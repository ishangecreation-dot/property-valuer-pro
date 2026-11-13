class RoomCounter {
  String name;
  int count;

  RoomCounter({required this.name, this.count = 0});

  Map<String, dynamic> toJson() => {'name': name, 'count': count};
  factory RoomCounter.fromJson(Map<String, dynamic> json) => RoomCounter(
    name: json['name'] ?? '',
    count: json['count'] ?? 0,
  );
}

class PropertyPhoto {
  String slotName; // Front Elevation, Side / Rear View, Interior, Boundary / Entrance
  String filePath;
  String description;

  PropertyPhoto({
    required this.slotName,
    this.filePath = '',
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
    'slotName': slotName,
    'filePath': filePath,
    'description': description,
  };

  factory PropertyPhoto.fromJson(Map<String, dynamic> json) => PropertyPhoto(
    slotName: json['slotName'] ?? '',
    filePath: json['filePath'] ?? '',
    description: json['description'] ?? '',
  );
}

class BuildingSpecification {
  String buildingName;
  String roofType; // Concrete Flat Roof, Asbestos, Tile, Zinc Aluminium, Iron Trusses, Timber Rafters, Other
  String wallType; // Cement Block, Brick Masonry, Plastered, Painted, Colour Washed, Other
  String floorType; // Cement Rendered, Ceramic Tiled, Cut Cement, Other
  String doorsWindows; // Timber Panel, Aluminium Frame, Glass, Window Grills, Other
  String bathFittings; // Commode, Wash Basin, Accessories, Complete, Incomplete
  int ageYears;
  String structuralCondition; // Good, Fair, Poor, Under Construction
  String occupancy; // Owner Occupied, Tenanted, Vacant
  double groundFloorAreaSqFt;
  double upperFloorAreaSqFt;
  List<RoomCounter> roomCounters;

  BuildingSpecification({
    this.buildingName = 'Main Residential Building',
    this.roofType = 'Concrete Flat Roof / Asbestos',
    this.wallType = 'Brick Masonry, Plastered & Painted',
    this.floorType = 'Ceramic Tiled',
    this.doorsWindows = 'Timber Panel & Window Grills',
    this.bathFittings = 'Commode, Wash Basin, Complete',
    this.ageYears = 5,
    this.structuralCondition = 'Good',
    this.occupancy = 'Owner Occupied',
    this.groundFloorAreaSqFt = 1500.0,
    this.upperFloorAreaSqFt = 0.0,
    List<RoomCounter>? roomCounters,
  }) : roomCounters = roomCounters ?? [
    RoomCounter(name: 'Verandah', count: 1),
    RoomCounter(name: 'Living Room', count: 1),
    RoomCounter(name: 'Dining Room', count: 1),
    RoomCounter(name: 'Kitchen / Pantry', count: 1),
    RoomCounter(name: 'Bedrooms', count: 3),
    RoomCounter(name: 'Bathrooms', count: 2),
    RoomCounter(name: 'Lavatories', count: 1),
    RoomCounter(name: 'Garage / Car Porch', count: 1),
  ];

  double get totalFloorAreaSqFt => groundFloorAreaSqFt + upperFloorAreaSqFt;

  Map<String, dynamic> toJson() => {
    'buildingName': buildingName,
    'roofType': roofType,
    'wallType': wallType,
    'floorType': floorType,
    'doorsWindows': doorsWindows,
    'bathFittings': bathFittings,
    'ageYears': ageYears,
    'structuralCondition': structuralCondition,
    'occupancy': occupancy,
    'groundFloorAreaSqFt': groundFloorAreaSqFt,
    'upperFloorAreaSqFt': upperFloorAreaSqFt,
    'roomCounters': roomCounters.map((r) => r.toJson()).toList(),
  };

  factory BuildingSpecification.fromJson(Map<String, dynamic> json) => BuildingSpecification(
    buildingName: json['buildingName'] ?? 'Main Residential Building',
    roofType: json['roofType'] ?? 'Concrete Flat Roof / Asbestos',
    wallType: json['wallType'] ?? 'Brick Masonry, Plastered & Painted',
    floorType: json['floorType'] ?? 'Ceramic Tiled',
    doorsWindows: json['doorsWindows'] ?? 'Timber Panel & Window Grills',
    bathFittings: json['bathFittings'] ?? 'Commode, Wash Basin, Complete',
    ageYears: json['ageYears'] ?? 5,
    structuralCondition: json['structuralCondition'] ?? 'Good',
    occupancy: json['occupancy'] ?? 'Owner Occupied',
    groundFloorAreaSqFt: (json['groundFloorAreaSqFt'] as num?)?.toDouble() ?? 1500.0,
    upperFloorAreaSqFt: (json['upperFloorAreaSqFt'] as num?)?.toDouble() ?? 0.0,
    roomCounters: (json['roomCounters'] as List?)
        ?.map((r) => RoomCounter.fromJson(r))
        .toList(),
  );
}

class BuildingDetails {
  bool hasBuilding;
  List<BuildingSpecification> buildings;
  String landShape;
  String landTopography;
  String subsoilCondition;
  String boundaryDemarcations;
  String additionalRemarks;
  List<PropertyPhoto> photographs;

  BuildingDetails({
    this.hasBuilding = true,
    List<BuildingSpecification>? buildings,
    this.landShape = 'Regular',
    this.landTopography = 'Flat at road grade',
    this.subsoilCondition = 'Firm, gravelly clay loam',
    this.boundaryDemarcations = 'Parapet wall and barbed wire fence',
    this.additionalRemarks = '',
    List<PropertyPhoto>? photographs,
  })  : buildings = buildings ?? [BuildingSpecification()],
        photographs = photographs ?? [
          PropertyPhoto(slotName: 'Front Elevation'),
          PropertyPhoto(slotName: 'Side / Rear View'),
          PropertyPhoto(slotName: 'Interior (Living/Dining)'),
          PropertyPhoto(slotName: 'Boundary / Entrance Road'),
        ];

  double get totalBuiltUpArea {
    if (!hasBuilding) return 0.0;
    return buildings.fold(0.0, (sum, b) => sum + b.totalFloorAreaSqFt);
  }

  Map<String, dynamic> toJson() => {
    'hasBuilding': hasBuilding,
    'buildings': buildings.map((b) => b.toJson()).toList(),
    'landShape': landShape,
    'landTopography': landTopography,
    'subsoilCondition': subsoilCondition,
    'boundaryDemarcations': boundaryDemarcations,
    'additionalRemarks': additionalRemarks,
    'photographs': photographs.map((p) => p.toJson()).toList(),
  };

  factory BuildingDetails.fromJson(Map<String, dynamic> json) => BuildingDetails(
    hasBuilding: json['hasBuilding'] ?? true,
    buildings: (json['buildings'] as List?)
        ?.map((b) => BuildingSpecification.fromJson(b))
        .toList() ?? [BuildingSpecification()],
    landShape: json['landShape'] ?? 'Regular',
    landTopography: json['landTopography'] ?? 'Flat at road grade',
    subsoilCondition: json['subsoilCondition'] ?? 'Firm, gravelly clay loam',
    boundaryDemarcations: json['boundaryDemarcations'] ?? 'Parapet wall and barbed wire fence',
    additionalRemarks: json['additionalRemarks'] ?? '',
    photographs: (json['photographs'] as List?)
        ?.map((p) => PropertyPhoto.fromJson(p))
        .toList() ?? [],
  );
}
