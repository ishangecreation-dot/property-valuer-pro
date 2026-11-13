import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class WorkflowHeader extends StatelessWidget {
  final int currentStep; // 1 to 10
  final Function(int)? onStepTapped;

  const WorkflowHeader({
    Key? key,
    required this.currentStep,
    this.onStepTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stepIndex = currentStep.clamp(1, 10);
    final progress = stepIndex / 10.0;
    final stepTitle = AppConstants.workflowSteps[stepIndex - 1];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'STEP $stepIndex OF 10',
                      style: const TextStyle(
                        color: AppColors.antiqueGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stepTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.mainText,
                    ),
                  ),
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primaryActionTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borders,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryActionTeal),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
