import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/valuation_project.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/services/monthly_usage_service.dart';
import '../../../widgets/responsive_scaffold.dart';
import '../../../widgets/monthly_limit_reached_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ValuationProject> _projects = [];
  ValuationProject? _activeProject;
  MonthlyUsageState? _usageState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projects = await StorageService.loadProjects();
    final active = await StorageService.loadActiveProject();
    final usage = await MonthlyUsageService.getUsage();
    if (mounted) {
      setState(() {
        _projects = projects;
        _activeProject = active ?? (projects.isNotEmpty ? projects.first : null);
        _usageState = usage;
        _isLoading = false;
      });
    }
  }

  void _createNewValuation() async {
    final newProj = ValuationProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectName: 'Valuation Dossier #${_projects.length + 1}',
    );
    await StorageService.saveActiveProject(newProj);
    if (!mounted) return;
    Navigator.pushNamed(context, '/step2'); // Navigate to Professional Profile
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusCompleted:
        return AppColors.success;
      case AppConstants.statusReadyToGenerate:
        return AppColors.primaryActionTeal;
      case AppConstants.statusInProgress:
        return AppColors.warning;
      default:
        return AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 1,
      title: 'Property Valuer Pro',
      showBottomNav: false,
      showAdBanner: true, // Non-intrusive banner on Dashboard as specified
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome & Branding Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryNavy, Color(0xFF284B70)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Professional Real Estate Appraisal',
                                    style: TextStyle(
                                      color: AppColors.antiqueGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Welcome, Valuer',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.verified_user, color: AppColors.antiqueGold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Prepare chartered, institutional valuation reports with AI-assisted title deeds extraction, A3 sketching, and editable Word DOCX exports.',
                            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          // Large Teal Action Button
                          ElevatedButton.icon(
                            onPressed: _createNewValuation,
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text('+ Create New Valuation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryActionTeal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Monthly Free Report Quota Status Card
                    if (_usageState != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _usageState!.isLimitReached
                              ? const Color(0xFFFEF2F2)
                              : (_usageState!.isPaid ? const Color(0xFFF0FDF4) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _usageState!.isLimitReached
                                ? AppColors.error.withOpacity(0.4)
                                : (_usageState!.isPaid ? AppColors.success.withOpacity(0.4) : AppColors.borders),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _usageState!.isLimitReached
                                  ? Icons.lock_clock
                                  : (_usageState!.isPaid ? Icons.workspace_premium : Icons.pie_chart_outline),
                              color: _usageState!.isLimitReached
                                  ? AppColors.error
                                  : (_usageState!.isPaid ? AppColors.success : AppColors.primaryNavy),
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
                                        _usageState!.isPaid
                                            ? 'ValuerPro Paid Version'
                                            : 'Free Reports Used: ${_usageState!.usedClicks} / ${_usageState!.maxAllowance}',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _usageState!.isLimitReached ? AppColors.error : AppColors.primaryNavy,
                                        ),
                                      ),
                                      Text(
                                        _usageState!.monthIdentifier,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.secondaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (!_usageState!.isPaid) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: (_usageState!.usedClicks / _usageState!.maxAllowance).clamp(0.0, 1.0),
                                        minHeight: 5,
                                        backgroundColor: Colors.black.withOpacity(0.06),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _usageState!.isLimitReached ? AppColors.error : AppColors.primaryActionTeal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _usageState!.isLimitReached
                                          ? 'Monthly limit reached (10/10). Tap to upgrade.'
                                          : '${_usageState!.remainingClicks} free report generations remaining this month.',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _usageState!.isLimitReached ? AppColors.error : AppColors.secondaryText,
                                      ),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'Unlimited monthly reports enabled',
                                      style: TextStyle(fontSize: 11, color: AppColors.success),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_usageState!.isLimitReached)
                              TextButton(
                                onPressed: () {
                                  MonthlyLimitReachedDialog.show(
                                    context,
                                    onPaidUnlocked: _loadData,
                                  );
                                },
                                child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Continue Incomplete Valuation Card
                    if (_activeProject != null) ...[
                      const Text(
                        'Continue Valuation',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _activeProject!.projectName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.mainText,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(_activeProject!.status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _activeProject!.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _getStatusColor(_activeProject!.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Target Bank: ${_activeProject!.clientOrBank} • Last updated: ${_activeProject!.updatedAt.day}/${_activeProject!.updatedAt.month}/${_activeProject!.updatedAt.year}',
                                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/step2');
                                      },
                                      child: const Text('Resume Guided Workflow'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Saved Projects Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Projects',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          '${_projects.length} Total',
                          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_projects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.folder_open, size: 48, color: AppColors.secondaryText.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text(
                              'No valuation projects yet.\nTap "+ Create New Valuation" to get started.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final p = _projects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.description, color: AppColors.primaryNavy, size: 22),
                              ),
                              title: Text(
                                p.projectName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${p.clientOrBank} • Target: ${p.targetPageCount} Pages',
                                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(p.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(p.status),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                await StorageService.saveActiveProject(p);
                                if (!mounted) return;
                                Navigator.pushNamed(context, '/step2');
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
