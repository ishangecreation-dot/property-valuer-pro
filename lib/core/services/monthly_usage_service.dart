import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'entitlement_service.dart';

class MonthlyUsageState {
  final String monthIdentifier; // e.g. "2026-11"
  final int usedClicks; // Number of accepted Generate Report clicks this month
  final int maxAllowance; // 10 for free version
  final bool isPaid;

  const MonthlyUsageState({
    required this.monthIdentifier,
    required this.usedClicks,
    required this.maxAllowance,
    required this.isPaid,
  });

  /// True if the 10-click free quota is completely exhausted
  bool get isLimitReached => !isPaid && usedClicks >= maxAllowance;

  /// True if a new click can be accepted (Paid users or free users under 10)
  bool get canAcceptClick => isPaid || usedClicks < maxAllowance;

  /// Remaining free clicks for this month
  int get remainingClicks => isPaid ? 999999 : (maxAllowance - usedClicks).clamp(0, maxAllowance);

  /// Human-readable label: "Free Reports Used: 7 / 10" or "Paid Version (Unlimited)"
  String get displayLabel => isPaid ? 'Paid Version: Unlimited' : 'Free Reports Used: $usedClicks / $maxAllowance';
}

/// Single Source of Truth for Monthly Report Generation Click Counter.
/// Manages device local calendar date month transitions (YYYY-MM),
/// debouncing / duplicate click prevention, and persistent storage.
class MonthlyUsageService {
  static const int maxMonthlyClicks = AppConstants.monthlyFreeReportLimit; // Exactly 10
  static const String _keyUsageMonth = 'val_monthly_usage_month';
  static const String _keyUsageClicks = 'val_monthly_usage_clicks';

  // In-memory debouncing lock to prevent rapid repeated taps from counting multiple times
  static bool _isProcessing = false;
  static bool get isProcessing => _isProcessing;

  /// Formats date to "YYYY-MM" using device's local calendar date
  static String getMonthIdentifier([DateTime? date]) {
    final now = date ?? DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    return '${now.year}-$monthStr';
  }

  /// Check usage state. Checks the month identifier; if the month has changed,
  /// it automatically resets to 0 for the first day of the new calendar month.
  static Future<MonthlyUsageState> getUsage({DateTime? currentDate}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeMonth = getMonthIdentifier(currentDate);
    final savedMonth = prefs.getString(_keyUsageMonth);

    int clicks = prefs.getInt(_keyUsageClicks) ?? 0;

    // Calendar month rollover check:
    // If opening the app on a new calendar month (or 1st day of next month),
    // automatically reset counter to zero.
    if (savedMonth != activeMonth) {
      clicks = 0;
      await prefs.setString(_keyUsageMonth, activeMonth);
      await prefs.setInt(_keyUsageClicks, 0);
    }

    final isPaid = await EntitlementService.isPaidTier();

    return MonthlyUsageState(
      monthIdentifier: activeMonth,
      usedClicks: clicks,
      maxAllowance: maxMonthlyClicks,
      isPaid: isPaid,
    );
  }

  /// Attempts to register an accepted Generate Report button click.
  ///
  /// Rules:
  /// 1. Rejects if an action is currently processing (rapid tap guard).
  /// 2. If free allowance is already exhausted (>= 10), returns null / rejects action.
  /// 3. If allowed, accepts click, increments persistently, and returns the updated state.
  ///    The 10th click is accepted and allowed to complete, but immediately leaves
  ///    the counter at 10/10, disabling subsequent attempts.
  static Future<MonthlyUsageState?> acceptGenerationClick({DateTime? currentDate}) async {
    if (_isProcessing) {
      // Rapid repeated tap rejected: do not count duplicate taps
      return null;
    }

    final currentState = await getUsage(currentDate: currentDate);

    // If free limit is already exhausted, do not accept the click
    if (!currentState.canAcceptClick) {
      return currentState;
    }

    // Lock processing
    _isProcessing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final activeMonth = getMonthIdentifier(currentDate);

      int updatedClicks = currentState.usedClicks;
      if (!currentState.isPaid) {
        updatedClicks += 1;
        await prefs.setString(_keyUsageMonth, activeMonth);
        await prefs.setInt(_keyUsageClicks, updatedClicks);
      }

      return MonthlyUsageState(
        monthIdentifier: activeMonth,
        usedClicks: updatedClicks,
        maxAllowance: maxMonthlyClicks,
        isPaid: currentState.isPaid,
      );
    } catch (_) {
      _isProcessing = false;
      rethrow;
    }
  }

  /// Must be called when the report generation flow finishes (or fails) to unlock the guard.
  static void releaseProcessingLock() {
    _isProcessing = false;
  }

  /// Resets the counter for testing
  static Future<void> resetCounterForTesting({DateTime? currentDate}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeMonth = getMonthIdentifier(currentDate);
    await prefs.setString(_keyUsageMonth, activeMonth);
    await prefs.setInt(_keyUsageClicks, 0);
    _isProcessing = false;
  }

  /// Sets an exact simulated count for testing (e.g. setting to 9 or 10)
  static Future<void> setSimulatedCountForTesting(int count, {DateTime? currentDate}) async {
    final prefs = await SharedPreferences.getInstance();
    final activeMonth = getMonthIdentifier(currentDate);
    await prefs.setString(_keyUsageMonth, activeMonth);
    await prefs.setInt(_keyUsageClicks, count);
    _isProcessing = false;
  }
}
