import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/valuation_data.dart';
import '../../../core/storage/storage_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';
import '../../../widgets/live_calculation_card.dart';

class ValuationScreen extends StatefulWidget {
  const ValuationScreen({Key? key}) : super(key: key);

  @override
  State<ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends State<ValuationScreen> {
  ValuationProject? _project;
  ValuationData _valData = ValuationData();
  bool _isLoading = true;

  final _landRateCtrl = TextEditingController();
  final _bldgCostCtrl = TextEditingController();
  final _depPctCtrl = TextEditingController();
  final _fsvPctCtrl = TextEditingController();

  final List<String> _methodologyOptions = [
    'Combined Approach',
    'Market Comparison Method',
    'Depreciated Replacement Cost Method',
    'Contractor\'s Test / Investment Method',
  ];

  final List<String> _ratingOptions = [
    'Class A / Prime Collateral',
    'Class B / Moderate Risk',
    'Class C / Cautious Exposure',
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
      _valData = proj.valuationData;
      _landRateCtrl.text = _valData.adoptedLandRatePerPerch.toStringAsFixed(0);
      _bldgCostCtrl.text = _valData.buildingReplacementCostPerSqFt.toStringAsFixed(0);
      _depPctCtrl.text = _valData.depreciationPercentage.toStringAsFixed(0);
      _fsvPctCtrl.text = _valData.fsvPercentage.toStringAsFixed(0);
    }
    setState(() => _isLoading = false);
  }

  void _syncData() {
    _valData.adoptedLandRatePerPerch = double.tryParse(_landRateCtrl.text.trim()) ?? 350000.0;
    _valData.buildingReplacementCostPerSqFt = double.tryParse(_bldgCostCtrl.text.trim()) ?? 7000.0;
    _valData.depreciationPercentage = double.tryParse(_depPctCtrl.text.trim()) ?? 10.0;
    _valData.fsvPercentage = double.tryParse(_fsvPctCtrl.text.trim()) ?? 75.0;

    if (_project != null) {
      _project!.valuationData = _valData;
      StorageService.saveActiveProject(_project!);
    }
  }

  void _addComparable() {
    setState(() {
      _valData.marketEvidence.add(
        ComparableProperty(
          location: 'Adjacent Property',
          saleDate: 'Recent',
          landExtentPerches: 12.0,
          ratePerPerch: _valData.adoptedLandRatePerPerch,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 9,
      title: 'Valuation Math & Market Evidence',
      onBack: () {
        _syncData();
        Navigator.pop(context);
      },
      onNext: () {
        _syncData();
        Navigator.pushNamed(context, '/step10');
      },
      nextLabel: 'Continue to Review & Generate',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Valuation Calculation Card
                  if (_project != null) LiveCalculationCard(project: _project!),

                  const SizedBox(height: 16),

                  // Valuation Benchmark Inputs Card
                  SectionCard(
                    title: 'Pricing Benchmarks & Rate Inputs',
                    subtitle: 'All mathematical calculations update in real time based on these professional parameters.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Valuation Methodology Adopted', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _methodologyOptions.map((m) {
                            final isSel = _valData.methodology == m;
                            return ChoiceChip(
                              label: Text(m),
                              selected: isSel,
                              selectedColor: AppColors.primaryNavy,
                              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.mainText, fontSize: 12),
                              onSelected: (val) {
                                if (val) setState(() => _valData.methodology = m);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Adopted Land Rate / Perch (LKR)',
                                hint: 'e.g. 350000',
                                controller: _landRateCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  _valData.adoptedLandRatePerPerch = double.tryParse(v) ?? 350000.0;
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Replacement Cost / sq.ft. (LKR)',
                                hint: 'e.g. 7000',
                                controller: _bldgCostCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  _valData.buildingReplacementCostPerSqFt = double.tryParse(v) ?? 7000.0;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: LabeledTextField(
                                label: 'Depreciation Percentage (%)',
                                hint: 'e.g. 10 (Default: 5-15%)',
                                controller: _depPctCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  _valData.depreciationPercentage = double.tryParse(v) ?? 10.0;
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LabeledTextField(
                                label: 'Forced Sale Value (%)',
                                hint: 'e.g. 75 (Default: 70-75%)',
                                controller: _fsvPctCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  _valData.fsvPercentage = double.tryParse(v) ?? 75.0;
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Market Evidence Comparables Card
                  SectionCard(
                    title: 'Market Evidence & Comparables',
                    subtitle: 'Comparable land and property transactions supporting the adopted perch rate.',
                    trailing: TextButton.icon(
                      onPressed: _addComparable,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Comparable'),
                    ),
                    child: Column(
                      children: _valData.marketEvidence.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final comp = entry.value;

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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Comparable #${idx + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNavy),
                                  ),
                                  if (_valData.marketEvidence.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                      onPressed: () => setState(() => _valData.marketEvidence.removeAt(idx)),
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: LabeledTextField(
                                      label: 'Location / Distance',
                                      initialValue: comp.location,
                                      hint: 'e.g. 200m along Main Road',
                                      onChanged: (v) => comp.location = v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LabeledTextField(
                                      label: 'Rate / Perch (LKR)',
                                      initialValue: comp.ratePerPerch > 0 ? comp.ratePerPerch.toStringAsFixed(0) : '',
                                      hint: 'e.g. 370000',
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => comp.ratePerPerch = double.tryParse(v) ?? 0.0,
                                    ),
                                  ),
                                ],
                              ),
                              LabeledTextField(
                                label: 'Adjustment & Evidence Source',
                                initialValue: comp.adjustmentRemarks,
                                hint: 'e.g. Similar access and terrain',
                                onChanged: (v) => comp.adjustmentRemarks = v,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // SWOC Analysis & Collateral Risk Profile Card
                  SectionCard(
                    title: 'SWOC Analysis & Risk Rating',
                    subtitle: 'Evaluates strengths, weaknesses, opportunities, and constraints for mortgage underwriting.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledTextField(
                          label: 'Strengths (S)',
                          initialValue: _valData.strengths,
                          hint: 'e.g. Direct motorable access, well-demarcated boundaries',
                          maxLines: 2,
                          onChanged: (v) => _valData.strengths = v,
                        ),
                        LabeledTextField(
                          label: 'Weaknesses (W)',
                          initialValue: _valData.weaknesses,
                          hint: 'e.g. Interior lane narrows to 15ft width',
                          maxLines: 2,
                          onChanged: (v) => _valData.weaknesses = v,
                        ),
                        LabeledTextField(
                          label: 'Opportunities (O)',
                          initialValue: _valData.opportunities,
                          hint: 'e.g. Rapid capital appreciation due to commercial expansion',
                          maxLines: 2,
                          onChanged: (v) => _valData.opportunities = v,
                        ),
                        LabeledTextField(
                          label: 'Constraints / Threats (C)',
                          initialValue: _valData.constraints,
                          hint: 'e.g. Adherence to standard local authority setback requirements',
                          maxLines: 2,
                          onChanged: (v) => _valData.constraints = v,
                        ),
                        const SizedBox(height: 8),
                        const Text('Final Collateral Underwriting Rating', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _ratingOptions.map((r) {
                            final isSel = _valData.collateralRating == r;
                            return ChoiceChip(
                              label: Text(r),
                              selected: isSel,
                              selectedColor: AppColors.primaryNavy,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.mainText,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _valData.collateralRating = r);
                              },
                            );
                          }).toList(),
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
