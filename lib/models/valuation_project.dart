import 'deed_data.dart';
import 'survey_plan_data.dart';
import 'inspection_data.dart';
import 'location_data.dart';
import 'building_sketch.dart';
import 'building_details.dart';
import 'valuation_data.dart';

class ValuationProject {
  String id;
  String projectName;
  String clientOrBank;
  String status; // 'Draft', 'In Progress', 'Ready to Generate', 'Completed'
  DateTime createdAt;
  DateTime updatedAt;
  int targetPageCount; // 3, 4, 5

  DeedData deedData;
  SurveyPlanData surveyPlanData;
  InspectionData inspectionData;
  LocationData locationData;
  BuildingSketch buildingSketch;
  BuildingDetails buildingDetails;
  ValuationData valuationData;
  String generatedDocxPath;

  ValuationProject({
    required this.id,
    this.projectName = 'Untitled Valuation',
    this.clientOrBank = "People's Bank",
    this.status = 'Draft',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.targetPageCount = 4,
    DeedData? deedData,
    SurveyPlanData? surveyPlanData,
    InspectionData? inspectionData,
    LocationData? locationData,
    BuildingSketch? buildingSketch,
    BuildingDetails? buildingDetails,
    ValuationData? valuationData,
    this.generatedDocxPath = '',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        deedData = deedData ?? DeedData(),
        surveyPlanData = surveyPlanData ?? SurveyPlanData(),
        inspectionData = inspectionData ?? InspectionData(),
        locationData = locationData ?? LocationData(),
        buildingSketch = buildingSketch ?? BuildingSketch(),
        buildingDetails = buildingDetails ?? BuildingDetails(),
        valuationData = valuationData ?? ValuationData();

  // Completion calculation
  double get progressPercentage {
    int completed = 0;
    if (deedData.deedNumber.isNotEmpty) completed++;
    if (surveyPlanData.planNumber.isNotEmpty) completed++;
    if (inspectionData.dateOfInspection.isNotEmpty) completed++;
    if (locationData.nearestTown.isNotEmpty) completed++;
    if (buildingSketch.elements.isNotEmpty || buildingSketch.isBareLand) completed++;
    if (buildingDetails.buildings.isNotEmpty) completed++;
    if (valuationData.adoptedLandRatePerPerch > 0) completed++;
    if (generatedDocxPath.isNotEmpty) completed++;

    return completed / 8.0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectName': projectName,
    'clientOrBank': clientOrBank,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'targetPageCount': targetPageCount,
    'deedData': deedData.toJson(),
    'surveyPlanData': surveyPlanData.toJson(),
    'inspectionData': inspectionData.toJson(),
    'locationData': locationData.toJson(),
    'buildingSketch': buildingSketch.toJson(),
    'buildingDetails': buildingDetails.toJson(),
    'valuationData': valuationData.toJson(),
    'generatedDocxPath': generatedDocxPath,
  };

  factory ValuationProject.fromJson(Map<String, dynamic> json) => ValuationProject(
    id: json['id'] ?? '',
    projectName: json['projectName'] ?? 'Untitled Valuation',
    clientOrBank: json['clientOrBank'] ?? "People's Bank",
    status: json['status'] ?? 'Draft',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    targetPageCount: json['targetPageCount'] ?? 4,
    deedData: json['deedData'] != null ? DeedData.fromJson(json['deedData']) : DeedData(),
    surveyPlanData: json['surveyPlanData'] != null ? SurveyPlanData.fromJson(json['surveyPlanData']) : SurveyPlanData(),
    inspectionData: json['inspectionData'] != null ? InspectionData.fromJson(json['inspectionData']) : InspectionData(),
    locationData: json['locationData'] != null ? LocationData.fromJson(json['locationData']) : LocationData(),
    buildingSketch: json['buildingSketch'] != null ? BuildingSketch.fromJson(json['buildingSketch']) : BuildingSketch(),
    buildingDetails: json['buildingDetails'] != null ? BuildingDetails.fromJson(json['buildingDetails']) : BuildingDetails(),
    valuationData: json['valuationData'] != null ? ValuationData.fromJson(json['valuationData']) : ValuationData(),
    generatedDocxPath: json['generatedDocxPath'] ?? '',
  );
}
