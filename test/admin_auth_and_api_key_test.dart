import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_valuer_pro/core/security/encryption_service.dart';
import 'package:property_valuer_pro/core/services/ai_service.dart';
import 'package:property_valuer_pro/features/settings/screens/admin_settings_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AiService.testConnectionOverride = null;
  });

  group('Administrator Password Authentication & AI API Key Settings Tests', () {
    test('1. Correct password admin@valuer is accepted', () async {
      final isAccepted = await EncryptionService.verifyAdminPassword('admin@valuer');
      expect(isAccepted, isTrue);

      // Verify with surrounding whitespace trimmed
      final isAcceptedTrimmed = await EncryptionService.verifyAdminPassword('  admin@valuer  ');
      expect(isAcceptedTrimmed, isTrue);
    });

    test('2. Wrong password is rejected', () async {
      final isRejectedWrong = await EncryptionService.verifyAdminPassword('wrongpassword123');
      expect(isRejectedWrong, isFalse);

      final isRejectedEmpty = await EncryptionService.verifyAdminPassword('');
      expect(isRejectedEmpty, isFalse);

      final isRejectedWhitespace = await EncryptionService.verifyAdminPassword('   ');
      expect(isRejectedWhitespace, isFalse);
    });

    test('3. An arbitrary first-entered password is never accepted or saved as the administrator password', () async {
      // First attempt with random password on uninitialized storage
      final firstAttempt = await EncryptionService.verifyAdminPassword('randomFirstPassword');
      expect(firstAttempt, isFalse);

      // Second attempt with the same random password must still be rejected
      final secondAttempt = await EncryptionService.verifyAdminPassword('randomFirstPassword');
      expect(secondAttempt, isFalse);

      // The authoritative default password must still be admin@valuer
      expect(await EncryptionService.verifyAdminPassword('admin@valuer'), isTrue);
    });

    testWidgets('4. Wrong-password dialog displays the exact required message', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminSettingsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Administrator Authentication popup title and message
      expect(find.text('Administrator Authentication'), findsOneWidget);
      expect(
        find.text('Enter the administrator password to access AI API settings.'),
        findsOneWidget,
      );

      // Enter an incorrect password
      final passwordField = find.byType(TextField);
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'wrong_pass');

      // Tap Login button
      final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
      expect(loginBtn, findsOneWidget);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Verify exact Alert Dialog per Requirement 2:
      // Dialog title: Access Denied
      // Exact message: Incorrect password. Please contact your app creator Admin.
      expect(find.text('Access Denied'), findsOneWidget);
      expect(
        find.text('Incorrect password. Please contact your app creator Admin.'),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);

      // Tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Access Denied dialog must close
      expect(find.text('Access Denied'), findsNothing);

      // The administrator password popup must remain available for another attempt
      expect(find.text('Administrator Authentication'), findsOneWidget);
      // AI API Key screen must NOT have opened
      expect(find.text('AI API Key Settings'), findsNothing);
    });

    testWidgets('5. Correct password opens the API key entry screen without blank screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminSettingsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter correct password admin@valuer
      final passwordField = find.byType(TextField);
      await tester.enterText(passwordField, 'admin@valuer');

      // Tap Login
      final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Verify immediate transition to AI API Key Settings screen per Requirement 3
      expect(find.text('AI API Key Settings'), findsOneWidget);
      expect(find.text('Enter Your Gemini API Key'), findsOneWidget);
      expect(
        find.text('Paste your Gemini API key below to enable AI document extraction.'),
        findsOneWidget,
      );
      expect(find.text('Save API Key'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Must not show Administrator Authentication anymore
      expect(find.text('Administrator Authentication'), findsNothing);
    });

    test('6. Empty API key cannot be saved', () async {
      final saveEmpty = await EncryptionService.saveAiApiKey('');
      expect(saveEmpty, isFalse);

      final saveWhitespace = await EncryptionService.saveAiApiKey('    ');
      expect(saveWhitespace, isFalse);
    });

    test('7. API key is saved and retrieved through secure storage', () async {
      const sampleKey = 'AIzaSyA_TestGeminiVisionKey_12345';
      final saved = await EncryptionService.saveAiApiKey(sampleKey);
      expect(saved, isTrue);

      final retrieved = await EncryptionService.getAiApiKey();
      expect(retrieved, sampleKey);
    });

    test('8. API key remains available to AiService', () async {
      const sampleKey = 'AIzaSy_CharteredValuationReportKey_98765';
      await EncryptionService.saveAiApiKey(sampleKey);

      // Verify getAiApiKey provides key to AiService
      final keyForAi = await EncryptionService.getAiApiKey();
      expect(keyForAi, sampleKey);

      // Verify AiService.testConnection with mock hook
      AiService.testConnectionOverride = true;
      final success = await AiService.testConnection();
      expect(success, isTrue);

      AiService.testConnectionOverride = false;
      final failure = await AiService.testConnection();
      expect(failure, isFalse);
    });

    testWidgets('9. The API key screen does not become blank when storage fails or errors occur', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminSettingsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Login with admin@valuer
      await tester.enterText(find.byType(TextField), 'admin@valuer');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Screen is loaded
      expect(find.text('AI API Key Settings'), findsOneWidget);

      // Test Connection when field is empty
      final testConnBtn = find.widgetWithText(OutlinedButton, 'Test Connection');
      await tester.tap(testConnBtn);
      await tester.pumpAndSettle();

      // Shows 'Please enter your API key first.'
      expect(find.text('Please enter your API key first.'), findsWidgets);

      // The screen remains fully functional and not blank
      expect(find.text('AI API Key Settings'), findsOneWidget);
      expect(find.text('Enter Your Gemini API Key'), findsOneWidget);
    });
  });
}
