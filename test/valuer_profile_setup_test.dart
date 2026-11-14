import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_valuer_pro/models/valuer_profile.dart';
import 'package:property_valuer_pro/core/storage/storage_service.dart';
import 'package:property_valuer_pro/features/profile/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Valuer Profile Setup – Model & Persistence Tests', () {
    test('1. Default ValuerProfile initializes with empty fields and no hardcoded personal name', () {
      final profile = ValuerProfile();
      expect(profile.valuerName, isEmpty);
      expect(profile.qualifications, isEmpty);
      expect(profile.registrationNumber, isEmpty);
      expect(profile.officeAddress, isEmpty);
      expect(profile.contactNumber, isEmpty);
      expect(profile.contactNumber1, isEmpty);
      expect(profile.contactNumber2, isEmpty);
      expect(profile.isConfigured, isFalse);
    });

    test('2. ValuerProfile serializes and deserializes all fields correctly', () {
      final original = ValuerProfile(
        valuerName: 'Vlr. J. M. Silva',
        qualifications: 'B.Sc. Estate Management & Valuation (USJP)',
        professionalMembership: 'Associate Member (AIV)',
        registrationNumber: 'IVSL/REG/A-999',
        officeAddress: 'No. 12, Queens Road, Colombo 03',
        emailAddress: 'silva.valuations@example.com',
        contactNumber: '+94 77 123 4567',
        contactNumber2: '+94 11 234 5678',
        additionalContactDetails: 'Panel: BOC, People\'s Bank',
        uploadedTemplates: ['Custom_Report.docx'],
      );

      final jsonMap = original.toJson();
      final restored = ValuerProfile.fromJson(jsonMap);

      expect(restored.valuerName, 'Vlr. J. M. Silva');
      expect(restored.qualifications, 'B.Sc. Estate Management & Valuation (USJP)');
      expect(restored.professionalMembership, 'Associate Member (AIV)');
      expect(restored.registrationNumber, 'IVSL/REG/A-999');
      expect(restored.officeAddress, 'No. 12, Queens Road, Colombo 03');
      expect(restored.emailAddress, 'silva.valuations@example.com');
      expect(restored.contactNumber, '+94 77 123 4567');
      expect(restored.contactNumber1, '+94 77 123 4567');
      expect(restored.contactNumber2, '+94 11 234 5678');
      expect(restored.additionalContactDetails, 'Panel: BOC, People\'s Bank');
      expect(restored.uploadedTemplates, contains('Custom_Report.docx'));
      expect(restored.isConfigured, isTrue);
    });

    test('3. StorageService persists and reloads profile across app launches', () async {
      final profile = ValuerProfile(
        valuerName: 'Vlr. D. Fernando',
        qualifications: 'MRICS, FIV (Sri Lanka)',
        registrationNumber: 'FIV/2024/042',
        officeAddress: 'No. 55, Galle Road, Colombo 04',
        contactNumber: '+94 71 555 6677',
      );

      await StorageService.saveProfile(profile);

      final reloaded = await StorageService.loadProfile();
      expect(reloaded.valuerName, 'Vlr. D. Fernando');
      expect(reloaded.qualifications, 'MRICS, FIV (Sri Lanka)');
      expect(reloaded.registrationNumber, 'FIV/2024/042');
      expect(reloaded.officeAddress, 'No. 55, Galle Road, Colombo 04');
      expect(reloaded.contactNumber, '+94 71 555 6677');
      expect(reloaded.isConfigured, isTrue);
    });
  });

  group('Valuer Profile Setup – UI & Screen 2 Tests', () {
    Widget buildTestWidget() {
      return const MaterialApp(
        home: ProfileScreen(),
      );
    }

    testWidgets('4. Screen 2 displays title and universal hints without prefilled personal names', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Valuer Profile Setup'), findsOneWidget);

      // Section Cards
      expect(find.text('Professional Details'), findsOneWidget);
      expect(find.text('Office and Contact Details'), findsOneWidget);

      // Universal Example Hints
      expect(find.text('YOUR NAME HERE'), findsOneWidget);
      expect(find.text('Enter your professional qualifications here'), findsOneWidget);
      expect(find.text('Enter your registration number'), findsOneWidget);
      expect(find.text('Enter your office address'), findsOneWidget);

      // Save Profile Button
      expect(find.byKey(const Key('save_profile_button')), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
    });

    testWidgets('5. Tapping Save Profile with empty fields triggers required field validation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Save Profile while fields are empty
      final saveBtn = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      // Must display validation error for the first missing required field
      expect(find.text('Please enter your Valuer Name.'), findsOneWidget);
    });

    testWidgets('6. Validation catches missing qualifications, registration, address, and phone', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveBtn);

      // Fill Valuer Name only
      await tester.enterText(find.byKey(const Key('valuer_name_field')), 'Vlr. Test User');
      await tester.tap(saveBtn);
      await tester.pump();
      expect(find.text('Please enter your Qualifications.'), findsOneWidget);

      // Fill Qualifications
      await tester.enterText(find.byKey(const Key('qualifications_field')), 'B.Sc. Estate Mgt.');
      await tester.tap(saveBtn);
      await tester.pump();
      expect(find.text('Please enter your Registration Number.'), findsOneWidget);

      // Fill Registration Number
      await tester.enterText(find.byKey(const Key('registration_number_field')), 'REG-1234');
      await tester.tap(saveBtn);
      await tester.pump();
      expect(find.text('Please enter your Office Address.'), findsOneWidget);

      // Fill Office Address
      await tester.enterText(find.byKey(const Key('office_address_field')), 'Colombo 07');
      await tester.tap(saveBtn);
      await tester.pump();
      expect(find.text('Please enter Contact Number 1.'), findsOneWidget);
    });

    testWidgets('7. Filling all required fields saves profile successfully and displays confirmation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter valid required credentials
      await tester.enterText(find.byKey(const Key('valuer_name_field')), 'Vlr. Kamal Jayasinghe');
      await tester.enterText(find.byKey(const Key('qualifications_field')), 'B.Sc. Estate Mgt & Val, AIV');
      await tester.enterText(find.byKey(const Key('registration_number_field')), 'IVSL/A/888');
      await tester.enterText(find.byKey(const Key('office_address_field')), 'No. 100, High Level Road, Nugegoda');
      await tester.enterText(find.byKey(const Key('contact_number_1_field')), '+94 77 000 1122');
      // Contact Number 2 is optional - leave empty

      final saveBtn = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      // Confirmation message
      expect(find.text('Profile saved successfully.'), findsOneWidget);

      // Verify persistence in StorageService
      final saved = await StorageService.loadProfile();
      expect(saved.valuerName, 'Vlr. Kamal Jayasinghe');
      expect(saved.qualifications, 'B.Sc. Estate Mgt & Val, AIV');
      expect(saved.registrationNumber, 'IVSL/A/888');
      expect(saved.officeAddress, 'No. 100, High Level Road, Nugegoda');
      expect(saved.contactNumber, '+94 77 000 1122');
      expect(saved.contactNumber2, isEmpty);
      expect(saved.isConfigured, isTrue);
    });

    testWidgets('8. Profile automatically loads saved data upon reopening the screen', (tester) async {
      // Pre-save profile data into storage
      final preSaved = ValuerProfile(
        valuerName: 'Vlr. Sunethra Bandara',
        qualifications: 'M.Sc. Real Estate, FRICS',
        registrationNumber: 'RICS/654321',
        officeAddress: 'No. 78, Peradeniya Road, Kandy',
        contactNumber: '+94 81 223 3445',
        contactNumber2: '+94 71 888 9900',
      );
      await StorageService.saveProfile(preSaved);

      // Open ProfileScreen fresh
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify fields auto-populated
      expect(find.text('Vlr. Sunethra Bandara'), findsOneWidget);
      expect(find.text('M.Sc. Real Estate, FRICS'), findsOneWidget);
      expect(find.text('RICS/654321'), findsOneWidget);
      expect(find.text('No. 78, Peradeniya Road, Kandy'), findsOneWidget);
      expect(find.text('+94 81 223 3445'), findsOneWidget);
      expect(find.text('+94 71 888 9900'), findsOneWidget);
    });
  });
}
