import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/valuer_profile.dart';
import '../../models/valuation_project.dart';
import '../../models/monthly_report_usage.dart';
import '../constants/app_constants.dart';

class StorageService {
  static const String _keyProfile = 'val_user_profile';
  static const String _keyProjects = 'val_projects_list';
  static const String _keyActiveProjectId = 'val_active_project_id';

  // Monthly Report Quota Keys
  static const String _keyUsageMonth = 'val_monthly_usage_month';
  static const String _keyUsageCount = 'val_monthly_usage_count';
  static const String _keyUsageLimit = 'val_monthly_usage_limit';
  static const String _keyIsPremium = 'val_tier_is_premium';

  // Advertising Keys
  static const String _keyAdsEnabled = 'val_ads_enabled';
  static const String _keyAdProvider = 'val_ad_provider';
  static const String _keyMetaBannerPlacementId = 'val_meta_banner_placement_id';
  static const String _keyMetaInterstitialPlacementId = 'val_meta_interstitial_placement_id';
  static const String _keyInterstitialEnabled = 'val_interstitial_enabled';

  // Profile Persistence
  static Future<void> saveProfile(ValuerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  static Future<ValuerProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw == null || raw.isEmpty) return ValuerProfile();
    try {
      return ValuerProfile.fromJson(jsonDecode(raw));
    } catch (_) {
      return ValuerProfile();
    }
  }

  // Projects Persistence
  static Future<void> saveProjects(List<ValuationProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = projects.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProjects, jsonEncode(rawList));
  }

  static Future<List<ValuationProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProjects);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((item) => ValuationProject.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveActiveProject(ValuationProject project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProjectId, project.id);

    final projects = await loadProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      projects[index] = project;
    } else {
      projects.insert(0, project);
    }
    await saveProjects(projects);
  }

  static Future<ValuationProject?> loadActiveProject() async {
    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_keyActiveProjectId);
    if (activeId == null) return null;
    final projects = await loadProjects();
    final match = projects.where((p) => p.id == activeId);
    return match.isNotEmpty ? match.first : null;
  }

  static Future<void> deleteProject(String projectId) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
  }

  // ==========================================
  // Monthly Free Report Quota Tracking
  // ==========================================

  static String getCurrentYearMonth() {
    final now = DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    return '${now.year}-$monthStr';
  }

  static Future<MonthlyReportUsage> getMonthlyReportUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = getCurrentYearMonth();
    final savedMonth = prefs.getString(_keyUsageMonth);

    // If month changed or not initialized, reset count for the new calendar month
    int count = prefs.getInt(_keyUsageCount) ?? 0;
    if (savedMonth != currentMonth) {
      count = 0;
      await prefs.setString(_keyUsageMonth, currentMonth);
      await prefs.setInt(_keyUsageCount, 0);
    }

    final limit = prefs.getInt(_keyUsageLimit) ?? AppConstants.defaultMonthlyFreeReportLimit;
    final isPremium = prefs.getBool(_keyIsPremium) ?? false;

    return MonthlyReportUsage(
      currentMonth: currentMonth,
      generatedCount: count,
      limit: limit,
      isPremium: isPremium,
    );
  }

  static Future<MonthlyReportUsage> incrementMonthlyReportCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = getCurrentYearMonth();
    final savedMonth = prefs.getString(_keyUsageMonth);

    int count = prefs.getInt(_keyUsageCount) ?? 0;
    if (savedMonth != currentMonth) {
      count = 0;
      await prefs.setString(_keyUsageMonth, currentMonth);
    }

    count += 1;
    await prefs.setInt(_keyUsageCount, count);

    final limit = prefs.getInt(_keyUsageLimit) ?? AppConstants.defaultMonthlyFreeReportLimit;
    final isPremium = prefs.getBool(_keyIsPremium) ?? false;

    return MonthlyReportUsage(
      currentMonth: currentMonth,
      generatedCount: count,
      limit: limit,
      isPremium: isPremium,
    );
  }

  static Future<void> resetMonthlyReportCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentMonth = getCurrentYearMonth();
    await prefs.setString(_keyUsageMonth, currentMonth);
    await prefs.setInt(_keyUsageCount, 0);
  }

  static Future<void> setMonthlyReportLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUsageLimit, limit);
  }

  static Future<bool> isPremiumTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  static Future<void> setPremiumTier(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, isPremium);
  }

  // ==========================================
  // Advertising & Meta Audience Network Settings
  // ==========================================

  static Future<bool> isAdsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdsEnabled) ?? false;
  }

  static Future<void> setAdsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdsEnabled, enabled);
  }

  static Future<String> getActiveAdProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdProvider) ?? AppConstants.adProviderMeta;
  }

  static Future<void> setActiveAdProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAdProvider, provider);
  }

  static Future<String> getMetaInterstitialPlacementId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMetaInterstitialPlacementId) ?? AppConstants.defaultMetaInterstitialPlacementId;
  }

  static Future<void> setMetaInterstitialPlacementId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMetaInterstitialPlacementId, id);
  }

  static Future<String> getMetaBannerPlacementId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMetaBannerPlacementId) ?? AppConstants.defaultMetaBannerPlacementId;
  }

  static Future<void> setMetaBannerPlacementId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMetaBannerPlacementId, id);
  }

  static Future<bool> isInterstitialEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyInterstitialEnabled) ?? true;
  }

  static Future<void> setInterstitialEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInterstitialEnabled, enabled);
  }
}
