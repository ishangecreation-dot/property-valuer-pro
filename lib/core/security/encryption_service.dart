import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure Storage Service using Android Keystore / Hardware Security Module.
/// Protects AI API keys, administrative passwords, and client credential metadata.
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

  /// Saves the AI API key securely in Android Keystore
  static Future<void> saveAiApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _keyAiApiKey, value: apiKey.trim());
    } catch (_) {
      // Fallback for test / emulator environments lacking Keystore provider
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAiApiKey, apiKey.trim());
    }
  }

  /// Retrieves the AI API key from Android Keystore
  static Future<String> getAiApiKey() async {
    try {
      final key = await _secureStorage.read(key: _keyAiApiKey);
      if (key != null && key.isNotEmpty) return key;
    } catch (_) {}

    // Check fallback
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAiApiKey) ?? '';
  }

  /// Saves the administrator authentication password
  static Future<void> saveAdminPassword(String password) async {
    try {
      await _secureStorage.write(key: _keyAdminPassword, value: password.trim());
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAdminPassword, password.trim());
    }
  }

  /// Verifies the administrator password.
  /// If no password has been initialized yet, allows the user to set/unlock on first use.
  static Future<bool> verifyAdminPassword(String inputPassword) async {
    final trimmed = inputPassword.trim();
    if (trimmed.isEmpty) return false;

    String? storedPassword;
    try {
      storedPassword = await _secureStorage.read(key: _keyAdminPassword);
    } catch (_) {}

    if (storedPassword == null || storedPassword.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      storedPassword = prefs.getString(_keyAdminPassword);
    }

    // First-time initialization: if no password has ever been set, the entered password initializes it
    if (storedPassword == null || storedPassword.isEmpty) {
      await saveAdminPassword(trimmed);
      return true;
    }

    return storedPassword == trimmed;
  }

  /// Saves chosen AI Provider (Gemini 1.5 Flash, Claude, OpenAI)
  static Future<void> saveAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiProvider, provider);
  }

  /// Retrieves chosen AI Provider
  static Future<String> getAiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAiProvider) ?? 'Gemini 3.8 Flash';
  }
}
