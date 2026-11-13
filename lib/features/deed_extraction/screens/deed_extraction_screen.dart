import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/deed_data.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';

class DeedExtractionScreen extends StatefulWidget {
  const DeedExtractionScreen({Key? key}) : super(key: key);

  @override
  State<DeedExtractionScreen> createState() => _DeedExtractionScreenState();
}

class _DeedExtractionScreenState extends State<DeedExtractionScreen> {
  ValuationProject? _project;
  DeedData _deed = DeedData();
  bool _isLoading = true;
  bool _isExtracting = false;
  String _extractionStatus = '';

  final _deedNoCtrl = TextEditingController();
  final _execDateCtrl = TextEditingController();
  final _notaryNameCtrl = TextEditingController();
  final _notaryStationCtrl = TextEditingController();
  final _landRegistryCtrl = TextEditingController();
  final _regDateCtrl = TextEditingController();
  final _dayBookCtrl = TextEditingController();
  final _folioCtrl = TextEditingController();
  final _vendeeNameCtrl = TextEditingController();
  final _vendeeNicCtrl = TextEditingController();
  final _vendeeAddressCtrl = TextEditingController();
  final _vendorNameCtrl = TextEditingController();
  final _vendorNicCtrl = TextEditingController();
  final _vendorAddressCtrl = TextEditingController();
  final _considerationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await StorageService.loadActiveProject();
    if (proj != null) {
      _project = proj;
      _deed = proj.deedData;
      _updateControllers();
    }
    setState(() => _isLoading = false);
  }

  void _updateControllers() {
    _deedNoCtrl.text = _deed.deedNumber;
    _execDateCtrl.text = _deed.executionDate;
    _notaryNameCtrl.text = _deed.notaryPublicName;
    _notaryStationCtrl.text = _deed.notaryPublicStation;
    _landRegistryCtrl.text = _deed.landRegistry;
    _regDateCtrl.text = _deed.registrationDate;
    _dayBookCtrl.text = _deed.dayBookNumber;
    _folioCtrl.text = _deed.registerFolioNumber;
    _vendeeNameCtrl.text = _deed.vendeeName;
    _vendeeNicCtrl.text = _deed.vendeeNic;
    _vendeeAddressCtrl.text = _deed.vendeeAddress;
    _vendorNameCtrl.text = _deed.vendorName;
    _vendorNicCtrl.text = _deed.vendorNic;
    _vendorAddressCtrl.text = _deed.vendorAddress;
    _considerationCtrl.text = _deed.purchaseConsideration > 0
        ? _deed.purchaseConsideration.toStringAsFixed(0)
        : '';
  }

  void _syncControllersToData() {
    _deed.deedNumber = _deedNoCtrl.text.trim();
    _deed.executionDate = _execDateCtrl.text.trim();
    _deed.notaryPublicName = _notaryNameCtrl.text.trim();
    _deed.notaryPublicStation = _notaryStationCtrl.text.trim();
    _deed.landRegistry = _landRegistryCtrl.text.trim();
    _deed.registrationDate = _regDateCtrl.text.trim();
    _deed.dayBookNumber = _dayBookCtrl.text.trim();
    _deed.registerFolioNumber = _folioCtrl.text.trim();
    _deed.vendeeName = _vendeeNameCtrl.text.trim();
    _deed.vendeeNic = _vendeeNicCtrl.text.trim();
    _deed.vendeeAddress = _vendeeAddressCtrl.text.trim();
    _deed.vendorName = _vendorNameCtrl.text.trim();
    _deed.vendorNic = _vendorNicCtrl.text.trim();
    _deed.vendorAddress = _vendorAddressCtrl.text.trim();
    _deed.purchaseConsideration = double.tryParse(_considerationCtrl.text.trim()) ?? 0.0;

    if (_project != null) {
      _project!.deedData = _deed;
      StorageService.saveActiveProject(_project!);
    }
  }

  void _pickPdf() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (res != null && res.files.single.path != null) {
        setState(() => _deed.documentFilePaths.add(res.files.single.path!));
      }
    } catch (_) {
      setState(() => _deed.documentFilePaths.add('Title_Deed_Scan_Doc.pdf'));
    }
  }

  void _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear, // Back camera default
        maxWidth: 1600,
        imageQuality: 85, // Automatic memory compression
      );
      if (picked != null) {
        setState(() => _deed.documentFilePaths.add(picked.path));
      }
    } catch (_) {
      setState(() => _deed.documentFilePaths.add('Deed_Page_${_deed.documentFilePaths.length + 1}.jpg'));
    }
  }

  void _triggerAiExtraction() async {
    setState(() {
      _isExtracting = true;
      _extractionStatus = 'Starting AI document extraction...';
    });

    try {
      final extracted = await AiService.extractDeed(
        filePaths: _deed.documentFilePaths,
        onProgress: (status) => setState(() => _extractionStatus = status),
      );

      setState(() {
        _deed = extracted;
        _updateControllers();
        _isExtracting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Deed Details Extracted. Please review and verify.')),
      );
    } catch (e) {
      setState(() => _isExtracting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.warning),
              SizedBox(width: 8),
              Text('AI Extraction Notice', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text('$e\n\nYou can proceed by entering the deed particulars manually below.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 720;

    return ResponsiveWorkflowScaffold(
      currentStep: 3,
      title: 'Title Deed Extraction',
      onBack: () {
        _syncControllersToData();
        Navigator.pop(context);
      },
      onNext: () {
        _syncControllersToData();
        Navigator.pushNamed(context, '/step4');
      },
      nextLabel: 'Save & Continue to Plan',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isTablet
              ? Row(
                  children: [
                    // Tablet Left Split: Original Document Preview
                    Expanded(
                      flex: 4,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borders),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              color: AppColors.surfaceContainerLow,
                              child: const Row(
                                children: [
                                  Icon(Icons.visibility, size: 18, color: AppColors.primaryNavy),
                                  SizedBox(width: 8),
                                  Text('Original Deed Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                            Expanded(child: _buildDocumentPreviewPane()),
                          ],
                        ),
                      ),
                    ),
                    // Tablet Right Split: Form Fields
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildFormFields(),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDocumentUploadCard(),
                      const SizedBox(height: 16),
                      _buildFormFields(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDocumentUploadCard() {
    return SectionCard(
      title: 'Title Deed Document',
      subtitle: 'Upload Deed PDF, deed scan photos, or capture pages using device back camera.',
      isMandatory: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Images'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.professionalBlue),
                ),
              ),
            ],
          ),
          if (_deed.documentFilePaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text('${_deed.documentFilePaths.length} pages/files ready'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _deed.documentFilePaths.clear()),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          // AI Extract Button
          ElevatedButton.icon(
            onPressed: _isExtracting ? null : _triggerAiExtraction,
            icon: _isExtracting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_isExtracting ? _extractionStatus : 'SUBMIT / EXTRACT WITH AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreviewPane() {
    if (_deed.documentFilePaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.secondaryText.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Upload deed to view document preview alongside extracted fields.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _deed.documentFilePaths.length,
      itemBuilder: (context, idx) => Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.description, color: AppColors.primaryNavy),
            const SizedBox(width: 8),
            Expanded(child: Text('Page ${idx + 1}: ${_deed.documentFilePaths[idx]}', style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Legal Instrument Particulars',
          subtitle: 'Verify deed registration, notary, and Land Registry references.',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Deed Number',
                      hint: 'e.g. 4821',
                      controller: _deedNoCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Execution Date',
                      hint: 'YYYY-MM-DD',
                      controller: _execDateCtrl,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Notary Public Name',
                      hint: 'e.g. K. M. Senanayake',
                      controller: _notaryNameCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Notary Station',
                      hint: 'e.g. Kandy',
                      controller: _notaryStationCtrl,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Land Registry',
                      hint: 'e.g. Kandy Land Registry',
                      controller: _landRegistryCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Registration Date',
                      hint: 'YYYY-MM-DD',
                      controller: _regDateCtrl,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Day Book / Reg Number',
                      hint: 'e.g. D/2019/8491',
                      controller: _dayBookCtrl,
                      isUncertain: _deed.uncertainFields['dayBookNumber'] ?? false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LabeledTextField(
                      label: 'Register Folio Number',
                      hint: 'e.g. F 184/92',
                      controller: _folioCtrl,
                    ),
                  ),
                ],
              ),
              LabeledTextField(
                label: 'Purchase Consideration Stated in Deed (LKR)',
                hint: 'e.g. 4500000',
                controller: _considerationCtrl,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Ownership & Devolution Parties',
          subtitle: 'Current Vendee (Buyer) and Vendor (Previous Owner) details.',
          child: Column(
            children: [
              LabeledTextField(
                label: 'Vendee / Current Owner Full Name',
                hint: 'e.g. P. G. Sunil Jayawardena',
                controller: _vendeeNameCtrl,
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Owner NIC Number',
                      hint: 'e.g. 741920831V',
                      controller: _vendeeNicCtrl,
                    ),
                  ),
                ],
              ),
              LabeledTextField(
                label: 'Owner Residential Address',
                hint: 'e.g. No. 45, Temple Road, Pilimathalawa',
                controller: _vendeeAddressCtrl,
              ),
              const Divider(color: AppColors.borders),
              LabeledTextField(
                label: 'Vendor / Previous Owner Full Name',
                hint: 'e.g. M. B. Wimalasiri Bandara',
                controller: _vendorNameCtrl,
              ),
              Row(
                children: [
                  Expanded(
                    child: LabeledTextField(
                      label: 'Vendor NIC Number',
                      hint: 'e.g. 621048392V',
                      controller: _vendorNicCtrl,
                    ),
                  ),
                ],
              ),
              LabeledTextField(
                label: 'Vendor Address',
                hint: 'e.g. Kotakumbura Watte, Handessa',
                controller: _vendorAddressCtrl,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
