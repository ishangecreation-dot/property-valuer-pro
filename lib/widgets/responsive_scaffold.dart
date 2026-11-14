import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/workflow_header.dart';
import '../widgets/tablet_navigation_rail.dart';
import '../widgets/ad_banner_placeholder.dart';
import '../features/settings/screens/admin_settings_modal.dart';

class ResponsiveWorkflowScaffold extends StatelessWidget {
  final int currentStep; // 1 to 10
  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isNextEnabled;
  final bool showBottomNav;
  final bool showAdBanner;

  const ResponsiveWorkflowScaffold({
    Key? key,
    required this.currentStep,
    required this.title,
    required this.body,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Next Step',
    this.isNextEnabled = true,
    this.showBottomNav = true,
    this.showAdBanner = false,
  }) : super(key: key);

  void _navigateToStep(BuildContext context, int step) {
    if (step == currentStep) return;
    Navigator.pushNamed(context, '/step$step');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Admin Settings',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AdminSettingsModal(),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Tablet Persistent Left Navigation Rail
          if (isTablet)
            TabletNavigationRail(
              currentStep: currentStep,
              onStepSelected: (step) => _navigateToStep(context, step),
            ),

          // Main Workflow Content Area
          Expanded(
            child: Column(
              children: [
                // Mobile Top Workflow Progress Header
                if (!isTablet && currentStep > 1)
                  WorkflowHeader(
                    currentStep: currentStep,
                    onStepTapped: (step) => _navigateToStep(context, step),
                  ),

                // Screen Content
                Expanded(child: body),

                // Non-intrusive bottom banner advertisement placeholder
                if (showAdBanner) const AdBannerPlaceholder(),

                // Bottom Navigation Bar (Back & Next CTA)
                if (showBottomNav)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.borders)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0D16324F),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (onBack != null) ...[
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                onPressed: onBack,
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (onNext != null)
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isNextEnabled ? onNext : null,
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: Text(nextLabel),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryActionTeal,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
