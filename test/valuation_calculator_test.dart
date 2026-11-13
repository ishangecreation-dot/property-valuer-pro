import 'package:flutter_test/flutter_test.dart';
import 'package:property_valuer_pro/models/valuation_data.dart';
import 'package:property_valuer_pro/models/survey_plan_data.dart';

void main() {
  group('Valuation Calculations Methodology Tests (SKILL.md)', () {
    test('1. Land Extent conversion from Acres, Roods, Perches', () {
      final lot1 = PlanLot(lotNumber: '1', acres: 0, roods: 0, perches: 18.5);
      expect(lot1.totalPerches, 18.5);

      final lot2 = PlanLot(lotNumber: '2', acres: 1, roods: 2, perches: 10.0);
      // 1 Acre = 160 Perches, 2 Roods = 80 Perches, 10 Perches = 250 Perches
      expect(lot2.totalPerches, 250.0);
    });

    test('2. Land Value calculation', () {
      final valData = ValuationData(adoptedLandRatePerPerch: 350000.0);
      final landVal = valData.computeLandValue(18.5);
      expect(landVal, 18.5 * 350000.0);
      expect(landVal, 6475000.0);
    });

    test('3. Building GRC, Depreciation & Depreciated Value', () {
      final valData = ValuationData(
        buildingReplacementCostPerSqFt: 7000.0,
        depreciationPercentage: 10.0,
      );

      const double totalFloorArea = 1500.0;
      final grc = valData.computeGrc(totalFloorArea, true);
      expect(grc, 1500.0 * 7000.0); // 10,500,000.0

      final dep = valData.computeDepreciation(grc);
      expect(dep, 1050000.0); // 10% of 10.5M

      final depBldgVal = valData.computeDepreciatedBuildingValue(grc, dep);
      expect(depBldgVal, 9450000.0); // 10.5M - 1.05M
    });

    test('4. Bare land has zero building value', () {
      final valData = ValuationData();
      final grc = valData.computeGrc(1500.0, false);
      expect(grc, 0.0);

      final totalMarketVal = valData.computeTotalMarketValue(
        extentPerches: 20.0,
        totalFloorAreaSqFt: 1500.0,
        hasBuilding: false,
      );
      expect(totalMarketVal, 20.0 * valData.adoptedLandRatePerPerch);
    });

    test('5. Market Value (SAY) and FSV (75%)', () {
      final valData = ValuationData(fsvPercentage: 75.0);
      const double rawMarketVal = 15925000.0;
      final sayVal = valData.computeSayValue(rawMarketVal);
      expect(sayVal, 15900000.0); // Rounded to standard bank 100k increments

      final fsv = valData.computeFsv(sayVal);
      expect(fsv, 15900000.0 * 0.75); // 11,925,000.0
    });
  });
}
