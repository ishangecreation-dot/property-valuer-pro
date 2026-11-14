import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/services/ad_service.dart';
import '../core/storage/storage_service.dart';

class AdBannerPlaceholder extends StatefulWidget {
  const AdBannerPlaceholder({Key? key}) : super(key: key);

  @override
  State<AdBannerPlaceholder> createState() => _AdBannerPlaceholderState();
}

class _AdBannerPlaceholderState extends State<AdBannerPlaceholder> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  void _checkPremium() async {
    final prem = await StorageService.isPremiumTier();
    if (mounted) setState(() => _isPremium = prem);
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.isAdsEnabled || _isPremium) {
      return const SizedBox.shrink();
    }

    final isMeta = AdService.activeAdProvider == AppConstants.adProviderMeta;

    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isMeta ? const Color(0xFFF0F4F9) : AppColors.surfaceContainerLow,
        border: const Border(top: BorderSide(color: AppColors.borders)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMeta) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF0081FB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.all_inclusive, color: Colors.white, size: 13),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMeta ? const Color(0xFF0081FB).withOpacity(0.12) : AppColors.secondaryText.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SPONSORED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isMeta ? const Color(0xFF0081FB) : AppColors.secondaryText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${AdService.activeAdProvider} Banner',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMeta ? const Color(0xFF1E293B) : AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '• Commercial Bank Housing Loan Partner',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
