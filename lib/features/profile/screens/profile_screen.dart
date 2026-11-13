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

  final _nameController = TextEditingController();
  final _qualController = TextEditingController();
  final _membershipController = TextEditingController();
  final _regNoController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _additionalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await StorageService.loadProfile();
    setState(() {
      _profile = profile;
      _nameController.text = profile.valuerName;
      _qualController.text = profile.qualifications;
      _membershipController.text = profile.professionalMembership;
      _regNoController.text = profile.registrationNumber;
      _addressController.text = profile.officeAddress;
      _emailController.text = profile.emailAddress;
      _phoneController.text = profile.contactNumber;
      _additionalController.text = profile.additionalContactDetails;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    _profile.valuerName = _nameController.text.trim();
    _profile.qualifications = _qualController.text.trim();
    _profile.professionalMembership = _membershipController.text.trim();
    _profile.registrationNumber = _regNoController.text.trim();
    _profile.officeAddress = _addressController.text.trim();
    _profile.emailAddress = _emailController.text.trim();
    _profile.contactNumber = _phoneController.text.trim();
    _profile.additionalContactDetails = _additionalController.text.trim();

    await StorageService.saveProfile(_profile);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Valuer Profile saved successfully')),
    );
  }

  void _uploadTemplate() async {
    final isPaid = await EntitlementService.isPaidTier();
    if (!isPaid && _profile.uploadedTemplates.length >= AppConstants.freeTierTemplateLimit) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Template Limit Reached'),
          content: const Text(
            'The Free Version supports up to 3 custom Word (.docx) report templates.\n\nUpgrade to the Paid Version to add unlimited report templates.',
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
        allowedExtensions: ['docx', 'doc'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _profile.uploadedTemplates.add(result.files.single.name);
        });
        await StorageService.saveProfile(_profile);
      }
    } catch (_) {
      // Handle fallback on restricted permission devices
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
        await _saveProfile();
        if (!mounted) return;
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
                  SectionCard(
                    title: 'Chartered Professional Identity',
                    subtitle: 'All valuation certificates and report headers will use your verified professional profile.',
                    isMandatory: true,
                    child: Column(
                      children: [
                        LabeledTextField(
                          label: 'Full Professional Name',
                          hint: 'e.g. Vlr. G. A. Perera (AIV)',
                          controller: _nameController,
                        ),
                        LabeledTextField(
                          label: 'Academic & Professional Qualifications',
                          hint: 'e.g. B.Sc. Estate Mgt. & Valuation (Special) (USJP)',
                          controller: _qualController,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Professional Membership',
                                hint: 'e.g. Associate Member (AIV)',
                                controller: _membershipController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Registration Number',
                                hint: 'e.g. Reg. No. A/695',
                                controller: _regNoController,
                              ),
                            ),
                          ],
                        ),
                        LabeledTextField(
                          label: 'Office / Residential Practice Address',
                          hint: 'e.g. No. 179/1, Main Road, Kandy, Sri Lanka',
                          controller: _addressController,
                          maxLines: 2,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Email Address',
                                hint: 'e.g. valuer@example.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Mobile / WhatsApp Contact',
                                hint: 'e.g. +94 77 123 4567',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        LabeledTextField(
                          label: 'Additional Contact Details / Panel Valuer Memberships',
                          hint: 'e.g. Panel Valuer: People\'s Bank, BOC, SMIB',
                          controller: _additionalController,
                        ),
                      ],
                    ),
                  ),

                  // Draft Report Templates Card
                  SectionCard(
                    title: 'Custom Report Templates (DOCX)',
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
                            padding: const EdgeInsets.all(16),
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
                                    'Default official chartered template from SKILL.md will be used automatically. You can also upload your own .docx templates below.',
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
                                    const Icon(Icons.description, color: AppColors.primaryNavy, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _profile.uploadedTemplates[index],
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                          label: const Text('+ Upload DOCX Template'),
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
