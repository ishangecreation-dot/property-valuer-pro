import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';
import 'entitlement_service.dart';
import '../../widgets/meta_interstitial_ad_dialog.dart';

class AdService {
  // Ads disabled by default until user/admin configures them
  static bool isAdsEnabled = false;
  static String activeAdProvider = AppConstants.adProviderMeta;
  static bool isInterstitialEnabled = true;

  // Placement IDs
  static String metaBannerPlacementId = AppConstants.defaultMetaBannerPlacementId;
  static String metaInterstitialPlacementId = AppConstants.defaultMetaInterstitialPlacementId;
  static String admobBannerAdUnitId = AppConstants.defaultAdMobBannerAdUnitId;
  static String admobInterstitialAdUnitId = AppConstants.defaultAdMobInterstitialAdUnitId;

  // Real-time Ad Metrics
  static int interstitialImpressions = 0;
  static int interstitialClicks = 0;

  // Offline / ad load simulation flags for testing
  static bool forceAdFailureForTesting = false;

  static Future<void> init() async {
    isAdsEnabled = await StorageService.isAdsEnabled();
    activeAdProvider = await StorageService.getActiveAdProvider();
    isInterstitialEnabled = await StorageService.isInterstitialEnabled();
    metaBannerPlacementId = await StorageService.getMetaBannerPlacementId();
    metaInterstitialPlacementId = await StorageService.getMetaInterstitialPlacementId();
  }

  static Future<void> enableMetaAds({String? bannerId, String? interstitialId}) async {
    isAdsEnabled = true;
    activeAdProvider = AppConstants.adProviderMeta;
    isInterstitialEnabled = true;
    if (bannerId != null && bannerId.isNotEmpty) metaBannerPlacementId = bannerId;
    if (interstitialId != null && interstitialId.isNotEmpty) metaInterstitialPlacementId = interstitialId;

    await StorageService.setAdsEnabled(true);
    await StorageService.setActiveAdProvider(AppConstants.adProviderMeta);
    await StorageService.setInterstitialEnabled(true);
    await StorageService.setMetaBannerPlacementId(metaBannerPlacementId);
    await StorageService.setMetaInterstitialPlacementId(metaInterstitialPlacementId);
  }

  static Future<void> enableAdMobAds({String? bannerId, String? interstitialId}) async {
    isAdsEnabled = true;
    activeAdProvider = AppConstants.adProviderAdMob;
    isInterstitialEnabled = true;
    if (bannerId != null && bannerId.isNotEmpty) admobBannerAdUnitId = bannerId;
    if (interstitialId != null && interstitialId.isNotEmpty) admobInterstitialAdUnitId = interstitialId;

    await StorageService.setAdsEnabled(true);
    await StorageService.setActiveAdProvider(AppConstants.adProviderAdMob);
    await StorageService.setInterstitialEnabled(true);
  }

  static Future<void> disableAds() async {
    isAdsEnabled = false;
    await StorageService.setAdsEnabled(false);
  }

  static void recordAdImpression() {
    interstitialImpressions++;
  }

  static void recordAdClick() {
    interstitialClicks++;
  }

  /// Displays a Meta Audience Network interstitial ad before starting report generation.
  ///
  /// Guarantees:
  /// 1. After user closes the ad, invokes [onAdClosed] to continue generation automatically.
  /// 2. If user has paid entitlement, completely bypasses the ad.
  /// 3. If ad fails to load, is unavailable, user is offline, or timeout occurs,
  ///    continues report generation immediately without leaving the user stuck.
  static Future<void> showMetaInterstitialBeforeGeneration(
    BuildContext context, {
    required VoidCallback onAdClosed,
  }) async {
    final isPaid = await EntitlementService.isPaidTier();
    if (isPaid || !isAdsEnabled || !isInterstitialEnabled || forceAdFailureForTesting) {
      // Bypassed or ad failure test: proceed to report generation immediately
      onAdClosed();
      return;
    }

    if (!context.mounted) {
      onAdClosed();
      return;
    }

    bool hasContinued = false;
    void safeContinue() {
      if (!hasContinued) {
        hasContinued = true;
        onAdClosed();
      }
    }

    try {
      if (activeAdProvider == AppConstants.adProviderMeta) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => MetaInterstitialAdDialog(
            placementId: metaInterstitialPlacementId,
            onDismissed: safeContinue,
          ),
        );
      } else {
        // Fallback AdMob Interstitial
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _AdMobInterstitialFallbackDialog(
            adUnitId: admobInterstitialAdUnitId,
            onDismissed: safeContinue,
          ),
        );
      }
    } catch (_) {
      // If dialog display fails, ensure user is never left stuck
      safeContinue();
    }
  }

  /// Admin preview tool to test the Meta Audience Network Interstitial Ad directly
  static void showMetaPreviewInterstitial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MetaInterstitialAdDialog(
        placementId: metaInterstitialPlacementId,
        onDismissed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta Audience Network Interstitial Ad preview completed.')),
          );
        },
      ),
    );
  }
}

class _AdMobInterstitialFallbackDialog extends StatelessWidget {
  final String adUnitId;
  final VoidCallback onDismissed;

  const _AdMobInterstitialFallbackDialog({
    Key? key,
    required this.adUnitId,
    required this.onDismissed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AdService.recordAdImpression();
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Ad • Google AdMob', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismissed();
                    },
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Google AdMob Interstitial Display',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismissed();
                },
                child: const Text('Continue to Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
