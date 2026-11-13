import 'package:flutter/material.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/deed_extraction/screens/deed_extraction_screen.dart';
import '../features/plan_extraction/screens/plan_extraction_screen.dart';
import '../features/inspection/screens/inspection_screen.dart';
import '../features/location/screens/location_screen.dart';
import '../features/sketching/screens/a3_sketching_screen.dart';
import '../features/building_details/screens/building_details_screen.dart';
import '../features/valuation/screens/valuation_screen.dart';
import '../features/report_generation/screens/final_review_screen.dart';
import '../features/report_generation/screens/generation_success_screen.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String step1Dashboard = '/step1';
  static const String step2Profile = '/step2';
  static const String step3Deed = '/step3';
  static const String step4Plan = '/step4';
  static const String step5Purpose = '/step5';
  static const String step6Location = '/step6';
  static const String step7Sketch = '/step7';
  static const String step8Building = '/step8';
  static const String step9Valuation = '/step9';
  static const String step10Review = '/step10';
  static const String step10Success = '/step10_success';

  static Map<String, WidgetBuilder> get routes => {
    dashboard: (context) => const DashboardScreen(),
    step1Dashboard: (context) => const DashboardScreen(),
    step2Profile: (context) => const ProfileScreen(),
    step3Deed: (context) => const DeedExtractionScreen(),
    step4Plan: (context) => const PlanExtractionScreen(),
    step5Purpose: (context) => const InspectionScreen(),
    step6Location: (context) => const LocationScreen(),
    step7Sketch: (context) => const A3SketchingScreen(),
    step8Building: (context) => const BuildingDetailsScreen(),
    step9Valuation: (context) => const ValuationScreen(),
    step10Review: (context) => const FinalReviewScreen(),
    step10Success: (context) => const GenerationSuccessScreen(),
  };
}
