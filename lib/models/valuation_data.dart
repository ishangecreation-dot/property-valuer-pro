class ComparableProperty {
  String location;
  String saleDate;
  double landExtentPerches;
  double salePrice;
  double ratePerPerch;
  String sourceEvidence;
  String adjustmentRemarks;

  ComparableProperty({
    this.location = '',
    this.saleDate = '',
    this.landExtentPerches = 0.0,
    this.salePrice = 0.0,
    this.ratePerPerch = 0.0,
    this.sourceEvidence = 'Local Registry & Broker Transactions',
    this.adjustmentRemarks = 'Similar access and shape',
  });

  Map<String, dynamic> toJson() => {
    'location': location,
    'saleDate': saleDate,
    'landExtentPerches': landExtentPerches,
    'salePrice': salePrice,
    'ratePerPerch': ratePerPerch,
    'sourceEvidence': sourceEvidence,
    'adjustmentRemarks': adjustmentRemarks,
  };

  factory ComparableProperty.fromJson(Map<String, dynamic> json) => ComparableProperty(
    location: json['location'] ?? '',
    saleDate: json['saleDate'] ?? '',
    landExtentPerches: (json['landExtentPerches'] as num?)?.toDouble() ?? 0.0,
    salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
    ratePerPerch: (json['ratePerPerch'] as num?)?.toDouble() ?? 0.0,
    sourceEvidence: json['sourceEvidence'] ?? '',
    adjustmentRemarks: json['adjustmentRemarks'] ?? '',
  );
}

class ValuationData {
  String methodology; // 'Market Comparison Method', 'Depreciated Replacement Cost Method', 'Combined Approach'
  double adoptedLandRatePerPerch;
  double buildingReplacementCostPerSqFt;
  double depreciationPercentage; // 5.0 to 15.0
  double fsvPercentage; // 70.0 to 75.0
  double customSayValue; // If manually overridden by valuer, else 0 (auto-rounded)

  // SWOC & Risk
  String strengths;
  String weaknesses;
  String opportunities;
  String constraints;
  String collateralRating; // 'Class A / Prime Collateral', 'Class B / Moderate', 'Class C / Cautious'

  List<ComparableProperty> marketEvidence;

  ValuationData({
    this.methodology = 'Combined Approach',
    this.adoptedLandRatePerPerch = 350000.0,
    this.buildingReplacementCostPerSqFt = 7000.0,
    this.depreciationPercentage = 10.0,
    this.fsvPercentage = 75.0,
    this.customSayValue = 0.0,
    this.strengths = 'Well-demarcated boundaries, motorable carpet road frontage, high residential demand.',
    this.weaknesses = 'Interior access road narrows to 15ft.',
    this.opportunities = 'Proximity to expressway interchange and central commercial node.',
    this.constraints = 'Subject to standard street line and building limit statutory setbacks.',
    this.collateralRating = 'Class A / Prime Collateral',
    List<ComparableProperty>? marketEvidence,
  }) : marketEvidence = marketEvidence ?? [
    ComparableProperty(
      location: 'Within 200m along Main Road',
      saleDate: 'Recent 6 Months',
      landExtentPerches: 15.0,
      salePrice: 5550000.0,
      ratePerPerch: 370000.0,
      sourceEvidence: 'Direct Inquiry / Local Brokers',
      adjustmentRemarks: 'Slightly higher elevation, adopted conservative rate.',
    )
  ];

  // Mathematical Calculations according to SKILL.md
  double computeLandValue(double extentPerches) {
    return extentPerches * adoptedLandRatePerPerch;
  }

  double computeGrc(double totalFloorAreaSqFt, bool hasBuilding) {
    if (!hasBuilding) return 0.0;
    return totalFloorAreaSqFt * buildingReplacementCostPerSqFt;
  }

  double computeDepreciation(double grc) {
    return grc * (depreciationPercentage / 100.0);
  }

  double computeDepreciatedBuildingValue(double grc, double depreciation) {
    return grc - depreciation;
  }

  double computeTotalMarketValue({
    required double extentPerches,
    required double totalFloorAreaSqFt,
    required bool hasBuilding,
  }) {
    final landVal = computeLandValue(extentPerches);
    if (!hasBuilding) return landVal;
    final grc = computeGrc(totalFloorAreaSqFt, hasBuilding);
    final dep = computeDepreciation(grc);
    final bldgVal = computeDepreciatedBuildingValue(grc, dep);
    return landVal + bldgVal;
  }

  double computeSayValue(double computedMarketValue) {
    if (customSayValue > 0) return customSayValue;
    // Standard banking rounding: nearest 50,000 or 100,000
    if (computedMarketValue >= 10000000) {
      return (computedMarketValue / 100000).round() * 100000.0;
    } else {
      return (computedMarketValue / 50000).round() * 50000.0;
    }
  }

  double computeFsv(double sayValue) {
    return sayValue * (fsvPercentage / 100.0);
  }

  Map<String, dynamic> toJson() => {
    'methodology': methodology,
    'adoptedLandRatePerPerch': adoptedLandRatePerPerch,
    'buildingReplacementCostPerSqFt': buildingReplacementCostPerSqFt,
    'depreciationPercentage': depreciationPercentage,
    'fsvPercentage': fsvPercentage,
    'customSayValue': customSayValue,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'opportunities': opportunities,
    'constraints': constraints,
    'collateralRating': collateralRating,
    'marketEvidence': marketEvidence.map((e) => e.toJson()).toList(),
  };

  factory ValuationData.fromJson(Map<String, dynamic> json) => ValuationData(
    methodology: json['methodology'] ?? 'Combined Approach',
    adoptedLandRatePerPerch: (json['adoptedLandRatePerPerch'] as num?)?.toDouble() ?? 350000.0,
    buildingReplacementCostPerSqFt: (json['buildingReplacementCostPerSqFt'] as num?)?.toDouble() ?? 7000.0,
    depreciationPercentage: (json['depreciationPercentage'] as num?)?.toDouble() ?? 10.0,
    fsvPercentage: (json['fsvPercentage'] as num?)?.toDouble() ?? 75.0,
    customSayValue: (json['customSayValue'] as num?)?.toDouble() ?? 0.0,
    strengths: json['strengths'] ?? '',
    weaknesses: json['weaknesses'] ?? '',
    opportunities: json['opportunities'] ?? '',
    constraints: json['constraints'] ?? '',
    collateralRating: json['collateralRating'] ?? 'Class A / Prime Collateral',
    marketEvidence: (json['marketEvidence'] as List?)
        ?.map((e) => ComparableProperty.fromJson(e))
        .toList(),
  );
}
