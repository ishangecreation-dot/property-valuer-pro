class AdService {
  // Ads disabled by default until user/admin configures them
  static bool isAdsEnabled = false;
  static String activeAdProvider = 'Google AdMob'; // 'Google AdMob', 'Meta Audience Network'
  static String bannerAdUnitId = '';

  static void enableTestAds() {
    isAdsEnabled = true;
    bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Google AdMob Test Banner
  }

  static void disableAds() {
    isAdsEnabled = false;
  }
}
