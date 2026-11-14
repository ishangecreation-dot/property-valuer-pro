class AppConstants {
  static const String appName = 'Property Valuer Pro';
  static const String appVersion = '1.0.0 (Build 1)';

  // 10 Connected Workflow Steps
  static const List<String> workflowSteps = [
    'Dashboard',
    'Valuer Profile',
    'Title Deed',
    'Survey Plan',
    'Purpose & Statutory',
    'Location & Access',
    'A3 Mini-CAD',
    'Building Details',
    'Valuation Math',
    'Review & Generate',
  ];

  // Project Statuses
  static const String statusDraft = 'Draft';
  static const String statusInProgress = 'In Progress';
  static const String statusReadyToGenerate = 'Ready to Generate';
  static const String statusCompleted = 'Completed';

  // Free Tier & Quota Limits
  static const int freeTierTemplateLimit = 3;
  static const int monthlyFreeReportLimit = 10;
  static const int defaultMonthlyFreeReportLimit = 10;

  // Ad Providers & Meta Audience Network Constants
  static const String adProviderMeta = 'Meta Audience Network';
  static const String adProviderAdMob = 'Google AdMob';
  static const String defaultMetaBannerPlacementId = 'IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID';
  static const String defaultMetaInterstitialPlacementId = 'VID_HD_9_16_39S_APP_INSTALL#YOUR_PLACEMENT_ID';
  static const String defaultAdMobBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String defaultAdMobInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // Valuation Defaults
  static const double defaultDepreciationPercent = 10.0;
  static const double defaultFsvPercent = 75.0;
  static const double perchInSqFt = 272.25;
}
