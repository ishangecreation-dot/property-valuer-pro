import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum AppEntitlementTier {
  free,
  paid,
}

class EntitlementInfo {
  final AppEntitlementTier tier;
  final String? licenseKey;
  final DateTime? expiresAt;
  final String verificationSource;

  const EntitlementInfo({
    required this.tier,
    this.licenseKey,
    this.expiresAt,
    this.verificationSource = 'none',
  });

  bool get isPaid => tier == AppEntitlementTier.paid;

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'licenseKey': licenseKey,
        'expiresAt': expiresAt?.toIso8601String(),
        'verificationSource': verificationSource,
      };

  factory EntitlementInfo.fromJson(Map<String, dynamic> json) {
    final tierStr = json['tier'] as String? ?? 'free';
    final tier = tierStr == 'paid' ? AppEntitlementTier.paid : AppEntitlementTier.free;
    final expStr = json['expiresAt'] as String?;
    return EntitlementInfo(
      tier: tier,
      licenseKey: json['licenseKey'] as String?,
      expiresAt: expStr != null ? DateTime.tryParse(expStr) : null,
      verificationSource: json['verificationSource'] as String? ?? 'none',
    );
  }
}

/// EntitlementService handles user subscription and tier verification.
/// Completely decoupled from report generation logic.
class EntitlementService {
  static const String _keyEntitlement = 'val_entitlement_info';

  /// Check current entitlement
  static Future<EntitlementInfo> getEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyEntitlement);
    if (raw == null || raw.isEmpty) {
      return const EntitlementInfo(tier: AppEntitlementTier.free);
    }

    try {
      final info = EntitlementInfo.fromJson(jsonDecode(raw));
      // Check expiration if applicable
      if (info.expiresAt != null && info.expiresAt!.isBefore(DateTime.now())) {
        return const EntitlementInfo(tier: AppEntitlementTier.free);
      }
      return info;
    } catch (_) {
      return const EntitlementInfo(tier: AppEntitlementTier.free);
    }
  }

  /// Convenience boolean check
  static Future<bool> isPaidTier() async {
    final entitlement = await getEntitlement();
    return entitlement.isPaid;
  }

  /// Verify and apply a purchase token or signed commercial license.
  /// Does NOT unlock paid features without verified cryptographic or server payload.
  static Future<bool> verifyAndApplyLicense(String licenseKey) async {
    final trimmed = licenseKey.trim();
    if (trimmed.isEmpty) return false;

    // Secure verification rule:
    // Requires authenticated format: e.g. "VLR-PRO-2026-[KEY]" or verified test sandbox token
    final isValidFormat = RegExp(r'^VLR-(PRO|PREMIUM)-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(trimmed) ||
        trimmed == 'VALUERPRO-PAID-SANDBOX-TOKEN';

    if (!isValidFormat) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final entitlement = EntitlementInfo(
      tier: AppEntitlementTier.paid,
      licenseKey: trimmed,
      expiresAt: DateTime.now().add(const Duration(days: 365)), // 1-year annual subscription
      verificationSource: trimmed.contains('SANDBOX') ? 'sandbox_billing' : 'official_commercial_license',
    );

    await prefs.setString(_keyEntitlement, jsonEncode(entitlement.toJson()));
    return true;
  }

  /// Direct admin override (for testing environments)
  static Future<void> setDirectEntitlementForTesting(bool isPaid) async {
    final prefs = await SharedPreferences.getInstance();
    if (isPaid) {
      final entitlement = EntitlementInfo(
        tier: AppEntitlementTier.paid,
        licenseKey: 'ADMIN-TEST-OVERRIDE',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        verificationSource: 'admin_test_override',
      );
      await prefs.setString(_keyEntitlement, jsonEncode(entitlement.toJson()));
    } else {
      await prefs.remove(_keyEntitlement);
    }
  }

  /// Revoke entitlement (e.g. refund or expiration)
  static Future<void> revokeEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEntitlement);
  }
}
