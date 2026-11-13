import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class TabletNavigationRail extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepSelected;

  const TabletNavigationRail({
    Key? key,
    required this.currentStep,
    required this.onStepSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        border: Border(
          right: BorderSide(color: AppColors.borders, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF243B55), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryActionTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.apartment, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valuer Pro',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Chartered Suite',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.antiqueGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 10 Workflow Steps List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: AppConstants.workflowSteps.length,
              itemBuilder: (context, index) {
                final stepNum = index + 1;
                final isSelected = currentStep == stepNum;
                final isCompleted = currentStep > stepNum;
                final title = AppConstants.workflowSteps[index];

                return InkWell(
                  onTap: () => onStepSelected(stepNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryActionTeal.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: AppColors.primaryActionTeal, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primaryActionTeal
                                : (isCompleted
                                    ? AppColors.success.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.1)),
                          ),
                          alignment: Alignment.center,
                          child: isCompleted
                              ? const Icon(Icons.check, size: 14, color: AppColors.success)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Version Tag
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'v1.0.0 • Offline Ready',
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}
