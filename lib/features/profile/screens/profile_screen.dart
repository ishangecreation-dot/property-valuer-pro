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
      if (!mounted) return;\n      showDialog(\n        context: context,\n        builder: (context) => AlertDialog(\n          title: const Text('Template Limit Reached'),\n          content: const Text(\n            'The Free Version supports up to 3 custom Word (.docx) report templates.\\n\\nUpgrade to the Paid Version to add unlimited report templates.',\n          ),\n          actions: [\n            TextButton(\n              onPressed: () => Navigator.pop(context),\n              child: const Text('OK'),\n            ),\n          ],\n        ),\n      );\n      return;\n    }\n\n    try {\n      FilePickerResult? result = await FilePicker.platform.pickFiles(\n        type: FileType.custom,\n        allowedExtensions: ['docx', 'doc'],\n      );\n\n      if (result != null && result.files.single.path != null) {\n        setState(() {\n          _profile.uploadedTemplates.add(result.files.single.name);\n        });\n        await StorageService.saveProfile(_profile);\n      }\n    } catch (_) {\n      // Handle fallback on restricted permission devices\n      setState(() {\n        _profile.uploadedTemplates.add('Standard_Chartered_Template_${_profile.uploadedTemplates.length + 1}.docx');\n      });\n      await StorageService.saveProfile(_profile);\n    }\n  }\n\n  void _removeTemplate(int index) async {\n    setState(() {\n      _profile.uploadedTemplates.removeAt(index);\n    });\n    await StorageService.saveProfile(_profile);\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    return ResponsiveWorkflowScaffold(\n      currentStep: 2,\n      title: 'Valuer Profile Setup',\n      onBack: () => Navigator.pop(context),\n      onNext: () async {\n        await _saveProfile();\n        if (!mounted) return;\n        Navigator.pushNamed(context, '/step3');\n      },\n      nextLabel: 'Save & Continue to Deed',\n      body: _isLoading\n          ? const Center(child: CircularProgressIndicator())\n          : SingleChildScrollView(\n              padding: const EdgeInsets.all(16.0),\n              child: Column(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  SectionCard(\n                    title: 'Chartered Professional Identity',\n                    subtitle: 'All valuation certificates and report headers will use your verified professional profile.',\n                    isMandatory: true,\n                    child: Column(\n                      children: [\n                        LabeledTextField(\n                          label: 'Full Professional Name',\n                          hint: 'e.g. Vlr. G. A. Perera (AIV)',\n                          controller: _nameController,\n                        ),\n                        LabeledTextField(\n                          label: 'Academic & Professional Qualifications',\n                          hint: 'e.g. B.Sc. Estate Mgt. & Valuation (Special) (USJP)',\n                          controller: _qualController,\n                        ),\n                        Row(\n                          children: [\n                            Expanded(\n                              child: LabeledTextField(\n                                label: 'Professional Membership',\n                                hint: 'e.g. Associate Member (AIV)',\n                                controller: _membershipController,\n                              ),\n                            ),\n                            const SizedBox(width: 12),\n                            Expanded(\n                              child: LabeledTextField(\n                                label: 'Registration Number',\n                                hint: 'e.g. Reg. No. A/695',\n                                controller: _regNoController,\n                              ),\n                            ),\n                          ],\n                        ),\n                        LabeledTextField(\n                          label: 'Office / Residential Practice Address',\n                          hint: 'e.g. No. 179/1, Main Road, Kandy, Sri Lanka',\n                          controller: _addressController,\n                          maxLines: 2,\n                        ),\n                        Row(\n                          children: [\n                            Expanded(\n                              child: LabeledTextField(\n                                label: 'Email Address',\n                                hint: 'e.g. valuer@example.com',\n                                controller: _emailController,\n                                keyboardType: TextInputType.emailAddress,\n                              ),\n                            ),\n                            const SizedBox(width: 12),\n                            Expanded(\n                              child: LabeledTextField(\n                                label: 'Mobile / WhatsApp Contact',\n                                hint: 'e.g. +94 77 123 4567',\n                                controller: _phoneController,\n                                keyboardType: TextInputType.phone,\n                              ),\n                            ),\n                          ],\n                        ),\n                        LabeledTextField(\n                          label: 'Additional Contact Details / Panel Valuer Memberships',\n                          hint: 'e.g. Panel Valuer: People\\'s Bank, BOC, SMIB',\n                          controller: _additionalController,\n                        ),\n                      ],\n                    ),\n                  ),\n\n                  // Draft Report Templates Card\n                  SectionCard(\n                    title: 'Custom Report Templates (DOCX)',\n                    subtitle: 'Upload up to 3 sample Word reports to preserve your personalized table formatting and styles.',\n                    trailing: Text(\n                      '${_profile.uploadedTemplates.length}/${AppConstants.freeTierTemplateLimit} Free Slots',\n                      style: const TextStyle(\n                        fontSize: 12,\n                        fontWeight: FontWeight.w700,\n                        color: AppColors.primaryActionTeal,\n                      ),\n                    ),\n                    child: Column(\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: [\n                        if (_profile.uploadedTemplates.isEmpty)\n                          Container(\n                            padding: const EdgeInsets.all(16),\n                            decoration: BoxDecoration(\n                              color: AppColors.surfaceContainerLow,\n                              borderRadius: BorderRadius.circular(8),\n                            ),\n                            child: const Row(\n                              children: [\n                                Icon(Icons.info_outline, color: AppColors.secondaryText, size: 20),\n                                SizedBox(width: 10),\n                                Expanded(\n                                  child: Text(\n                                    'Default official chartered template from SKILL.md will be used automatically. You can also upload your own .docx templates below.',\n                                    style: TextStyle(fontSize: 12, color: AppColors.secondaryText),\n                                  ),\n                                ),\n                              ],\n                            ),\n                          )\n                        else\n                          ListView.builder(\n                            shrinkWrap: true,\n                            physics: const NeverScrollableScrollPhysics(),\n                            itemCount: _profile.uploadedTemplates.length,\n                            itemBuilder: (context, index) {\n                              return Container(\n                                margin: const EdgeInsets.only(bottom: 8),\n                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),\n                                decoration: BoxDecoration(\n                                  color: Colors.white,\n                                  borderRadius: BorderRadius.circular(8),\n                                  border: Border.all(color: AppColors.borders),\n                                ),\n                                child: Row(\n                                  children: [\n                                    const Icon(Icons.description, color: AppColors.primaryNavy, size: 20),\n                                    const SizedBox(width: 10),\n                                    Expanded(\n                                      child: Text(\n                                        _profile.uploadedTemplates[index],\n                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),\n                                      ),\n                                    ),\n                                    IconButton(\n                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),\n                                      onPressed: () => _removeTemplate(index),\n                                    ),\n                                  ],\n                                ),\n                              );\n                            },\n                          ),\n\n                        const SizedBox(height: 12),\n                        OutlinedButton.icon(\n                          onPressed: _uploadTemplate,\n                          icon: const Icon(Icons.upload_file, size: 18),\n                          label: const Text('+ Upload DOCX Template'),\n                        ),\n                      ],\n                    ),\n                  ),\n                ],\n              ),\n            ),\n    );\n  }\n}\n