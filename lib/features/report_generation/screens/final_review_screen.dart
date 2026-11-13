import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/valuer_profile.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/docx_service.dart';
import '../../../core/services/monthly_usage_service.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/custom_form_fields.dart';
import '../../../widgets/monthly_limit_reached_dialog.dart';

class FinalReviewScreen extends StatefulWidget {
  const FinalReviewScreen({Key? key}) : super(key: key);

  @override
  State<FinalReviewScreen> createState() => _FinalReviewScreenState();
}

class _FinalReviewScreenState extends State<FinalReviewScreen> {
  ValuationProject? _project;
  ValuerProfile? _profile;
  MonthlyUsageState? _usageState;
  bool _isLoading = true;
  bool _isGenerating = false;
  String _generationProgress = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshUsageState();
  }

  Future<void> _loadData() async {
    final proj = await StorageService.loadActiveProject();
    final prof = await StorageService.loadProfile();
    final usage = await MonthlyUsageService.getUsage();
    if (mounted) {
      setState(() {
        _project = proj;
        _profile = prof;
        _usageState = usage;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUsageState() async {
    final usage = await MonthlyUsageService.getUsage();
    if (mounted) {
      setState(() {
        _usageState = usage;
      });
    }
  }

  /// Handles the user tapping "Generate Report"
  void _onGenerateTapped() async {
    // 1. Prevent rapid repeated taps while already processing
    if (_isGenerating || MonthlyUsageService.isProcessing) {
      return;
    }

    if (_project == null || _profile == null) return;

    // 2. Refresh usage state and verify allowance
    final usage = await MonthlyUsageService.getUsage();
    setState(() => _usageState = usage);

    // 3. If limit reached and not paid: show required popup and halt
    if (usage.isLimitReached) {
      _showLimitReachedPopup();
      return;
    }

    // 4. Accept the click as a valid generation action.
    // The 10th click is accepted and allowed to complete, but marks the allowance exhausted.
    final updatedUsage = await MonthlyUsageService.acceptGenerationClick();
    if (updatedUsage == null) {
      // Rapid tap prevented
      return;
    }

    // Update count immediately in UI
    setState(() {
      _usageState = updatedUsage;
    });

    // 5. Interstitial Ad Behavior:
    // Display Meta Audience Network interstitial ad before starting report generation.
    // After user closes the ad, continue generating the report automatically.
    // If ad fails to load, is unavailable, or user is offline, continue report generation without the ad.
    // Never leave the user stuck.
    await AdService.showMetaInterstitialBeforeGeneration(
      context,
      onAdClosed: () {
        // Continue report generation automatically after ad closes (or if ad is skipped/unavailable)
        _startReportGeneration();
      },
    );
  }

  /// Core report generation execution
  void _startReportGeneration() async {
    setState(() {
      _isGenerating = true;
      _generationProgress = 'Validating valuation metrics & tables...';
    });

    try {
      final docxPath = await DocxService.generateValuationDocx(
        project: _project!,
        profile: _profile!,
        onProgress: (status) {
          if (mounted) {
            setState(() => _generationProgress = status);
          }
        },
      );

      _project!.generatedDocxPath = docxPath;
      _project!.status = 'Completed';
      await StorageService.saveActiveProject(_project!);

      // Refresh final usage state
      final latestUsage = await MonthlyUsageService.getUsage();

      if (mounted) {
        setState(() {
          _usageState = latestUsage;
          _isGenerating = false;
        });
        // Unlock processing lock upon completion
        MonthlyUsageService.releaseProcessingLock();
        Navigator.pushNamed(context, '/step10_success');
      }
    } catch (e) {
      MonthlyUsageService.releaseProcessingLock();
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error generating report: $e'),
          ),
        );
      }
    }
  }

  void _showLimitReachedPopup() {
    MonthlyLimitReachedDialog.show(
      context,
      onPaidUnlocked: () {
        _refreshUsageState();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final p = _project!;
    final prof = _profile ?? ValuerProfile();
    final usage = _usageState ?? const MonthlyUsageState(
      monthIdentifier: '',
      usedClicks: 0,
      maxAllowance: 10,
      isPaid: false,
    );

    final bool isLimitReached = usage.isLimitReached;

    return ResponsiveWorkflowScaffold(
      currentStep: 10,
      title: 'Review & Generate Report',
      showBottomNav: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Quota Status Banner
            _buildMonthlyUsageCard(usage),
            const SizedBox(height: 16),

            // Mandatory Page Budget Selection Card
            SectionCard(
              title: 'Mandatory Report Page Budget',
              subtitle: 'How many pages do you want for the final and complete Valuation Report?',
              isMandatory: true,
              child: Column(
                children: [
                  _buildPageOption(
                    pages: 3,
                    title: '3 Pages – Concise Format',
                    description: 'Direct appraisal summary and core calculation tables for swift institutional review.',
                  ),
                  const SizedBox(height: 8),
                  _buildPageOption(
                    pages: 4,
                    title: '4 Pages – Standard Chartered Format (Default)',
                    description: 'Comprehensive 10-point valuation body, legal audit, and SWOC risk underwriting.',
                  ),
                  const SizedBox(height: 8),
                  _buildPageOption(
                    pages: 5,
                    title: '5 Pages – Extended Full Dossier',
                    description: 'Includes Executive Letterhead Cover Page, Valuation Body, and Annexure Photographic Plates.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 8-Step Pre-Generation Checklist Audit
            SectionCard(
              title: 'Pre-Generation Inspection Checklist',
              subtitle: 'Verify extracted parameters before compiling Microsoft Word (.docx) report.',
              child: Column(
                children: [
                  _buildChecklistItem(
                    stepNum: 2,
                    title: '1. Professional Valuer Profile',
                    summary: '${prof.valuerName.isNotEmpty ? prof.valuerName : "Valuer Profile Pending"} (${prof.registrationNumber.isNotEmpty ? prof.registrationNumber : "Reg Pending"})',
                    isCompleted: prof.valuerName.isNotEmpty,
                  ),
                  _buildChecklistItem(
                    stepNum: 3,
                    title: '2. Title Deed & Owner Verification',
                    summary: 'Deed No: ${p.deedData.deedNumber} • Owner: ${p.deedData.vendeeName.isNotEmpty ? p.deedData.vendeeName : "Pending Verification"}',
                    isCompleted: p.deedData.deedNumber.isNotEmpty,
                  ),
                  _buildChecklistItem(
                    stepNum: 4,
                    title: '3. Survey Plan & Cadastral Lots',
                    summary: 'Plan: ${p.surveyPlanData.planNumber} • Total: ${p.surveyPlanData.selectedTotalPerches.toStringAsFixed(2)} Perches',
                    isCompleted: p.surveyPlanData.lots.any((l) => l.isSelected),
                  ),
                  _buildChecklistItem(
                    stepNum: 5,
                    title: '4. Purpose, Inspection & Statutory Details',
                    summary: 'Bank: ${p.clientOrBank} • Assessment No. ${p.inspectionData.assessmentNumber}',
                    isCompleted: true,
                  ),
                  _buildChecklistItem(
                    stepNum: 6,
                    title: '5. Location & Access Route',
                    summary: '${p.locationData.nearestTown.isNotEmpty ? p.locationData.nearestTown : "Locality"} (${p.locationData.accessRoadWidthFt.toStringAsFixed(0)} ft wide road)',
                    isCompleted: true,
                  ),
                  _buildChecklistItem(
                    stepNum: 7,
                    title: '6. Building Sketch (Mini-CAD)',
                    summary: p.buildingSketch.isBareLand
                        ? 'Bare Land Assessment (Building Sketch Skipped)'
                        : '${p.buildingSketch.elements.length} architectural vector elements drafted',
                    isCompleted: true,
                  ),
                  _buildChecklistItem(
                    stepNum: 8,
                    title: '7. Building Specs & Photographs',
                    summary: p.buildingDetails.hasBuilding
                        ? 'Floor Area: ${p.buildingDetails.totalBuiltUpArea.toStringAsFixed(0)} sq.ft. • 4 photo slots ready'
                        : 'Bare Land Only (No Buildings)',
                    isCompleted: true,
                  ),
                  _buildChecklistItem(
                    stepNum: 9,
                    title: '8. Valuation Calculations',
                    summary: 'Rate: LKR ${p.valuationData.adoptedLandRatePerPerch.toStringAsFixed(0)}/P • FSV: ${p.valuationData.fsvPercentage.toStringAsFixed(0)}%',
                    isCompleted: p.valuationData.adoptedLandRatePerPerch > 0,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Generate Button with Limit Reached Disabled State
            _buildGenerateButton(isLimitReached),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyUsageCard(MonthlyUsageState usage) {
    final isLimitReached = usage.isLimitReached;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLimitReached
            ? const Color(0xFFFEF2F2)
            : (usage.isPaid ? const Color(0xFFF0FDF4) : AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLimitReached
              ? AppColors.error.withOpacity(0.4)
              : (usage.isPaid ? AppColors.success.withOpacity(0.4) : AppColors.borders),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLimitReached
                ? Icons.lock_clock
                : (usage.isPaid ? Icons.verified : Icons.analytics_outlined),
            color: isLimitReached
                ? AppColors.error
                : (usage.isPaid ? AppColors.success : AppColors.primaryNavy),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usage.isPaid
                          ? 'ValuerPro Paid Version'
                          : 'Free Reports Used: ${usage.usedClicks} / ${usage.maxAllowance}',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isLimitReached ? AppColors.error : AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      usage.monthIdentifier,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!usage.isPaid) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (usage.usedClicks / usage.maxAllowance).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.black.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLimitReached ? AppColors.error : AppColors.primaryActionTeal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLimitReached
                        ? 'Monthly allowance exhausted. Resets 1st of next month.'
                        : '${usage.remainingClicks} free report generations remaining this month.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLimitReached ? AppColors.error : AppColors.secondaryText,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Unlimited monthly report generation unlocked.',
                    style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(bool isLimitReached) {
    if (isLimitReached) {
      // Disabled state: "Monthly Limit Reached – Upgrade to Paid Version"
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _showLimitReachedPopup,
            icon: const Icon(Icons.lock, size: 20),
            label: const Text(
              'Monthly Limit Reached  Upgrade to Paid Version',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF94A3B8), // Muted disabled slate
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The 10-report free monthly allowance has been reached. Tap above to upgrade to Paid Version.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.error),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: _isGenerating ? null : _onGenerateTapped,
      icon: _isGenerating
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.description, size: 22),
      label: Text(
        _isGenerating ? _generationProgress : 'GENERATE REPORT',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryActionTeal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
    );
  }

  Widget _buildPageOption({
    required int pages,
    required String title,
    required String description,
  }) {
    final isSel = _project!.targetPageCount == pages;

    return InkWell(
      onTap: () {
        setState(() => _project!.targetPageCount = pages);
        StorageService.saveActiveProject(_project!);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primaryNavy.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? AppColors.primaryNavy : AppColors.borders,
            width: isSel ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: pages,
              groupValue: _project!.targetPageCount,
              activeColor: AppColors.primaryNavy,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _project!.targetPageCount = val);
                  StorageService.saveActiveProject(_project!);
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSel ? AppColors.primaryNavy : AppColors.mainText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required int stepNum,
    required String title,
    required String summary,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borders),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? AppColors.success : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(summary, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/step$stepNum'),
            child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
