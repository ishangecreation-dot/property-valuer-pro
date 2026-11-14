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
                if (!isTablet && currentStep > 1)\n                  WorkflowHeader(\n                    currentStep: currentStep,\n                    onStepTapped: (step) => _navigateToStep(context, step),\n                  ),\n\n                // Screen Content\n                Expanded(child: body),\n\n                // Non-intrusive bottom banner advertisement placeholder\n                if (showAdBanner) const AdBannerPlaceholder(),\n\n                // Bottom Navigation Bar (Back & Next CTA)\n                if (showBottomNav)\n                  Container(\n                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),\n                    decoration: const BoxDecoration(\n                      color: Colors.white,\n                      border: Border(top: BorderSide(color: AppColors.borders)),\n                      boxShadow: [\n                        BoxShadow(\n                          color: Color(0x0D16324F),\n                          blurRadius: 10,\n                          offset: Offset(0, -2),\n                        ),\n                      ],\n                    ),\n                    child: SafeArea(\n                      child: Row(\n                        children: [\n                          if (onBack != null) ...[\n                            Expanded(\n                              flex: 1,\n                              child: OutlinedButton.icon(\n                                onPressed: onBack,\n                                icon: const Icon(Icons.arrow_back, size: 18),\n                                label: const Text('Back'),\n                              ),\n                            ),\n                            const SizedBox(width: 12),\n                          ],\n                          if (onNext != null)\n                            Expanded(\n                              flex: 2,\n                              child: ElevatedButton.icon(\n                                onPressed: isNextEnabled ? onNext : null,\n                                icon: const Icon(Icons.arrow_forward, size: 18),\n                                label: Text(nextLabel),\n                                style: ElevatedButton.styleFrom(\n                                  backgroundColor: AppColors.primaryActionTeal,\n                                ),\n                              ),\n                            ),\n                        ],\n                      ),\n                    ),\n                  ),\n              ],\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}\n