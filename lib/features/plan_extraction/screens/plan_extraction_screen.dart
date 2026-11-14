import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/survey_plan_data.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';

class PlanExtractionScreen extends StatefulWidget {
  const PlanExtractionScreen({Key? key}) : super(key: key);

  @override
  State<PlanExtractionScreen> createState() => _PlanExtractionScreenState();
}

class _PlanExtractionScreenState extends State<PlanExtractionScreen> {
  ValuationProject? _project;
  SurveyPlanData _plan = SurveyPlanData();
  bool _isLoading = true;
  bool _isExtracting = false;
  String _extractionStatus = '';

  final _planNoCtrl = TextEditingController();
  final _surveyDateCtrl = TextEditingController();
  final _certDateCtrl = TextEditingController();
  final _surveyorNameCtrl = TextEditingController();
  final _surveyorRegCtrl = TextEditingController();
  final _landNameCtrl = TextEditingController();
  final _priorPlanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await StorageService.loadActiveProject();
    if (proj != null) {
      _project = proj;
      _plan = proj.surveyPlanData;
      _updateControllers();
    }
    setState(() => _isLoading = false);
  }

  void _updateControllers() {
    _planNoCtrl.text = _plan.planNumber;
    _surveyDateCtrl.text = _plan.surveyDate;
    _certDateCtrl.text = _plan.certificationDate;
    _surveyorNameCtrl.text = _plan.surveyorName;
    _surveyorRegCtrl.text = _plan.surveyorRegistrationNumber;
    _landNameCtrl.text = _plan.landName;
    _priorPlanCtrl.text = _plan.priorPlanReference;
  }

  void _syncControllersToData() {
    _plan.planNumber = _planNoCtrl.text.trim();
    _plan.surveyDate = _surveyDateCtrl.text.trim();
    _plan.certificationDate = _certDateCtrl.text.trim();
    _plan.surveyorName = _surveyorNameCtrl.text.trim();
    _plan.surveyorRegistrationNumber = _surveyorRegCtrl.text.trim();
    _plan.landName = _landNameCtrl.text.trim();
    _plan.priorPlanReference = _priorPlanCtrl.text.trim();

    if (_project != null) {
      _project!.surveyPlanData = _plan;
      StorageService.saveActiveProject(_project!);
    }
  }

  void _pickPdf() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (res != null && res.files.single.path != null) {
        setState(() => _plan.documentFilePaths.add(res.files.single.path!));
      }
    } catch (_) {
      setState(() => _plan.documentFilePaths.add('Cadastral_Plan_Scan.pdf'));
    }
  }

  void _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _plan.documentFilePaths.add(picked.path));
      }
    } catch (_) {
      setState(() => _plan.documentFilePaths.add('Plan_Sheet_${_plan.documentFilePaths.length + 1}.jpg'));
    }
  }

  void _triggerAiExtraction() async {
    setState(() {
      _isExtracting = true;
      _extractionStatus = 'Analyzing survey plan & extracting lots...';
    });

    final extracted = await AiService.extractSurveyPlan(
      filePaths: _plan.documentFilePaths,
      onProgress: (status) => setState(() => _extractionStatus = status),
    );

    setState(() {
      _plan = extracted;
      _updateControllers();
      _isExtracting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Survey Plan & Lots extracted successfully.')),
    );
  }

  void _addNewLot() {
    setState(() {
      _plan.lots.add(PlanLot(lotNumber: '${_plan.lots.length + 1}'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 4,
      title: 'Survey Plan & Lot Selection',
      onBack: () {
        _syncControllersToData();
        Navigator.pop(context);
      },
      onNext: () {
        _syncControllersToData();
        Navigator.pushNamed(context, '/step5');
      },
      nextLabel: 'Save & Continue to Purpose',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Document Upload Card
                  SectionCard(
                    title: 'Survey Plan Document',
                    subtitle: 'Upload Plan PDF, plan images, or photograph with back camera.',
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
                        if (_plan.documentFilePaths.isNotEmpty) ...[
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
                                Text('${_plan.documentFilePaths.length} survey plan files attached'),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() => _plan.documentFilePaths.clear()),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _isExtracting ? null : _triggerAiExtraction,
                          icon: _isExtracting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(_isExtracting ? _extractionStatus : 'SUBMIT / EXTRACT SURVEY PLAN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Plan Cadastral Particulars
                  SectionCard(
                    title: 'Survey Plan Particulars',
                    subtitle: 'Identification reference for cadastral mapping and report certification.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Plan Number',
                                hint: 'e.g. 2418/SP',
                                controller: _planNoCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Survey Date',
                                hint: 'YYYY-MM-DD',
                                controller: _surveyDateCtrl,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Licensed Surveyor Name',
                                hint: 'e.g. Gamini Ratnayake',
                                controller: _surveyorNameCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Surveyor Reg. Number',
                                hint: 'e.g. LS/1842',
                                controller: _surveyorRegCtrl,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Name of the Land',
                                hint: 'e.g. Kotakumbura (Part)',
                                controller: _landNameCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Prior Plan Reference',
                                hint: 'e.g. Plan No. 1102',
                                controller: _priorPlanCtrl,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Multiple-Lot Functionality & Boundary Schedules
                  SectionCard(
                    title: 'Exact Lot Selection & Boundaries',
                    subtitle: 'Which lot or lots do you want to include in this valuation report?',
                    trailing: TextButton.icon(
                      onPressed: _addNewLot,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Lot'),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Combined Extent Callout Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COMBINED EVALUATED EXTENT',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Only selected lots are computed in valuation',
                                    style: TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                              Text(
                                '${_plan.selectedTotalPerches.toStringAsFixed(2)} Perches',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.antiqueGold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Lots List
                        ..._plan.lots.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final lot = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: lot.isSelected ? Colors.white : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: lot.isSelected ? AppColors.primaryActionTeal : AppColors.borders,
                                width: lot.isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: lot.isSelected,
                                      activeColor: AppColors.primaryActionTeal,
                                      onChanged: (val) {
                                        setState(() => lot.isSelected = val ?? true);
                                      },
                                    ),
                                    Text(
                                      'Lot No. ${lot.lotNumber}',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: lot.isSelected ? AppColors.primaryNavy : AppColors.secondaryText,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${lot.totalPerches.toStringAsFixed(2)} Perches',
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: AppColors.borders),
                                // Extent Breakdown in Acres, Roods, Perches
                                Row(
                                  children: [
                                    Expanded(
                                      child: LabeledTextField(
                                        label: 'Acres (A)',
                                        initialValue: lot.acres.toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => setState(() => lot.acres = int.tryParse(v) ?? 0),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LabeledTextField(
                                        label: 'Roods (R)',
                                        initialValue: lot.roods.toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => setState(() => lot.roods = int.tryParse(v) ?? 0),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LabeledTextField(
                                        label: 'Perches (P)',
                                        initialValue: lot.perches.toString(),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => setState(() => lot.perches = double.tryParse(v) ?? 0.0),
                                      ),
                                    ),
                                  ],
                                ),
                                // Boundaries Schedule
                                const Text(
                                  'Schedule of Boundaries',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(height: 6),
                                LabeledTextField(
                                  label: 'North Boundary',
                                  initialValue: lot.northBoundary,
                                  hint: 'e.g. Lot 2 of the same land',
                                  onChanged: (v) => lot.northBoundary = v,
                                ),
                                LabeledTextField(
                                  label: 'East Boundary',
                                  initialValue: lot.eastBoundary,
                                  hint: 'e.g. Access Road (15ft Wide)',
                                  onChanged: (v) => lot.eastBoundary = v,
                                ),
                                LabeledTextField(
                                  label: 'South Boundary',
                                  initialValue: lot.southBoundary,
                                  hint: 'e.g. Land of H. M. Dingiri Banda',
                                  onChanged: (v) => lot.southBoundary = v,
                                ),
                                LabeledTextField(
                                  label: 'West Boundary',
                                  initialValue: lot.westBoundary,
                                  hint: 'e.g. Ela (Drainage Stream)',
                                  onChanged: (v) => lot.westBoundary = v,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
