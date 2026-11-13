import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/ad_service.dart';

class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!AdService.isAdsEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: const Border(top: BorderSide(color: AppColors.borders)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryText.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SPONSORED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${AdService.activeAdProvider} Banner Placeholder',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
