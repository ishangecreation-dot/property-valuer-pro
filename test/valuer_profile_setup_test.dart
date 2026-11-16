import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_valuer_pro/models/valuer_profile.dart';
import 'package:property_valuer_pro/models/valuation_project.dart';
import 'package:property_valuer_pro/core/storage/storage_service.dart';
import 'package:property_valuer_pro/core/services/ai_service.dart';
import 'package:property_valuer_pro/core/services/dossier_markdown_service.dart';
import 'package:property_valuer_pro/features/profile/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AiService.analyzeReportStyleOverride = null;
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

    test('2. ValuerProfile serializes and deserializes all fields correctly including drafts & AI style', () {
      final original = ValuerProfile(
        id: 'draft_101',
        draftName: 'Colombo Chambers',
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
        reportFormat: 'Chartered 10-Point Schedule & Executive Appraisal Table',
        reportStyle: 'Formal Chartered Practitioner Terminology & LKR Rounding',
        reportType: 'Real Estate Mortgage Collateral Valuation',
        reportStyleSummary: 'Executive summary with standard per-perch valuation table.',
        templateStyleNotes: {'Custom_Report.docx': 'Standard layout'},
      );

      final jsonMap = original.toJson();
      final restored = ValuerProfile.fromJson(jsonMap);

      expect(restored.id, 'draft_101');
      expect(restored.draftName, 'Colombo Chambers');
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
      expect(restored.reportFormat, contains('10-Point Schedule'));
      expect(restored.reportStyle, contains('Chartered Practitioner'));
      expect(restored.reportType, contains('Mortgage Collateral'));
      expect(restored.reportStyleSummary, contains('Executive summary'));
      expect(restored.templateStyleNotes['Custom_Report.docx'], 'Standard layout');
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

    test('4. StorageService manages multiple profile drafts (save, load, delete)', () async {
      final draft1 = ValuerProfile(
        id: 'draft_colombo',
        draftName: 'Colombo Chambers',
        valuerName: 'Vlr. A. Perera',
        qualifications: 'B.Sc., FIV',
        registrationNumber: 'REG-001',
        officeAddress: 'Colombo 03',
        contactNumber: '0771112233',
      );

      final draft2 = ValuerProfile(
        id: 'draft_kandy',
        draftName: 'Kandy Practice',
        valuerName: 'Vlr. B. Silva',
        qualifications: 'MRICS',
        registrationNumber: 'REG-002',
        officeAddress: 'Kandy',
        contactNumber: '0812233445',
      );

      await StorageService.saveProfileDraft(draft1);
      await StorageService.saveProfileDraft(draft2);

      final drafts = await StorageService.loadProfileDrafts();
      expect(drafts.length, 2);
      expect(drafts.any((d) => d.draftName == 'Colombo Chambers'), isTrue);
      expect(drafts.any((d) => d.draftName == 'Kandy Practice'), isTrue);

      await StorageService.deleteProfileDraft('draft_colombo');
      final remaining = await StorageService.loadProfileDrafts();
      expect(remaining.length, 1);
      expect(remaining.first.draftName, 'Kandy Practice');
    });

    test('5. AiService.analyzeReportConventions extracts format, style, type, and blueprint', () async {
      final result = await AiService.analyzeReportConventions([
        'Sample_Valuation_Report_1.docx',
        'Sample_Valuation_Report_2.pdf',
      ]);
      expect(result.reportFormat.isNotEmpty, isTrue);
      expect(result.reportStyle.isNotEmpty, isTrue);
      expect(result.reportType.isNotEmpty, isTrue);
      expect(result.detailedBlueprint, contains('Executive Summary'));
    });

    test('5b. DossierMarkdownService builds structured markdown collecting all steps', () {
      final profile = ValuerProfile(
        valuerName: 'Vlr. Nimal Jayawardena',
        qualifications: 'B.Sc. Estate Mgt, MRICS',
        registrationNumber: 'IVSL/A/100',
        officeAddress: 'No. 25, Duplication Road, Colombo 03',
        contactNumber: '0771234567',
        uploadedTemplates: ['Sample_Report.docx'],
        reportFormat: 'Chartered 10-Point Schedule & Executive Appraisal Table',
        reportStyle: 'Formal Chartered Practitioner Terminology & LKR Rounding',
        reportType: 'Real Estate Mortgage Collateral Valuation',
      );

      final project = ValuationProject(
        id: 'proj_123',
        projectName: 'Prime Commercial Property Appraisal',
        clientOrBank: 'Bank of Ceylon',
      );

      final md = DossierMarkdownService.buildDossierMarkdown(
        profile: profile,
        project: project,
      );

      expect(md, contains('# Chartered Valuation Report Case Dossier'));
      expect(md, contains('Prime Commercial Property Appraisal'));
      expect(md, contains('Bank of Ceylon'));
      expect(md, contains('Vlr. Nimal Jayawardena'));
      expect(md, contains('Report Format:'));
      expect(md, contains('Report Style:'));
      expect(md, contains('Report Type:'));
      expect(md, contains('## 3. Title Deed Extraction Particulars & Devolution (Step 3)'));
      expect(md, contains('## 4. Cadastral Survey Plan Particulars & Exact Lots (Step 4)'));
      expect(md, contains('## 9. Chartered Valuation Engine & Calculations (Step 9)'));
    });
  });

  group('Valuer Profile Setup – UI & Screen 2 Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        routes: {
          '/': (context) => const ProfileScreen(),
          '/step3': (context) => const Scaffold(body: Text('Step 3 Deed Screen')),
        },
      );
    }

    testWidgets('6. Screen 2 displays title and universal hints without prefilled personal names', (tester) async {
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

      // Dedicated Save & Next to Deed Button
      expect(find.byKey(const Key('save_and_next_to_deed_button')), findsOneWidget);
      expect(find.text('Save & Next to Deed'), findsWidgets);
    });

    testWidgets('7. Tapping Save Profile with empty fields triggers required field validation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      expect(find.text('Please enter your Valuer Name.'), findsOneWidget);
    });

    testWidgets('8. Validation catches missing qualifications, registration, address, and phone', (tester) async {
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

    testWidgets('9. Filling all required fields saves profile successfully and displays confirmation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('valuer_name_field')), 'Vlr. Kamal Jayasinghe');
      await tester.enterText(find.byKey(const Key('qualifications_field')), 'B.Sc. Estate Mgt & Val, AIV');
      await tester.enterText(find.byKey(const Key('registration_number_field')), 'IVSL/A/888');
      await tester.enterText(find.byKey(const Key('office_address_field')), 'No. 100, High Level Road, Nugegoda');
      await tester.enterText(find.byKey(const Key('contact_number_1_field')), '+94 77 000 1122');

      final saveBtn = find.byKey(const Key('save_profile_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      expect(find.text('Profile saved successfully. Dossier updated.'), findsOneWidget);

      final saved = await StorageService.loadProfile();
      expect(saved.valuerName, 'Vlr. Kamal Jayasinghe');
      expect(saved.qualifications, 'B.Sc. Estate Mgt & Val, AIV');
      expect(saved.registrationNumber, 'IVSL/A/888');
      expect(saved.officeAddress, 'No. 100, High Level Road, Nugegoda');
      expect(saved.contactNumber, '+94 77 000 1122');
      expect(saved.isConfigured, isTrue);
    });

    testWidgets('10. Profile automatically loads saved data upon reopening the screen', (tester) async {
      final preSaved = ValuerProfile(
        valuerName: 'Vlr. Sunethra Bandara',
        qualifications: 'M.Sc. Real Estate, FRICS',
        registrationNumber: 'RICS/654321',
        officeAddress: 'No. 78, Peradeniya Road, Kandy',
        contactNumber: '+94 81 223 3445',
        contactNumber2: '+94 71 888 9900',
      );
      await StorageService.saveProfile(preSaved);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Vlr. Sunethra Bandara'), findsOneWidget);
      expect(find.text('M.Sc. Real Estate, FRICS'), findsOneWidget);
      expect(find.text('RICS/654321'), findsOneWidget);
      expect(find.text('No. 78, Peradeniya Road, Kandy'), findsOneWidget);
      expect(find.text('+94 81 223 3445'), findsOneWidget);
      expect(find.text('+94 71 888 9900'), findsOneWidget);
    });

    testWidgets('11. Document analysis displays clean right-mark status without verbose text and allows viewing dossier', (tester) async {
      final preSaved = ValuerProfile(
        valuerName: 'Vlr. Sunethra Bandara',
        qualifications: 'M.Sc. Real Estate, FRICS',
        registrationNumber: 'RICS/654321',
        officeAddress: 'No. 78, Peradeniya Road, Kandy',
        contactNumber: '+94 81 223 3445',
        uploadedTemplates: ['Chambers_Standard_Draft_1.docx'],
        reportFormat: 'Chartered 10-Point Schedule & Executive Appraisal Table',
        reportStyle: 'Formal Chartered Practitioner Terminology & LKR Rounding',
        reportType: 'Real Estate Mortgage Collateral & Bank Panel Valuation',
        reportStyleSummary: 'Executive summary with standard per-perch valuation table and GRC itemization.',
      );
      await StorageService.saveProfile(preSaved);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Clean message with right marks should be displayed
      expect(find.text('Document analyze complete'), findsOneWidget);
      expect(find.text('Report format: '), findsOneWidget);
      expect(find.text('Report style: '), findsOneWidget);
      expect(find.text('Report type: '), findsOneWidget);

      // Verify the View Dossier MD button is present
      final viewDossierBtn = find.text('View Dossier MD');
      expect(viewDossierBtn, findsOneWidget);
      await tester.tap(viewDossierBtn);
      await tester.pumpAndSettle();

      // Verify modal opens with Markdown Dossier
      expect(find.text('Valuation Case Dossier (.md)'), findsOneWidget);
    });

    testWidgets('12. Dedicated [Save & Next to Deed] button validates, saves draft, and navigates to Step 3', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('valuer_name_field')), 'Vlr. Nimal Dias');
      await tester.enterText(find.byKey(const Key('qualifications_field')), 'B.Sc. Estate Management, AIV');
      await tester.enterText(find.byKey(const Key('registration_number_field')), 'IVSL/REG/777');
      await tester.enterText(find.byKey(const Key('office_address_field')), 'No. 45, Temple Road, Mount Lavinia');
      await tester.enterText(find.byKey(const Key('contact_number_1_field')), '+94 77 789 0123');

      final nextBtn = find.byKey(const Key('save_and_next_to_deed_button'));
      await tester.ensureVisible(nextBtn);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Step 3 Deed Screen'), findsOneWidget);

      final drafts = await StorageService.loadProfileDrafts();
      expect(drafts.isNotEmpty, isTrue);
      expect(drafts.any((d) => d.valuerName == 'Vlr. Nimal Dias'), isTrue);
    });
  });
}
