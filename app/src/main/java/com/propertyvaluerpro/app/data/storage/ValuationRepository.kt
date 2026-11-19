package com.propertyvaluerpro.app.data.storage

import android.content.Context
import com.propertyvaluerpro.app.data.models.AppConstants
import com.propertyvaluerpro.app.data.models.MonthlyUsageState
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.data.models.ValuerProfile
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class ValuationRepository(context: Context) {
    private val prefs = context.getSharedPreferences("property_valuer_pro_prefs", Context.MODE_PRIVATE)
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    companion object {
        private const val KEY_PROFILE = "val_user_profile"
        private const val KEY_PROFILE_DRAFTS = "val_profile_drafts_list"
        private const val KEY_PROJECTS = "val_projects_list"
        private const val KEY_ACTIVE_PROJECT_ID = "val_active_project_id"
        private const val KEY_USAGE_MONTH = "val_monthly_usage_month"
        private const val KEY_USAGE_CLICKS = "val_monthly_usage_clicks"
        private const val KEY_IS_PAID = "val_tier_is_premium"
        private const val KEY_ADS_ENABLED = "val_ads_enabled"
        private const val KEY_AD_PROVIDER = "val_ad_provider"
        private const val KEY_META_INTERSTITIAL_ID = "val_meta_interstitial_placement_id"
        private const val KEY_SCREENS_FROZEN = "val_screens_3_to_10_frozen"
    }

    fun loadProfile(): ValuerProfile {
        val raw = prefs.getString(KEY_PROFILE, null) ?: return ValuerProfile()
        return runCatching { json.decodeFromString<ValuerProfile>(raw) }.getOrDefault(ValuerProfile())
    }

    fun saveProfile(profile: ValuerProfile) {
        prefs.edit().putString(KEY_PROFILE, json.encodeToString(profile)).apply()
    }

    fun loadProfileDrafts(): List<ValuerProfile> {
        val raw = prefs.getString(KEY_PROFILE_DRAFTS, null) ?: return emptyList()
        return runCatching { json.decodeFromString<List<ValuerProfile>>(raw) }.getOrDefault(emptyList())
    }

    fun saveProfileDraft(profile: ValuerProfile): List<ValuerProfile> {
        val normalized = profile.copy(
            id = if (profile.id.isBlank() || profile.id == "draft_default") {
                "draft_${System.currentTimeMillis()}"
            } else {
                profile.id
            },
            lastModifiedEpochMs = System.currentTimeMillis(),
        )
        saveProfile(normalized)
        val drafts = loadProfileDrafts().toMutableList()
        val idx = drafts.indexOfFirst { it.id == normalized.id }
        if (idx >= 0) drafts[idx] = normalized else drafts.add(0, normalized)
        prefs.edit().putString(KEY_PROFILE_DRAFTS, json.encodeToString(drafts)).apply()
        return drafts
    }

    fun loadProjects(): List<ValuationProject> {
        val raw = prefs.getString(KEY_PROJECTS, null) ?: return emptyList()
        return runCatching { json.decodeFromString<List<ValuationProject>>(raw) }.getOrDefault(emptyList())
    }

    fun saveProjects(projects: List<ValuationProject>) {
        prefs.edit().putString(KEY_PROJECTS, json.encodeToString(projects)).apply()
    }

    fun loadActiveProjectId(): String? = prefs.getString(KEY_ACTIVE_PROJECT_ID, null)

    fun saveActiveProject(project: ValuationProject): List<ValuationProject> {
        val updated = project.copy(updatedAtEpochMs = System.currentTimeMillis())
        val projects = loadProjects().toMutableList()
        val idx = projects.indexOfFirst { it.id == updated.id }
        if (idx >= 0) projects[idx] = updated else projects.add(0, updated)
        prefs.edit()
            .putString(KEY_ACTIVE_PROJECT_ID, updated.id)
            .putString(KEY_PROJECTS, json.encodeToString(projects))
            .apply()
        return projects
    }

    fun deleteProject(projectId: String): List<ValuationProject> {
        val projects = loadProjects().filterNot { it.id == projectId }
        saveProjects(projects)
        return projects
    }

    fun currentMonthId(): String =
        SimpleDateFormat("yyyy-MM", Locale.US).format(Date())

    fun getMonthlyUsage(): MonthlyUsageState {
        val activeMonth = currentMonthId()
        val savedMonth = prefs.getString(KEY_USAGE_MONTH, null)
        var clicks = prefs.getInt(KEY_USAGE_CLICKS, 0)
        if (savedMonth != activeMonth) {
            clicks = 0
            prefs.edit()
                .putString(KEY_USAGE_MONTH, activeMonth)
                .putInt(KEY_USAGE_CLICKS, 0)
                .apply()
        }
        return MonthlyUsageState(
            monthIdentifier = activeMonth,
            usedClicks = clicks,
            maxAllowance = AppConstants.MONTHLY_FREE_REPORT_LIMIT,
            isPaid = isPaidTier(),
        )
    }

    fun incrementMonthlyUsage(): MonthlyUsageState {
        val current = getMonthlyUsage()
        if (current.isPaid) return current
        val next = current.usedClicks + 1
        prefs.edit()
            .putString(KEY_USAGE_MONTH, current.monthIdentifier)
            .putInt(KEY_USAGE_CLICKS, next)
            .apply()
        return current.copy(usedClicks = next)
    }

    fun setSimulatedMonthlyCount(count: Int): MonthlyUsageState {
        val month = currentMonthId()
        prefs.edit()
            .putString(KEY_USAGE_MONTH, month)
            .putInt(KEY_USAGE_CLICKS, count.coerceAtLeast(0))
            .apply()
        return getMonthlyUsage()
    }

    fun isPaidTier(): Boolean = prefs.getBoolean(KEY_IS_PAID, false)

    fun setPaidTier(isPaid: Boolean) {
        prefs.edit().putBoolean(KEY_IS_PAID, isPaid).apply()
    }

    fun verifyAndApplyLicense(licenseKey: String): Boolean {
        val normalized = licenseKey.trim().uppercase(Locale.US)
        val isValid = normalized.startsWith("VLR-PRO-") && normalized.length >= 14
        if (isValid) setPaidTier(true)
        return isValid
    }

    fun isAdsEnabled(): Boolean = prefs.getBoolean(KEY_ADS_ENABLED, false)
    fun setAdsEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_ADS_ENABLED, enabled).apply()
    }

    fun getAdProvider(): String =
        prefs.getString(KEY_AD_PROVIDER, AppConstants.AD_PROVIDER_META) ?: AppConstants.AD_PROVIDER_META

    fun setAdProvider(provider: String) {
        prefs.edit().putString(KEY_AD_PROVIDER, provider).apply()
    }

    fun getMetaInterstitialId(): String =
        prefs.getString(KEY_META_INTERSTITIAL_ID, AppConstants.DEFAULT_META_INTERSTITIAL_ID)
            ?: AppConstants.DEFAULT_META_INTERSTITIAL_ID

    fun setMetaInterstitialId(id: String) {
        prefs.edit().putString(KEY_META_INTERSTITIAL_ID, id.trim()).apply()
    }

    fun areScreens3To10Frozen(): Boolean = prefs.getBoolean(KEY_SCREENS_FROZEN, true)
    fun setScreens3To10Frozen(frozen: Boolean) {
        prefs.edit().putBoolean(KEY_SCREENS_FROZEN, frozen).apply()
    }
}
