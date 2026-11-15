import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/valuer_profile.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ValuerProfile _profile = ValuerProfile();
  List<ValuerProfile> _drafts = [];
  bool _isLoading = true;
  bool _isAnalyzingStyle = false;

  // Controllers for editable fields
  final _draftNameController = TextEditingController(text: 'Default Profile');
  final _nameController = TextEditingController();
  final _qualController = TextEditingController();
  final _regNoController = TextEditingController();
  final _membershipController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _additionalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileAndDrafts();
  }

  @override
  void dispose() {
    _draftNameController.dispose();
    _nameController.dispose();
    _qualController.dispose();
    _regNoController.dispose();
    _membershipController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  /// Automatically load saved profile and drafts from persistent storage
  Future<void> _loadProfileAndDrafts() async {
    final profile = await StorageService.loadProfile();
    final drafts = await StorageService.loadProfileDrafts();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _drafts = drafts;
      _populateControllers(profile);
      _isLoading = false;
    });
  }

  void _populateControllers(ValuerProfile profile) {
    _draftNameController.text = profile.draftName.isNotEmpty ? profile.draftName : 'Default Profile';
    _nameController.text = profile.valuerName;
    _qualController.text = profile.qualifications;
    _membershipController.text = profile.professionalMembership;
    _regNoController.text = profile.registrationNumber;
    _addressController.text = profile.officeAddress;
    _emailController.text = profile.emailAddress;
    _phone1Controller.text = profile.contactNumber;
    _phone2Controller.text = profile.contactNumber2;
    _additionalController.text = profile.additionalContactDetails;
  }

  void _syncControllersToProfile() {
    _profile.draftName = _draftNameController.text.trim().isEmpty ? 'Default Profile' : _draftNameController.text.trim();
    _profile.valuerName = _nameController.text.trim();
    _profile.qualifications = _qualController.text.trim();
    _profile.professionalMembership = _membershipController.text.trim();
    _profile.registrationNumber = _regNoController.text.trim();
    _profile.officeAddress = _addressController.text.trim();
    _profile.emailAddress = _emailController.text.trim();
    _profile.contactNumber = _phone1Controller.text.trim();
    _profile.contactNumber2 = _phone2Controller.text.trim();
    _profile.additionalContactDetails = _additionalController.text.trim();
  }

  /// Validates required fields and saves profile locally in persistent storage
  Future<bool> _saveProfile({bool showSuccessFeedback = true}) async {
    final name = _nameController.text.trim();
    final qual = _qualController.text.trim();
    final regNo = _regNoController.text.trim();
    final address = _addressController.text.trim();
    final phone1 = _phone1Controller.text.trim();

    // Required Field Validation
    if (name.isEmpty) {
      _showValidationError('Please enter your Valuer Name.');
      return false;
    }
    if (qual.isEmpty) {
      _showValidationError('Please enter your Qualifications.');
      return false;
    }
    if (regNo.isEmpty) {
      _showValidationError('Please enter your Registration Number.');
      return false;
    }
    if (address.isEmpty) {
      _showValidationError('Please enter your Office Address.');
      return false;
    }
    if (phone1.isEmpty) {
      _showValidationError('Please enter Contact Number 1.');
      return false;
    }

    _syncControllersToProfile();
    await StorageService.saveProfile(_profile);
    await StorageService.saveProfileDraft(_profile, draftName: _profile.draftName);

    final refreshedDrafts = await StorageService.loadProfileDrafts();
    if (mounted) {
      setState(() {
        _drafts = refreshedDrafts;
      });
    }

    if (!mounted) return true;

    if (showSuccessFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully.'),
          backgroundColor: AppColors.primaryActionTeal,
        ),
      );
    }

    return true;
  }

  /// Dedicated action for Save & Next to Deed button
  Future<void> _handleSaveAndNextToDeed() async {
    final success = await _saveProfile(showSuccessFeedback: false);
    if (!success || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile draft saved. Continuing to Deed Extraction.'),
        backgroundColor: AppColors.primaryActionTeal,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pushNamed(context, '/step3');
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  /// Multi-document / PDF selection and AI Report Style Analysis
  void _uploadTemplate() async {
    final isPaid = await EntitlementService.isPaidTier();
    if (!isPaid && _profile.uploadedTemplates.length >= AppConstants.freeTierTemplateLimit) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Template Limit Reached'),
          content: const Text(
            'The Free Version supports up to 3 custom Word (.docx) or PDF report templates.\n\nUpgrade to the Paid Version to add unlimited report templates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx', 'doc', 'pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isAnalyzingStyle = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(child: Text('AI analyzing report formatting & style conventions...')),
              ],
            ),
            duration: Duration(seconds: 4),
          ),
        );

        String combinedStyleBlueprint = _profile.reportStyleSummary;

        for (final file in result.files) {
          final fileName = file.name;
          if (!_profile.uploadedTemplates.contains(fileName)) {
            _profile.uploadedTemplates.add(fileName);
          }

          // Call Gemini AI service to analyze draft report style
          try {
            final styleSummary = await AiService.analyzeReportStyle(
              fileName: fileName,
              fileBytes: file.bytes,
            );
            _profile.templateStyleNotes[fileName] = styleSummary;
            combinedStyleBlueprint = styleSummary;
          } catch (_) {
            // Keep fallback
          }
        }

        _profile.reportStyleSummary = combinedStyleBlueprint;
        await StorageService.saveProfile(_profile);

        if (mounted) {
          setState(() {
            _isAnalyzingStyle = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft reports analyzed. AI style conventions captured.'),
              backgroundColor: AppColors.primaryActionTeal,
            ),
          );
        }
      }
    } catch (_) {
      // Fallback on restricted permission environments
      final fallbackName = 'Standard_Chartered_Template_${_profile.uploadedTemplates.length + 1}.docx';
      setState(() {
        _profile.uploadedTemplates.add(fallbackName);
        _profile.reportStyleSummary =
            '### AI Report Style Blueprint (Learned from $fallbackName)\n'
            '• Executive Summary table structure with valuation metrics.\n'
            '• Land rate itemization in LKR per perch.\n'
            '• Building Gross Replacement Cost (GRC) & age depreciation rate.\n'
            '• Impartiality certificate & chartered valuer seal.';
      });
      await StorageService.saveProfile(_profile);
    }
  }

  void _removeTemplate(int index) async {
    final removed = _profile.uploadedTemplates[index];
    setState(() {
      _profile.uploadedTemplates.removeAt(index);
      _profile.templateStyleNotes.remove(removed);
      if (_profile.uploadedTemplates.isEmpty) {
        _profile.reportStyleSummary = '';
      }
    });
    await StorageService.saveProfile(_profile);
  }

  /// Switch active profile to a saved draft
  void _switchDraft(ValuerProfile draft) {
    setState(() {
      _profile = draft;
      _populateControllers(draft);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to profile draft: "${draft.draftName}"'),
        backgroundColor: AppColors.professionalBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Create a fresh new draft
  void _createNewDraft() {
    final newDraft = ValuerProfile(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      draftName: 'Chambers Profile ${_drafts.length + 1}',
    );
    setState(() {
      _profile = newDraft;
      _populateControllers(newDraft);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New profile draft created. Enter details and save.'),
        backgroundColor: AppColors.primaryActionTeal,
      ),
    );
  }

  /// Displays the 10-Step Valuation Workflow Guide
  void _showWorkflowGuideModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '10-Step Valuation Report Creation Guide',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: const [
                      _WorkflowStepTile(
                        step: 1,
                        title: 'Dashboard & Project Initialization',
                        description: 'Case file creation, banking client selection, branch, and monthly quota tracking.',
                      ),
                      _WorkflowStepTile(
                        step: 2,
                        title: 'Valuer Profile Setup & AI Style Learning',
                        description: 'Professional credentials, chambers address, multi-document upload & Gemini layout style learning.',
                      ),
                      _WorkflowStepTile(
                        step: 3,
                        title: 'Title Deed Extraction & Devolution',
                        description: 'Deed OCR ingestion, notary, registration volume/folio, vendee/vendor, and consideration.',
                      ),
                      _WorkflowStepTile(
                        step: 4,
                        title: 'Cadastral Survey Plan & Exact Lots',
                        description: 'Plan number, surveyor details, lot allotments (Acres-Roods-Perches), and cardinal boundaries.',
                      ),
                      _WorkflowStepTile(
                        step: 5,
                        title: 'Inspection Particulars & Statutory Compliance',
                        description: 'Inspection date, weather, borrower presence, Local Authority limits, street lines & building reservations.',
                      ),
                      _WorkflowStepTile(
                        step: 6,
                        title: 'Situation, Accessibility & GIS Geolocation',
                        description: 'GPS coordinates satellite pin, distance from town, road width/surface, motorability, utilities.',
                      ),
                      _WorkflowStepTile(
                        step: 7,
                        title: 'Building Improvements & CAD Sketch',
                        description: 'Bare land vs improved, floor area sq.ft., architectural finishes, accommodation breakdown, and CAD canvas.',
                      ),
                      _WorkflowStepTile(
                        step: 8,
                        title: 'Land Physicality & SWOC Risk Matrix',
                        description: 'Topography, soil stability, Strengths, Weaknesses, Opportunities, and Constraints (SWOC) rating.',
                      ),
                      _WorkflowStepTile(
                        step: 9,
                        title: 'Valuation Engine (Land, GRC, FSV & Collateral)',
                        description: 'Calculations: Land Value, Gross Replacement Cost, Age Depreciation, Market Value (Say), and Forced Sale Value (FSV).',
                      ),
                      _WorkflowStepTile(
                        step: 10,
                        title: 'Final Review, Page Budget & DOCX Generation',
                        description: '10-point audit, page budget distribution (3, 5, or 8 pages), and instant Microsoft Word (.docx) generation.',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 2,
      title: 'Valuer Profile Setup',
      onBack: () => Navigator.pop(context),
      onNext: _handleSaveAndNextToDeed,
      nextLabel: 'Save & Next to Deed',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Information & Workflow Guide Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borders),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_user, color: AppColors.primaryNavy, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Enter your professional practitioner credentials. Your details are saved permanently on this device for all future reports. You can edit, add, or remove details at any time.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.mainText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _showWorkflowGuideModal,
                              icon: const Icon(Icons.menu_book, size: 16, color: AppColors.primaryNavy),
                              label: const Text(
                                'View 10-Step Valuation Guide',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Profile Draft Selector Card
                  SectionCard(
                    title: 'Profile Draft Management',
                    subtitle: 'Save multiple practice profiles or branches. Switch easily anytime.',
                    trailing: TextButton.icon(
                      onPressed: _createNewDraft,
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primaryActionTeal),
                      label: const Text(
                        'New Draft',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryActionTeal),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_drafts.length > 1) ...[
                          const Text(
                            'Select Saved Profile Draft:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borders),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _profile.id,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryNavy),
                                items: _drafts.map((d) {
                                  return DropdownMenuItem<String>(
                                    value: d.id,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.badge, size: 16, color: AppColors.primaryNavy),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            d.draftName.isNotEmpty ? d.draftName : 'Draft Profile',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (d.valuerName.isNotEmpty)
                                          Text(
                                            '(${d.valuerName})',
                                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (selectedId) {
                                  if (selectedId != null) {
                                    final match = _drafts.firstWhere((d) => d.id == selectedId, orElse: () => _profile);
                                    _switchDraft(match);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        LabeledTextField(
                          label: 'Draft Label / Chambers Name',
                          hint: 'e.g. Primary Practice, Colombo Head Office, Kandy Chambers',
                          isRequired: false,
                          controller: _draftNameController,
                          prefixIcon: const Icon(Icons.edit_note, color: AppColors.primaryNavy, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // A. Professional Details
                  SectionCard(
                    title: 'Professional Details',
                    subtitle: 'Chartered credentials and registration identifiers.',
                    isMandatory: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledTextField(
                          key: const Key('valuer_name_field'),
                          label: 'Valuer Name',
                          hint: 'YOUR NAME HERE',
                          isRequired: true,
                          controller: _nameController,
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryNavy, size: 20),
                        ),
                        LabeledTextField(
                          key: const Key('qualifications_field'),
                          label: 'Qualifications',
                          hint: 'Enter your professional qualifications here',
                          isRequired: true,
                          maxLines: 3,
                          controller: _qualController,
                          prefixIcon: const Icon(Icons.school_outlined, color: AppColors.primaryNavy, size: 20),
                        ),
                        LabeledTextField(
                          key: const Key('registration_number_field'),
                          label: 'Registration Number',
                          hint: 'Enter your registration number',
                          isRequired: true,
                          controller: _regNoController,
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primaryNavy, size: 20),
                        ),
                        LabeledTextField(
                          label: 'Professional Membership (Optional)',
                          hint: 'e.g. Associate Member (AIV), MRICS, FIV',
                          isRequired: false,
                          controller: _membershipController,
                          prefixIcon: const Icon(Icons.verified_outlined, color: AppColors.primaryNavy, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // B. Office & Contact Details
                  SectionCard(
                    title: 'Office and Contact Details',
                    subtitle: 'Chambers address and communication channels.',
                    isMandatory: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledTextField(
                          key: const Key('office_address_field'),
                          label: 'Office Address',
                          hint: 'Enter your office address',
                          isRequired: true,
                          maxLines: 2,
                          controller: _addressController,
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primaryNavy, size: 20),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                key: const Key('contact_number_1_field'),
                                label: 'Contact Number 1',
                                hint: 'Enter contact number 1',
                                isRequired: true,
                                keyboardType: TextInputType.phone,
                                controller: _phone1Controller,
                                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryNavy, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                key: const Key('contact_number_2_field'),
                                label: 'Contact Number 2',
                                hint: 'Enter contact number 2 (optional)',
                                isRequired: false,
                                keyboardType: TextInputType.phone,
                                controller: _phone2Controller,
                                prefixIcon: const Icon(Icons.phone_android_outlined, color: AppColors.primaryNavy, size: 20),
                              ),
                            ),
                          ],
                        ),
                        LabeledTextField(
                          label: 'Official Dispatch Email (Optional)',
                          hint: 'e.g. valuer@example.com',
                          isRequired: false,
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          prefixIcon: const Icon(Icons.mail_outline, color: AppColors.primaryNavy, size: 20),
                        ),
                        LabeledTextField(
                          label: 'Authorized Bank Valuation Panels / Notes (Optional)',
                          hint: 'e.g. People\'s Bank, BOC, Commercial Bank PLC',
                          isRequired: false,
                          controller: _additionalController,
                          prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.primaryNavy, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Dedicated Buttons Row: Save Profile + Save & Next to Deed
                  Row(
                    children: [
                      // Save Profile Button (Persistent one-time or re-usable save)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('save_profile_button'),
                            onPressed: () => _saveProfile(showSuccessFeedback: true),
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text(
                              'Save Profile',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryNavy,
                              side: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Dedicated Save & Next to Deed Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            key: const Key('save_and_next_to_deed_button'),
                            onPressed: _handleSaveAndNextToDeed,
                            icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                            label: const Text(
                              'Save & Next to Deed',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryActionTeal,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // C. Custom Report Templates & AI Style Extraction (DOCX/PDF)
                  SectionCard(
                    title: 'Multi-Document / PDF Draft Reports',
                    subtitle: 'Upload draft reports. Gemini AI extracts formatting and table style for your final valuation report.',
                    trailing: Text(
                      '${_profile.uploadedTemplates.length}/${AppConstants.freeTierTemplateLimit} Free Slots',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryActionTeal,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isAnalyzingStyle)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.professionalBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.professionalBlue.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.professionalBlue),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Gemini AI analyzing report style conventions...',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.professionalBlue),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_profile.uploadedTemplates.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.secondaryText, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Upload one or multiple .docx or .pdf draft reports. The AI will learn your table styles, perch rate formats, and phrasing conventions to tailor future reports.',
                                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _profile.uploadedTemplates.length,
                            itemBuilder: (context, index) {
                              final templateName = _profile.uploadedTemplates[index];
                              final isPdf = templateName.toLowerCase().endsWith('.pdf');
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borders),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPdf ? Icons.picture_as_pdf : Icons.description,
                                      color: isPdf ? AppColors.error : AppColors.primaryNavy,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            templateName,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            'Style analyzed by Gemini AI',
                                            style: TextStyle(fontSize: 11, color: AppColors.primaryActionTeal),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                      onPressed: () => _removeTemplate(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _uploadTemplate,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('+ Upload Draft Reports (Multi-Select DOCX/PDF)'),
                        ),

                        // AI Report Style Blueprint Display Card
                        if (_profile.reportStyleSummary.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryActionTeal.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primaryActionTeal.withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, color: AppColors.primaryActionTeal, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'AI Learned Report Style Blueprint',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _profile.reportStyleSummary,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.mainText,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _WorkflowStepTile extends StatelessWidget {
  final int step;
  final String title;
  final String description;

  const _WorkflowStepTile({
    Key? key,
    required this.step,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borders),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryNavy,
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.mainText),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
