import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Storage Service using Android Keystore / Hardware Security Module.
/// Protects AI API keys, administrative passwords, and client credential metadata.
///
/// Security Note: A password embedded in a client-side APK can be extracted by
/// a technically capable person. This password serves as a basic local application
/// gate, not as strong server-side administrator authentication.
class EncryptionService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const String _keyAiApiKey = 'val_secure_ai_api_key';
  static const String _keyAdminPassword = 'val_secure_admin_password';
  static const String _keyAiProvider = 'val_secure_ai_provider';

  /// Required default administrator password per specification
  static const String defaultAdminPassword = 'admin@valuer';

  /// Saves the AI API key securely in Android Keystore / Secure Storage.
  /// Validates that the key is not empty and never silently replaces a valid key with empty.
  static Future<bool> saveAiApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    try {
      await _secureStorage.write(key: _keyAiApiKey, value: trimmed);
    } catch (_) {
      // Fallback for test / emulator environments lacking Keystore provider
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyAiApiKey, trimmed);
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// Retrieves the AI API key from Android Keystore / Secure Storage.
  static Future<String> getAiApiKey() async {
    try {
      final key = await _secureStorage.read(key: _keyAiApiKey);
      if (key != null && key.trim().isNotEmpty) {
        return key.trim();
      }
    } catch (_) {}

    // Fallback to SharedPreferences if secure storage throws or is empty
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAiApiKey)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Saves the administrator authentication password securely in Keystore.
  /// Intentionally avoids saving passwords in plain-text SharedPreferences.
  static Future<void> saveAdminPassword(String password) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) return;

    try {
      await _secureStorage.write(key: _keyAdminPassword, value: trimmed);
    } catch (_) {
      // Do not store the password in plain-text SharedPreferences
    }
  }

  /// Verifies the administrator password against the required default password.
  /// Does NOT accept arbitrary first-entered passwords as new passwords.
  static Future<bool> verifyAdminPassword(String inputPassword) async {
    final trimmed = inputPassword.trim();
    if (trimmed.isEmpty) return false;

    // Check against the authoritative default administrator password
    if (trimmed == defaultAdminPassword) {
      return true;
    }

    // Check if an updated administrator password was explicitly saved in Keystore
    try {
      final stored = await _secureStorage.read(key: _keyAdminPassword);
      if (stored != null && stored.trim().isNotEmpty && trimmed == stored.trim()) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Saves chosen AI Provider (Gemini 1.5 Flash, Claude, OpenAI)
  static Future<void> saveAiProvider(String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAiProvider, provider.trim());
    } catch (_) {}
  }

  /// Retrieves chosen AI Provider
  static Future<String> getAiProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAiProvider) ?? 'Gemini 3.1 Flash-Lite';
    } catch (_) {
      return 'Gemini 3.1 Flash-Lite';
    }
  }
}
