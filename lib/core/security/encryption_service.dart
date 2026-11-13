import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static const String _keyAiApiKey = 'sec_ai_api_key';
  static const String _keyAdminPassword = 'sec_admin_password';
  static const String _keyAiProvider = 'sec_ai_provider';

  // Obfuscation / Encrypted envelope for Android local storage
  static String _xorTransform(String input) {
    const key = 0x5A;
    final bytes = utf8.encode(input);
    final transformed = bytes.map((b) => b ^ key).toList();
    return base64Encode(transformed);
  }

  static String _xorUntransform(String encoded) {
    try {
      const key = 0x5A;
      final bytes = base64Decode(encoded);
      final untransformed = bytes.map((b) => b ^ key).toList();
      return utf8.decode(untransformed);
    } catch (_) {
      return '';
    }
  }

  static Future<void> saveAiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiApiKey, _xorTransform(apiKey.trim()));
  }

  static Future<String> getAiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAiApiKey);
    if (raw == null || raw.isEmpty) return '';
    return _xorUntransform(raw);
  }

  static Future<void> saveAdminPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdminPassword, _xorTransform(password.trim()));
  }

  static Future<bool> verifyAdminPassword(String inputPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAdminPassword);
    if (raw == null || raw.isEmpty) {
      // Default initial admin password: admin123
      return inputPassword.trim() == 'admin123';
    }
    return _xorUntransform(raw) == inputPassword.trim();
  }

  static Future<void> saveAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiProvider, provider);
  }

  static Future<String> getAiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAiProvider) ?? 'Gemini 3.8 Flash';
  }
}
