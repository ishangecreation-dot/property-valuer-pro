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

  // Limits
  static const int freeTierTemplateLimit = 3;

  // Valuation Defaults
  static const double defaultDepreciationPercent = 10.0;
  static const double defaultFsvPercent = 75.0;
  static const double perchInSqFt = 272.25;
}
