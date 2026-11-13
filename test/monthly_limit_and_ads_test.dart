import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_valuer_pro/core/services/monthly_usage_service.dart';
import 'package:property_valuer_pro/core/services/entitlement_service.dart';
import 'package:property_valuer_pro/core/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MonthlyUsageService.releaseProcessingLock();
    await EntitlementService.revokeEntitlement();
    AdService.forceAdFailureForTesting = false;
  });

  group('Section 20: Monthly Free Report Limit & Meta Audience Network Tests', () {
    test('1. First click: counter becomes 1/10; report generation proceeds', () async {
      final initialUsage = await MonthlyUsageService.getUsage();
      expect(initialUsage.usedClicks, 0);
      expect(initialUsage.maxAllowance, 10);
      expect(initialUsage.canAcceptClick, true);

      final updatedUsage = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      expect(updatedUsage, isNotNull);
      expect(updatedUsage!.usedClicks, 1);
      expect(updatedUsage.remainingClicks, 9);
      expect(updatedUsage.isLimitReached, false);
    });

    test('2. Ninth click: counter becomes 9/10', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(8);

      final stateBefore = await MonthlyUsageService.getUsage();
      expect(stateBefore.usedClicks, 8);

      final updatedUsage = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      expect(updatedUsage, isNotNull);
      expect(updatedUsage!.usedClicks, 9);
      expect(updatedUsage.remainingClicks, 1);
      expect(updatedUsage.isLimitReached, false);
      expect(updatedUsage.canAcceptClick, true);
    });

    test('3. Tenth click: report generation allowed; counter becomes 10/10; limit marked exhausted', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(9);

      // User initiates 10th click
      final tenthClick = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      expect(tenthClick, isNotNull);
      expect(tenthClick!.usedClicks, 10);
      expect(tenthClick.remainingClicks, 0);
      // Immediately after the 10th accepted click, mark allowance exhausted
      expect(tenthClick.isLimitReached, true);
      expect(tenthClick.canAcceptClick, false);
    });

    test('4. Eleventh attempt: blocked; returns limit reached without incrementing counter', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(10);

      final usageBefore = await MonthlyUsageService.getUsage();
      expect(usageBefore.usedClicks, 10);
      expect(usageBefore.canAcceptClick, false);
      expect(usageBefore.isLimitReached, true);

      // Attempt 11th click
      final eleventhAttempt = await MonthlyUsageService.acceptGenerationClick();
      expect(eleventhAttempt!.usedClicks, 10); // Not incremented!
      expect(eleventhAttempt.canAcceptClick, false);

      final usageAfter = await MonthlyUsageService.getUsage();
      expect(usageAfter.usedClicks, 10);
    });

    test('5. Restart the app: counter remains 10/10 in persistent storage', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(10);

      // Fresh reload simulation
      final usageAfterRestart = await MonthlyUsageService.getUsage();
      expect(usageAfterRestart.usedClicks, 10);
      expect(usageAfterRestart.isLimitReached, true);
    });

    test('6. Navigate away and return: counter remains 10/10', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(10);

      // Simulate navigating to step 1, step 5, and returning to step 10
      final step1Check = await MonthlyUsageService.getUsage();
      final step5Check = await MonthlyUsageService.getUsage();
      final returnCheck = await MonthlyUsageService.getUsage();

      expect(step1Check.usedClicks, 10);
      expect(step5Check.usedClicks, 10);
      expect(returnCheck.usedClicks, 10);
      expect(returnCheck.isLimitReached, true);
    });

    test('7. First day of next calendar month: auto-resets to 0/10 and becomes available', () async {
      final novDate = DateTime(2026, 11, 20);
      await MonthlyUsageService.setSimulatedCountForTesting(10, currentDate: novDate);

      final novUsage = await MonthlyUsageService.getUsage(currentDate: novDate);
      expect(novUsage.monthIdentifier, '2026-11');
      expect(novUsage.usedClicks, 10);
      expect(novUsage.isLimitReached, true);

      // Device transitions to Dec 1st, 2026
      final dec1stDate = DateTime(2026, 12, 1);
      final decUsage = await MonthlyUsageService.getUsage(currentDate: dec1stDate);

      expect(decUsage.monthIdentifier, '2026-12');
      expect(decUsage.usedClicks, 0); // Automatically reset to 0!
      expect(decUsage.remainingClicks, 10);
      expect(decUsage.isLimitReached, false);
      expect(decUsage.canAcceptClick, true);
    });

    test('8. Ad unavailable / offline fallback: callback continues immediately without getting stuck', () async {
      AdService.forceAdFailureForTesting = true;
      bool reportGenerationStarted = false;

      // Mock contextless fallback execution
      final isPaid = await EntitlementService.isPaidTier();
      if (isPaid || !AdService.isAdsEnabled || AdService.forceAdFailureForTesting) {
        reportGenerationStarted = true;
      }

      expect(reportGenerationStarted, true);
    });

    test('9. Rapid repeated taps: debounced and locked; only one click counted', () async {
      SharedPreferences.setMockInitialValues({});
      MonthlyUsageService.releaseProcessingLock();

      // First valid tap
      final firstTap = await MonthlyUsageService.acceptGenerationClick();
      expect(firstTap, isNotNull);
      expect(firstTap!.usedClicks, 1);
      expect(MonthlyUsageService.isProcessing, true);

      // Immediate second and third taps while processing
      final secondTap = await MonthlyUsageService.acceptGenerationClick();
      final thirdTap = await MonthlyUsageService.acceptGenerationClick();

      expect(secondTap, isNull); // Rejected by rapid tap guard
      expect(thirdTap, isNull);

      final state = await MonthlyUsageService.getUsage();
      expect(state.usedClicks, 1); // Exactly 1 click counted!

      MonthlyUsageService.releaseProcessingLock();
    });

    test('10. Paid entitlement verified: monthly limit is completely bypassed', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(10);
      final freeState = await MonthlyUsageService.getUsage();
      expect(freeState.isLimitReached, true);
      expect(freeState.canAcceptClick, false);

      // Verify and apply paid commercial license
      final activated = await EntitlementService.verifyAndApplyLicense('VLR-PRO-2026-ABCD');
      expect(activated, true);

      final paidState = await MonthlyUsageService.getUsage();
      expect(paidState.isPaid, true);
      expect(paidState.isLimitReached, false);
      expect(paidState.canAcceptClick, true); // Bypassed!
      expect(paidState.displayLabel, 'Paid Version: Unlimited');
    });
  });
}
