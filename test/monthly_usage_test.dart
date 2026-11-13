import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_valuer_pro/core/services/monthly_usage_service.dart';
import 'package:property_valuer_pro/core/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MonthlyUsageService.resetCounterForTesting();
    await EntitlementService.revokeEntitlement();
  });

  group('Phase Six: Monthly Free Report Limit & Entitlement Tests', () {
    test('1. First accepted request: counter becomes 1/10', () async {
      final initial = await MonthlyUsageService.getUsage();
      expect(initial.usedClicks, 0);
      expect(initial.isLimitReached, false);
      expect(initial.canAcceptClick, true);

      final updated = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      expect(updated, isNotNull);
      expect(updated!.usedClicks, 1);
      expect(updated.remainingClicks, 9);
      expect(updated.isLimitReached, false);
    });

    test('2. Ninth accepted request: counter becomes 9/10', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(8);

      final updated = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      expect(updated, isNotNull);
      expect(updated!.usedClicks, 9);
      expect(updated.remainingClicks, 1);
      expect(updated.isLimitReached, false);
    });

    test('3. Tenth accepted request: succeeds, reaches 10/10', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(9);

      final updated = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      expect(updated, isNotNull);
      expect(updated!.usedClicks, 10);
      expect(updated.remainingClicks, 0);
      expect(updated.isLimitReached, true);
    });

    test('4. Eleventh request: blocked after 10/10 allowance', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(10);

      final state = await MonthlyUsageService.getUsage();
      expect(state.canAcceptClick, false);
      expect(state.isLimitReached, true);

      final attempt = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      // Attempt rejected, returns current state with limit reached
      expect(attempt!.isLimitReached, true);
      expect(attempt.usedClicks, 10);
    });

    test('5. Usage counter persists across simulated app restarts', () async {
      await MonthlyUsageService.setSimulatedCountForTesting(5);

      // Re-fetch as if launching the app afresh
      final state = await MonthlyUsageService.getUsage();
      expect(state.usedClicks, 5);
      expect(state.remainingClicks, 5);
    });

    test('6. New calendar month automatically resets counter to 0/10', () async {
      final novDate = DateTime(2026, 11, 15);
      await MonthlyUsageService.setSimulatedCountForTesting(10, currentDate: novDate);

      final novState = await MonthlyUsageService.getUsage(currentDate: novDate);
      expect(novState.usedClicks, 10);
      expect(novState.isLimitReached, true);

      // Transition to December 1st (new calendar month)
      final decDate = DateTime(2026, 12, 1);
      final decState = await MonthlyUsageService.getUsage(currentDate: decDate);

      expect(decState.monthIdentifier, '2026-12');
      expect(decState.usedClicks, 0);
      expect(decState.remainingClicks, 10);
      expect(decState.isLimitReached, false);
    });

    test('7. Rapid duplicate taps guard prevents duplicate counts', () async {
      // First tap accepted
      final click1 = await MonthlyUsageService.acceptGenerationClick();
      expect(click1, isNotNull);
      expect(click1!.usedClicks, 1);

      // Second tap while still processing (without releasing lock)
      final click2 = await MonthlyUsageService.acceptGenerationClick();
      // Guard rejects duplicate click
      expect(click2, isNull);

      // Release lock once finished
      MonthlyUsageService.releaseProcessingLock();
    });

    test('8. Verified Paid Entitlement bypasses monthly limit', () async {
      // Simulate reaching limit
      await MonthlyUsageService.setSimulatedCountForTesting(10);

      // Apply verified license token
      final applied = await EntitlementService.verifyAndApplyLicense('VLR-PRO-2026-ABCD');
      expect(applied, true);

      final state = await MonthlyUsageService.getUsage();
      expect(state.isPaid, true);
      expect(state.isLimitReached, false);
      expect(state.canAcceptClick, true);

      final accepted = await MonthlyUsageService.acceptGenerationClick();
      MonthlyUsageService.releaseProcessingLock();

      expect(accepted, isNotNull);
      expect(accepted!.isPaid, true);
      expect(accepted.isLimitReached, false);
    });
  });
}
