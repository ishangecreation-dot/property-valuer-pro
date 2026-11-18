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
  /// When true, Screens 3 to 10 are frozen (locked) until unfreeze.
  /// Only Screen 0 (Dashboard), Screen 1 (Valuer Profile), and Screen 2 (Title Deed) remain active.
  static const bool areScreens3To10Frozen = true;

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
    step4Plan: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 3, stepName: 'Survey Plan Details & Lot Selection')
        : const PlanExtractionScreen(),
    step5Purpose: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 4, stepName: 'Purpose, Inspection & Statutory')
        : const InspectionScreen(),
    step6Location: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 5, stepName: 'Location & Google Maps Access')
        : const LocationScreen(),
    step7Sketch: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 6, stepName: 'A3 Building Sketch (Mini-CAD)')
        : const A3SketchingScreen(),
    step8Building: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 7, stepName: 'Building Details & Photo Register')
        : const BuildingDetailsScreen(),
    step9Valuation: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 8, stepName: 'Valuation Math & Computations')
        : const ValuationScreen(),
    step10Review: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 9, stepName: 'Final Review & DOCX Generation')
        : const FinalReviewScreen(),
    step10Success: (context) => areScreens3To10Frozen
        ? const FrozenStepScreen(stepNumber: 10, stepName: 'Report Generation Success')
        : const GenerationSuccessScreen(),
  };
}

/// Fallback screen displayed while Screens 3 to 10 are frozen.
class FrozenStepScreen extends StatelessWidget {
  final int stepNumber;
  final String stepName;

  const FrozenStepScreen({
    Key? key,
    required this.stepNumber,
    required this.stepName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step $stepNumber: $stepName'),
        backgroundColor: const Color(0xFF00173A),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2878B5).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ac_unit, color: Color(0xFF2878B5), size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Step $stepNumber is Frozen',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00173A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Screens 3 to 10 are currently frozen for focused verification of Screens 0 to 2.\nThis step will be unlocked when unfreezing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00173A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.pushReplacementNamed(context, '/step3'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Return to Title Deed (Screen 2)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                icon: const Icon(Icons.dashboard, size: 18),
                label: const Text('Return to Dashboard (Screen 0)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
