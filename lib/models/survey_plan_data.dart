class PlanLot {
  String lotNumber;
  int acres;
  int roods;
  double perches;
  double squareMeters;
  String northBoundary;
  String eastBoundary;
  String southBoundary;
  String westBoundary;
  bool isSelected;

  PlanLot({
    this.lotNumber = '1',
    this.acres = 0,
    this.roods = 0,
    this.perches = 0.0,
    this.squareMeters = 0.0,
    this.northBoundary = '',
    this.eastBoundary = '',
    this.southBoundary = '',
    this.westBoundary = '',
    this.isSelected = true,
  });

  double get totalPerches => (acres * 160.0) + (roods * 40.0) + perches;

  Map<String, dynamic> toJson() => {
    'lotNumber': lotNumber,
    'acres': acres,
    'roods': roods,
    'perches': perches,
    'squareMeters': squareMeters,
    'northBoundary': northBoundary,
    'eastBoundary': eastBoundary,
    'southBoundary': southBoundary,
    'westBoundary': westBoundary,
    'isSelected': isSelected,
  };

  factory PlanLot.fromJson(Map<String, dynamic> json) => PlanLot(
    lotNumber: json['lotNumber'] ?? '1',
    acres: json['acres'] ?? 0,
    roods: json['roods'] ?? 0,
    perches: (json['perches'] as num?)?.toDouble() ?? 0.0,
    squareMeters: (json['squareMeters'] as num?)?.toDouble() ?? 0.0,
    northBoundary: json['northBoundary'] ?? '',
    eastBoundary: json['eastBoundary'] ?? '',
    southBoundary: json['southBoundary'] ?? '',
    westBoundary: json['westBoundary'] ?? '',
    isSelected: json['isSelected'] ?? true,
  );
}

class SurveyPlanData {
  String planNumber;
  String surveyDate;
  String certificationDate;
  String surveyorName;
  String surveyorRegistrationNumber;
  String landName;
  String priorPlanReference;
  List<PlanLot> lots;
  List<String> documentFilePaths;

  SurveyPlanData({
    this.planNumber = '',
    this.surveyDate = '',
    this.certificationDate = '',
    this.surveyorName = '',
    this.surveyorRegistrationNumber = '',
    this.landName = '',
    this.priorPlanReference = '',
    List<PlanLot>? lots,
    List<String>? documentFilePaths,
  })  : lots = lots ?? [PlanLot()],
        documentFilePaths = documentFilePaths ?? [];

  double get selectedTotalPerches {
    return lots.where((l) => l.isSelected).fold(0.0, (sum, l) => sum + l.totalPerches);
  }

  Map<String, dynamic> toJson() => {
    'planNumber': planNumber,
    'surveyDate': surveyDate,
    'certificationDate': certificationDate,
    'surveyorName': surveyorName,
    'surveyorRegistrationNumber': surveyorRegistrationNumber,
    'landName': landName,
    'priorPlanReference': priorPlanReference,
    'lots': lots.map((l) => l.toJson()).toList(),
    'documentFilePaths': documentFilePaths,
  };

  factory SurveyPlanData.fromJson(Map<String, dynamic> json) => SurveyPlanData(
    planNumber: json['planNumber'] ?? '',
    surveyDate: json['surveyDate'] ?? '',
    certificationDate: json['certificationDate'] ?? '',
    surveyorName: json['surveyorName'] ?? '',
    surveyorRegistrationNumber: json['surveyorRegistrationNumber'] ?? '',
    landName: json['landName'] ?? '',
    priorPlanReference: json['priorPlanReference'] ?? '',
    lots: (json['lots'] as List?)?.map((l) => PlanLot.fromJson(l)).toList() ?? [PlanLot()],
    documentFilePaths: List<String>.from(json['documentFilePaths'] ?? []),
  );
}
