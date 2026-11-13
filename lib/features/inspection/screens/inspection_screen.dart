import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/inspection_data.dart';
import '../../../core/storage/storage_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({Key? key}) : super(key: key);

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  ValuationProject? _project;
  InspectionData _inspection = InspectionData();
  bool _isLoading = true;

  final _branchCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _gnCtrl = TextEditingController();
  final _koraleCtrl = TextEditingController();
  final _dsCtrl = TextEditingController();
  final _laCtrl = TextEditingController();
  final _assessmentCtrl = TextEditingController();

  final List<String> _bankSuggestions = [
    "People's Bank",
    "Bank of Ceylon",
    "Commercial Bank",
    "Sampath Bank",
    "Hatton National Bank",
    "State Mortgage & Investment Bank",
    "National Savings Bank",
    "Seylan Bank",
    "DFCC Bank",
    "Nations Trust Bank",
  ];

  final List<String> _purposeOptions = [
    "Mortgage Security",
    "Bank Guarantee",
    "Credit Facility",
    "Balance Sheet / Accounting",
    "Auction Reserve Price",
    "Purchase Decision",
  ];

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await StorageService.loadActiveProject();
    if (proj != null) {
      _project = proj;
      _inspection = proj.inspectionData;
      _branchCtrl.text = _inspection.bankBranch;
      _dateCtrl.text = _inspection.dateOfInspection.isNotEmpty
          ? _inspection.dateOfInspection
          : DateTime.now().toString().split(' ')[0];
      _villageCtrl.text = _inspection.village;
      _gnCtrl.text = _inspection.gnDivision;
      _koraleCtrl.text = _inspection.korale;
      _dsCtrl.text = _inspection.divisionalSecretariat;
      _laCtrl.text = _inspection.localAuthority;
      _assessmentCtrl.text = _inspection.assessmentNumber;
    }
    setState(() => _isLoading = false);
  }

  void _syncData() {
    _inspection.bankBranch = _branchCtrl.text.trim();
    _inspection.dateOfInspection = _dateCtrl.text.trim();
    _inspection.village = _villageCtrl.text.trim();
    _inspection.gnDivision = _gnCtrl.text.trim();
    _inspection.korale = _koraleCtrl.text.trim();
    _inspection.divisionalSecretariat = _dsCtrl.text.trim();
    _inspection.localAuthority = _laCtrl.text.trim();
    _inspection.assessmentNumber = _assessmentCtrl.text.trim();

    if (_project != null) {
      _project!.inspectionData = _inspection;
      _project!.clientOrBank = _inspection.targetInstitution;
      StorageService.saveActiveProject(_project!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 5,
      title: 'Purpose & Statutory Compliance',
      onBack: () {
        _syncData();
        Navigator.pop(context);
      },
      onNext: () {
        _syncData();
        Navigator.pushNamed(context, '/step6');
      },
      nextLabel: 'Save & Continue to Location',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Institution Card
                  SectionCard(
                    title: 'Target Institution & Facility Purpose',
                    subtitle: 'Specify the lending bank and loan facility context.',
                    isMandatory: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Lending Bank / Financial Institution',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _bankSuggestions.map((bank) {
                            final isSel = _inspection.targetInstitution == bank;
                            return ChoiceChip(
                              label: Text(bank),
                              selected: isSel,
                              selectedColor: AppColors.primaryNavy,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.mainText,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _inspection.targetInstitution = bank);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Bank Branch',
                                hint: 'e.g. Pilimathalawa Branch',
                                controller: _branchCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Date of Physical Inspection',
                                hint: 'YYYY-MM-DD',
                                controller: _dateCtrl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Valuation Purpose',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _purposeOptions.map((purp) {
                            final isSel = _inspection.valuationPurpose == purp;
                            return ChoiceChip(
                              label: Text(purp),
                              selected: isSel,
                              selectedColor: AppColors.primaryActionTeal,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.mainText,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _inspection.valuationPurpose = purp);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Administrative Situation Card
                  SectionCard(
                    title: 'Administrative & Statutory Location',
                    subtitle: 'Official divisions according to statutory valuation reporting standards.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Village / Locality',
                                hint: 'e.g. Handessa',
                                controller: _villageCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Grama Niladhari Division',
                                hint: 'e.g. Handessa South',
                                controller: _gnCtrl,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Korale',
                                hint: 'e.g. Medapalatha',
                                controller: _koraleCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Divisional Secretariat (DS)',
                                hint: 'e.g. Udunuwara',
                                controller: _dsCtrl,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Pradeshiya Sabha / MC Limits',
                                hint: 'e.g. Udunuwara Pradeshiya Sabha',
                                controller: _laCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Assessment Number',
                                hint: 'e.g. Assessment No. 84',
                                controller: _assessmentCtrl,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Statutory Compliance Checklist
                  SectionCard(
                    title: 'Statutory Compliance Matrix',
                    subtitle: 'Never assume approvals. Verify street lines, building limits, and NBRO clearance status.',
                    child: Column(
                      children: _inspection.statutoryCompliances.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borders),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  'Applicable',
                                  'Not Applicable',
                                  'Obtained',
                                  'Not Obtained',
                                  'Pending Verification',
                                ].map((status) {
                                  final isSel = item.status == status;
                                  return ChoiceChip(
                                    label: Text(status, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.mainText)),
                                    selected: isSel,
                                    selectedColor: status == 'Obtained'
                                        ? AppColors.success
                                        : (status == 'Pending Verification' ? AppColors.warning : AppColors.primaryNavy),
                                    onSelected: (val) {
                                      if (val) setState(() => item.status = status);
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: item.remarks,
                                decoration: const InputDecoration(
                                  hintText: 'Custom remarks (e.g. Ref No, clearance date)',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (v) => item.remarks = v,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
