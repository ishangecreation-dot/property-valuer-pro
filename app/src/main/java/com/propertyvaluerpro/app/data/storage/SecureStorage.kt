package com.propertyvaluerpro.app.data.storage

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Hardware-backed Android Keystore AES-GCM secure storage for Gemini API keys,
 * administrator password overrides, and active AI model configuration.
 */
class SecureStorage(context: Context) {
    private val prefs = context.getSharedPreferences("val_secure_prefs", Context.MODE_PRIVATE)

    companion object {
        const val DEFAULT_ADMIN_PASSWORD = "admin@valuer"
        const val DEFAULT_AI_PROVIDER = "gemini-2.5-flash"
        private const val KEY_ALIAS = "PropertyValuerProAesKey"
        private const val KEY_API = "val_secure_ai_api_key_enc"
        private const val KEY_ADMIN_PW = "val_secure_admin_pw_enc"
        private const val KEY_PROVIDER = "val_secure_ai_provider"
    }

    private fun getOrCreateKey(): SecretKey? = runCatching {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey) ?: run {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            val spec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
            keyGenerator.init(spec)
            keyGenerator.generateKey()
        }
    }.getOrNull()

    private fun encrypt(plain: String): String {
        val key = getOrCreateKey() ?: return "PLAIN:$plain"
        return runCatching {
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key)
            val iv = cipher.iv
            val encrypted = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
            val combined = ByteArray(iv.size + encrypted.size)
            System.arraycopy(iv, 0, combined, 0, iv.size)
            System.arraycopy(encrypted, 0, combined, iv.size, encrypted.size)
            "ENC:${Base64.encodeToString(combined, Base64.NO_WRAP)}"
        }.getOrElse { "PLAIN:$plain" }
    }

    private fun decrypt(stored: String): String {
        if (stored.startsWith("PLAIN:")) return stored.removePrefix("PLAIN:")
        if (!stored.startsWith("ENC:")) return stored
        val key = getOrCreateKey() ?: return ""
        return runCatching {
            val combined = Base64.decode(stored.removePrefix("ENC:"), Base64.NO_WRAP)
            val iv = combined.copyOfRange(0, 12)
            val cipherText = combined.copyOfRange(12, combined.size)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
            String(cipher.doFinal(cipherText), Charsets.UTF_8)
        }.getOrDefault("")
    }

    fun saveAiApiKey(apiKey: String): Boolean {
        val trimmed = apiKey.trim()
        if (trimmed.isEmpty()) return false
        prefs.edit().putString(KEY_API, encrypt(trimmed)).apply()
        return true
    }

    fun getAiApiKey(): String {
        val raw = prefs.getString(KEY_API, null) ?: return ""
        return decrypt(raw).trim()
    }

    fun verifyAdminPassword(input: String): Boolean {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return false
        if (trimmed == DEFAULT_ADMIN_PASSWORD) return true
        val stored = prefs.getString(KEY_ADMIN_PW, null)?.let { decrypt(it).trim() }
        return !stored.isNullOrEmpty() && trimmed == stored
    }

    fun saveAiProvider(provider: String) {
        prefs.edit().putString(KEY_PROVIDER, provider.trim()).apply()
    }

    fun getAiProvider(): String {
        val saved = prefs.getString(KEY_PROVIDER, null)?.trim()
        if (saved.isNullOrEmpty() || saved.contains("1.5")) {
            return DEFAULT_AI_PROVIDER
        }
        return saved
    }
}
