import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/valuation_project.dart';

class LiveCalculationCard extends StatelessWidget {
  final ValuationProject project;

  const LiveCalculationCard({Key? key, required this.project}) : super(key: key);

  String _formatLkr(double val) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'LKR ${formatter.format(val)}';
  }

  @override
  Widget build(BuildContext context) {
    final perches = project.surveyPlanData.selectedTotalPerches > 0
        ? project.surveyPlanData.selectedTotalPerches
        : 15.0; // Preview default if not yet entered
    final landRate = project.valuationData.adoptedLandRatePerPerch;
    final landVal = project.valuationData.computeLandValue(perches);

    final hasBuilding = project.buildingDetails.hasBuilding;
    final totalArea = project.buildingDetails.totalBuiltUpArea > 0
        ? project.buildingDetails.totalBuiltUpArea
        : (hasBuilding ? 1500.0 : 0.0);

    final grc = project.valuationData.computeGrc(totalArea, hasBuilding);
    final dep = project.valuationData.computeDepreciation(grc);
    final bldgVal = project.valuationData.computeDepreciatedBuildingValue(grc, dep);
    final computedMarketVal = project.valuationData.computeTotalMarketValue(
      extentPerches: perches,
      totalFloorAreaSqFt: totalArea,
      hasBuilding: hasBuilding,
    );
    final sayVal = project.valuationData.computeSayValue(computedMarketVal);
    final fsvVal = project.valuationData.computeFsv(sayVal);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF243B55))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calculate, color: AppColors.antiqueGold, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Live Valuation Summary',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.antiqueGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AUTO-CALCULATED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Math Breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMathRow(
                  'Land Value (${perches.toStringAsFixed(2)} P @ ${_formatLkr(landRate)}/P)',
                  _formatLkr(landVal),
                  Colors.white70,
                ),
                if (hasBuilding) ...[
                  const SizedBox(height: 6),
                  _buildMathRow(
                    'Building GRC (${totalArea.toStringAsFixed(0)} sq.ft.)',
                    _formatLkr(grc),
                    Colors.white70,
                  ),
                  const SizedBox(height: 6),
                  _buildMathRow(
                    'Less Depreciation (${project.valuationData.depreciationPercentage.toStringAsFixed(0)}%)',
                    '- ${_formatLkr(dep)}',
                    const Color(0xFFFC8181),
                  ),
                  const SizedBox(height: 6),
                  _buildMathRow(
                    'Depreciated Building Value',
                    _formatLkr(bldgVal),
                    Colors.white70,
                  ),
                ] else ...[
                  const SizedBox(height: 6),
                  _buildMathRow(
                    'Building Value (Bare Land)',
                    'Nil (Bare Land Only)',
                    Colors.white54,
                  ),
                ],
                const Divider(height: 20, color: Color(0xFF243B55)),
                _buildMathRow(
                  'Total Computed Market Value',
                  _formatLkr(computedMarketVal),
                  Colors.white,
                  isBold: true,
                ),
              ],
            ),
          ),

          // Prominent Badges: Market Value (SAY) & FSV
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F243B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Market Value (SAY)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MARKET VALUE (SAY)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatLkr(sayVal),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.antiqueGold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: const Color(0xFF243B55)),
                const SizedBox(width: 12),
                // Forced Sale Value (FSV)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FSV (${project.valuationData.fsvPercentage.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatLkr(fsvVal),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryActionTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathRow(String label, String value, Color textColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
