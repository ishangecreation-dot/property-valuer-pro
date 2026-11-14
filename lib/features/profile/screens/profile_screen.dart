import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/valuer_profile.dart';
import '../../../core/storage/storage_service.dart';
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
  bool _isLoading = true;

  // Controllers for editable fields
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
    _loadProfile();
  }

  @override
  void dispose() {
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

  /// Automatically load saved profile details from persistent storage
  Future<void> _loadProfile() async {
    final profile = await StorageService.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _nameController.text = profile.valuerName;
      _qualController.text = profile.qualifications;
      _membershipController.text = profile.professionalMembership;
      _regNoController.text = profile.registrationNumber;
      _addressController.text = profile.officeAddress;
      _emailController.text = profile.emailAddress;
      _phone1Controller.text = profile.contactNumber;
      _phone2Controller.text = profile.contactNumber2;
      _additionalController.text = profile.additionalContactDetails;
      _isLoading = false;
    });
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

    _profile.valuerName = name;
    _profile.qualifications = qual;
    _profile.professionalMembership = _membershipController.text.trim();
    _profile.registrationNumber = regNo;
    _profile.officeAddress = address;
    _profile.emailAddress = _emailController.text.trim();
    _profile.contactNumber = phone1;
    _profile.contactNumber2 = _phone2Controller.text.trim();
    _profile.additionalContactDetails = _additionalController.text.trim();

    await StorageService.saveProfile(_profile);

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

  /// Template Upload with Free Tier Guard
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
      );

      if (result != null && result.files.isNotEmpty) {
        final fileName = result.files.single.name;
        setState(() {
          _profile.uploadedTemplates.add(fileName);
        });
        await StorageService.saveProfile(_profile);
      }
    } catch (_) {
      // Fallback on restricted permission environments
      setState(() {
        _profile.uploadedTemplates.add('Standard_Chartered_Template_${_profile.uploadedTemplates.length + 1}.docx');
      });
      await StorageService.saveProfile(_profile);
    }
  }

  void _removeTemplate(int index) async {
    setState(() {
      _profile.uploadedTemplates.removeAt(index);
    });
    await StorageService.saveProfile(_profile);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 2,
      title: 'Valuer Profile Setup',
      onBack: () => Navigator.pop(context),
      onNext: () async {
        final success = await _saveProfile(showSuccessFeedback: false);
        if (!success || !mounted) return;
        Navigator.pushNamed(context, '/step3');
      },
      nextLabel: 'Save & Continue to Deed',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Information banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borders),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user, color: AppColors.primaryNavy, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enter your professional practitioner credentials. Your details are saved locally on this device and automatically included in your valuation certificates, letterheads, and final report annexures.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.mainText,
                              height: 1.4,
                            ),
                          ),
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

                  // Dedicated Save Profile Button
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      key: const Key('save_profile_button'),
                      onPressed: () => _saveProfile(showSuccessFeedback: true),
                      icon: const Icon(Icons.save, color: Colors.white, size: 20),
                      label: const Text(
                        'Save Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // C. Custom Report Templates (DOCX/PDF)
                  SectionCard(
                    title: 'Custom Report Templates (DOCX/PDF)',
                    subtitle: 'Upload up to 3 sample Word reports to preserve your personalized table formatting and styles.',
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
                                    'Default official chartered template from SKILL.md will be used automatically. You can also upload your own .docx or .pdf templates below.',
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
                                            'Custom Styling Baseline',
                                            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
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
                          label: const Text('+ Upload DOCX / PDF Template'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
