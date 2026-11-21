package com.propertyvaluerpro.app.data.services

import android.content.Context
import android.util.Log
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.propertyvaluerpro.app.data.models.FirebaseUserProfile
import com.propertyvaluerpro.app.data.models.SystemAdminConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.withContext

/**
 * Service managing Firebase Authentication (Google Sign-In) and Cloud Firestore
 * for user accounts, role-based access control, and API token usage metrics for billing.
 */
class FirebaseService(private val context: Context) {

    companion object {
        private const val TAG = "FirebaseService"
        const val USERS_COLLECTION = "users"
        const val CONFIG_COLLECTION = "system_config"
        const val ADMIN_CONFIG_DOC = "admin_settings"
        const val SUPER_ADMIN_EMAIL = FirebaseUserProfile.SUPER_ADMIN_EMAIL
    }

    private val auth: FirebaseAuth? by lazy {
        runCatching {
            ensureFirebaseApp()
            FirebaseAuth.getInstance()
        }.getOrNull()
    }

    private val firestore: FirebaseFirestore? by lazy {
        runCatching {
            ensureFirebaseApp()
            FirebaseFirestore.getInstance()
        }.getOrNull()
    }

    private fun ensureFirebaseApp() {
        if (FirebaseApp.getApps(context).isEmpty()) {
            FirebaseApp.initializeApp(context)
        }
    }

    val currentUser: FirebaseUser?
        get() = runCatching { auth?.currentUser }.getOrNull()

    /**
     * Flow emitting the current Firebase Auth user state.
     */
    val authStateFlow: Flow<FirebaseUser?> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { fbAuth ->
            trySend(fbAuth.currentUser)
        }
        val safeAuth = auth
        safeAuth?.addAuthStateListener(listener) ?: trySend(null)
        awaitClose {
            safeAuth?.removeAuthStateListener(listener)
        }
    }

    /**
     * Configure Google Sign-In Client.
     * @param serverClientId Optional Web Client ID from Firebase console for ID Token verification.
     */
    fun getGoogleSignInClient(serverClientId: String? = null): GoogleSignInClient {
        val gsoBuilder = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestProfile()

        val trimmedClientId = serverClientId?.trim() ?: ""
        if (trimmedClientId.isNotEmpty()) {
            gsoBuilder.requestIdToken(trimmedClientId)
        }

        return GoogleSignIn.getClient(context, gsoBuilder.build())
    }

    /**
     * Complete Firebase sign-in with Google Account.
     */
    suspend fun signInWithGoogle(account: GoogleSignInAccount): Result<FirebaseUserProfile> = withContext(Dispatchers.IO) {
        runCatching {
            val safeAuth = auth ?: throw IllegalStateException("Firebase Auth is not available on this device.")
            val idToken = account.idToken
            val firebaseUser = if (!idToken.isNullOrBlank()) {
                val credential = GoogleAuthProvider.getCredential(idToken, null)
                val authResult = Tasks.await(safeAuth.signInWithCredential(credential))
                authResult.user ?: throw IllegalStateException("Failed to obtain user from Firebase credential.")
            } else {
                // When idToken is not configured (e.g. initial setup without web client id),
                // use existing Firebase current user or simulate profile synchronization
                safeAuth.currentUser ?: throw IllegalStateException("Please configure the Firebase Web Client ID to enable Google ID tokens.")
            }

            // Sync with Firestore users collection
            syncUserOnLogin(
                uid = firebaseUser.uid,
                email = firebaseUser.email ?: account.email.orEmpty(),
                displayName = firebaseUser.displayName ?: account.displayName.orEmpty(),
                photoUrl = (firebaseUser.photoUrl ?: account.photoUrl)?.toString().orEmpty(),
            )
        }
    }

    /**
     * Synchronize user profile in Firestore when signing in.
     * If user document doesn't exist, create it with all required fields.
     */
    suspend fun syncUserOnLogin(
        uid: String,
        email: String,
        displayName: String,
        photoUrl: String = "",
    ): FirebaseUserProfile = withContext(Dispatchers.IO) {
        val db = firestore ?: return@withContext FirebaseUserProfile(
            uid = uid,
            email = email,
            name = displayName,
            role = if (email.trim().equals(SUPER_ADMIN_EMAIL, ignoreCase = true)) FirebaseUserProfile.ROLE_ADMIN else FirebaseUserProfile.ROLE_USER,
            photoUrl = photoUrl,
        )

        val docRef = db.collection(USERS_COLLECTION).document(uid)
        val snapshot = runCatching { Tasks.await(docRef.get()) }.getOrNull()

        // Fetch allowed admin emails to evaluate role
        val allowedAdmins = fetchAllowedAdminEmailsInternal()
        val isSuperAdmin = email.trim().equals(SUPER_ADMIN_EMAIL, ignoreCase = true)
        val isAllowedAdmin = allowedAdmins.any { it.trim().equals(email.trim(), ignoreCase = true) }
        val assignedRole = if (isSuperAdmin || isAllowedAdmin) FirebaseUserProfile.ROLE_ADMIN else FirebaseUserProfile.ROLE_USER

        if (snapshot != null && snapshot.exists()) {
            val existingRole = snapshot.getString("role") ?: assignedRole
            val effectiveRole = if (isSuperAdmin || isAllowedAdmin) FirebaseUserProfile.ROLE_ADMIN else existingRole

            val updates = mutableMapOf<String, Any>(
                "lastLoginAt" to System.currentTimeMillis(),
                "name" to displayName.ifBlank { snapshot.getString("name").orEmpty() },
                "role" to effectiveRole,
            )
            if (photoUrl.isNotBlank()) updates["photoUrl"] = photoUrl

            runCatching { Tasks.await(docRef.update(updates)) }

            mapSnapshotToProfile(snapshot).copy(
                name = displayName.ifBlank { snapshot.getString("name").orEmpty() },
                role = effectiveRole,
                lastLoginAt = System.currentTimeMillis(),
                photoUrl = photoUrl.ifBlank { snapshot.getString("photoUrl").orEmpty() },
            )
        } else {
            // First time login - Create document in users collection using their uid
            val newProfile = FirebaseUserProfile(
                uid = uid,
                email = email,
                name = displayName.ifBlank { email.substringBefore("@") },
                role = assignedRole,
                generatedReport = FirebaseUserProfile.DEFAULT_QUOTA, // "0/10"
                apiKey = "",
                apiModel = "gemini-3.1-flash-lite",
                apiTokenUsageIn = 0L,
                apiTokenUsageOut = 0L,
                avgApiTokenUsage = 0.0,
                totalRequests = 0L,
                createdAt = System.currentTimeMillis(),
                lastLoginAt = System.currentTimeMillis(),
                photoUrl = photoUrl,
            )

            val dataMap = mapProfileToMap(newProfile)
            runCatching { Tasks.await(docRef.set(dataMap)) }
            newProfile
        }
    }

    /**
     * Fetch user profile from Firestore by UID.
     */
    suspend fun getUserProfile(uid: String): FirebaseUserProfile? = withContext(Dispatchers.IO) {
        val db = firestore ?: return@withContext null
        runCatching {
            val snap = Tasks.await(db.collection(USERS_COLLECTION).document(uid).get())
            if (snap.exists()) mapSnapshotToProfile(snap) else null
        }.getOrNull()
    }

    /**
     * Admin capability: Fetch all registered users from Cloud Firestore.
     */
    suspend fun fetchAllUsers(): Result<List<FirebaseUserProfile>> = withContext(Dispatchers.IO) {
        runCatching {
            val db = firestore ?: throw IllegalStateException("Cloud Firestore is not initialized.")
            val snapshot = Tasks.await(db.collection(USERS_COLLECTION).get())
            snapshot.documents.map { mapSnapshotToProfile(it) }.sortedByDescending { it.createdAt }
        }
    }

    /**
     * Admin capability: Add a new user document manually.
     */
    suspend fun addUserDocument(profile: FirebaseUserProfile): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val db = firestore ?: throw IllegalStateException("Cloud Firestore is not initialized.")
            val targetUid = profile.uid.ifBlank { "manual_${System.currentTimeMillis()}" }
            val finalProfile = profile.copy(uid = targetUid)
            Tasks.await(db.collection(USERS_COLLECTION).document(targetUid).set(mapProfileToMap(finalProfile)))
            Unit
        }
    }

    /**
     * Admin capability: Update/edit ANY field of a user document.
     */
    suspend fun updateUserDocument(profile: FirebaseUserProfile): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val db = firestore ?: throw IllegalStateException("Cloud Firestore is not initialized.")
            require(profile.uid.isNotBlank()) { "User UID cannot be empty for update." }
            Tasks.await(
                db.collection(USERS_COLLECTION).document(profile.uid)
                    .set(mapProfileToMap(profile), SetOptions.merge())
            )
            Unit
        }
    }

    /**
     * Admin capability: Delete a user document.
     */
    suspend fun deleteUserDocument(uid: String): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val db = firestore ?: throw IllegalStateException("Cloud Firestore is not initialized.")
            require(uid.isNotBlank()) { "User UID cannot be empty for delete." }
            Tasks.await(db.collection(USERS_COLLECTION).document(uid).delete())
            Unit
        }
    }

    /**
     * Fetch allowed admin emails list configured by the super admin.
     */
    suspend fun fetchAllowedAdminEmails(): List<String> = withContext(Dispatchers.IO) {
        fetchAllowedAdminEmailsInternal()
    }

    private fun fetchAllowedAdminEmailsInternal(): List<String> {
        val db = firestore ?: return listOf(SUPER_ADMIN_EMAIL)
        return runCatching {
            val doc = Tasks.await(db.collection(CONFIG_COLLECTION).document(ADMIN_CONFIG_DOC).get())
            val list = doc.get("allowedAdminEmails") as? List<*>
            val emails = list?.mapNotNull { it?.toString() } ?: emptyList()
            if (emails.contains(SUPER_ADMIN_EMAIL)) emails else listOf(SUPER_ADMIN_EMAIL) + emails
        }.getOrDefault(listOf(SUPER_ADMIN_EMAIL))
    }

    /**
     * Super Admin capability: Add an email to allowed admins list.
     */
    suspend fun addAllowedAdminEmail(email: String): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val cleanEmail = email.trim().lowercase()
            require(cleanEmail.contains("@")) { "Please enter a valid email address." }
            val db = firestore ?: throw IllegalStateException("Cloud Firestore is not initialized.")
            val current = fetchAllowedAdminEmailsInternal().toMutableSet()
            current.add(SUPER_ADMIN_EMAIL)
            current.add(cleanEmail)

            Tasks.await(
                db.collection(CONFIG_COLLECTION).document(ADMIN_CONFIG_DOC).set(
                    mapOf(
                        "superAdminEmail" to SUPER_ADMIN_EMAIL,
                        "allowedAdminEmails" to current.toList(),
                    ),
                    SetOptions.merge()
                )
            )

            // If user already has a document, upgrade role to admin
            val usersSnap = Tasks.await(db.collection(USERS_COLLECTION).whereEqualTo("email", cleanEmail).get())
            for (doc in usersSnap.documents) {
                Tasks.await(doc.reference.update("role", FirebaseUserProfile.ROLE_ADMIN))
            }
            Unit
        }
    }

    /**
     * Super Admin capability: Remove an email from allowed admins list.
     */
    suspend fun removeAllowedAdminEmail(email: String): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val cleanEmail = email.trim().lowercase()
            if (cleanEmail.equals(SUPER_ADMIN_EMAIL, ignoreCase = true)) {
                throw IllegalArgumentException("The primary super admin ($SUPER_ADMIN_EMAIL) cannot be removed.")
            }
            val db = firestore ?: throw IllegalStateException("Cloud Firestore is not initialized.")
            val current = fetchAllowedAdminEmailsInternal().toMutableSet()
            current.remove(cleanEmail)
            current.add(SUPER_ADMIN_EMAIL)

            Tasks.await(
                db.collection(CONFIG_COLLECTION).document(ADMIN_CONFIG_DOC).set(
                    mapOf(
                        "superAdminEmail" to SUPER_ADMIN_EMAIL,
                        "allowedAdminEmails" to current.toList(),
                    ),
                    SetOptions.merge()
                )
            )

            // Downgrade user's role in users collection to user
            val usersSnap = Tasks.await(db.collection(USERS_COLLECTION).whereEqualTo("email", cleanEmail).get())
            for (doc in usersSnap.documents) {
                Tasks.await(doc.reference.update("role", FirebaseUserProfile.ROLE_USER))
            }
            Unit
        }
    }

    /**
     * Real-time billing insight: Record API token usage in & out for a user
     * and recalculate the running average token usage.
     */
    suspend fun recordTokenUsage(uid: String, inputTokens: Long, outputTokens: Long): Result<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            if (uid.isBlank()) return@runCatching
            val db = firestore ?: return@runCatching
            val docRef = db.collection(USERS_COLLECTION).document(uid)
            val snap = Tasks.await(docRef.get())
            if (!snap.exists()) return@runCatching

            val curIn = snap.getLong("apiTokenUsageIn") ?: 0L
            val curOut = snap.getLong("apiTokenUsageOut") ?: 0L
            val curReq = snap.getLong("totalRequests") ?: 0L

            val nextIn = curIn + inputTokens
            val nextOut = curOut + outputTokens
            val nextReq = curReq + 1L
            val nextAvg = (nextIn + nextOut).toDouble() / nextReq.coerceAtLeast(1L)

            Tasks.await(
                docRef.update(
                    mapOf(
                        "apiTokenUsageIn" to nextIn,
                        "apiTokenUsageOut" to nextOut,
                        "totalRequests" to nextReq,
                        "avgApiTokenUsage" to nextAvg,
                        "lastLoginAt" to System.currentTimeMillis(),
                    )
                )
            )
            Unit
        }
    }

    /**
     * Increment generated report count (e.g. "0/10" -> "1/10").
     */
    suspend fun incrementGeneratedReport(uid: String): Result<String> = withContext(Dispatchers.IO) {
        runCatching {
            if (uid.isBlank()) return@runCatching "0/10"
            val db = firestore ?: return@runCatching "0/10"
            val docRef = db.collection(USERS_COLLECTION).document(uid)
            val snap = Tasks.await(docRef.get())
            if (!snap.exists()) return@runCatching "0/10"

            val currentQuota = snap.getString("generatedReport") ?: "0/10"
            val currentCount = currentQuota.substringBefore("/").trim().toIntOrNull() ?: 0
            val maxLimit = currentQuota.substringAfter("/", "10").trim().toIntOrNull() ?: 10
            val nextQuota = "${currentCount + 1}/$maxLimit"

            Tasks.await(docRef.update("generatedReport", nextQuota))
            nextQuota
        }
    }

    fun signOut() {
        runCatching { auth?.signOut() }
        runCatching { getGoogleSignInClient().signOut() }
    }

    /**
     * Direct sign-in helper (useful for testing on emulators or instant admin login).
     */
    suspend fun manualSignIn(email: String, displayName: String): Result<FirebaseUserProfile> = withContext(Dispatchers.IO) {
        runCatching {
            val cleanEmail = email.trim().lowercase()
            require(cleanEmail.contains("@")) { "Please enter a valid email." }
            val uid = "usr_" + cleanEmail.replace(Regex("[^a-zA-Z0-9]"), "_")
            syncUserOnLogin(
                uid = uid,
                email = cleanEmail,
                displayName = displayName.ifBlank { cleanEmail.substringBefore("@") },
            )
        }
    }

    private fun mapSnapshotToProfile(doc: com.google.firebase.firestore.DocumentSnapshot): FirebaseUserProfile {
        return FirebaseUserProfile(
            uid = doc.id,
            email = doc.getString("email").orEmpty(),
            name = doc.getString("name").orEmpty(),
            role = doc.getString("role") ?: FirebaseUserProfile.ROLE_USER,
            generatedReport = doc.getString("generatedReport") ?: FirebaseUserProfile.DEFAULT_QUOTA,
            apiKey = doc.getString("apiKey").orEmpty(),
            apiModel = doc.getString("apiModel") ?: "gemini-3.1-flash-lite",
            apiTokenUsageIn = doc.getLong("apiTokenUsageIn") ?: 0L,
            apiTokenUsageOut = doc.getLong("apiTokenUsageOut") ?: 0L,
            avgApiTokenUsage = doc.getDouble("avgApiTokenUsage") ?: 0.0,
            totalRequests = doc.getLong("totalRequests") ?: 0L,
            createdAt = doc.getLong("createdAt") ?: System.currentTimeMillis(),
            lastLoginAt = doc.getLong("lastLoginAt") ?: System.currentTimeMillis(),
            photoUrl = doc.getString("photoUrl").orEmpty(),
        )
    }

    private fun mapProfileToMap(p: FirebaseUserProfile): Map<String, Any> {
        return mapOf(
            "uid" to p.uid,
            "email" to p.email,
            "name" to p.name,
            "role" to p.role,
            "generatedReport" to p.generatedReport,
            "apiKey" to p.apiKey,
            "apiModel" to p.apiModel,
            "apiTokenUsageIn" to p.apiTokenUsageIn,
            "apiTokenUsageOut" to p.apiTokenUsageOut,
            "avgApiTokenUsage" to p.avgApiTokenUsage,
            "totalRequests" to p.totalRequests,
            "createdAt" to p.createdAt,
            "lastLoginAt" to p.lastLoginAt,
            "photoUrl" to p.photoUrl,
        )
    }
}
