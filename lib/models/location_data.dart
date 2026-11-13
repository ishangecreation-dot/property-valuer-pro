class LocationData {
  double latitude;
  double longitude;
  String nearestTown;
  String startingJunction;
  String accessDirections;
  double distanceFromTownKm;
  double accessRoadWidthFt;
  String roadSurface; // 'Concrete', 'Carpet', 'Gravel', 'Earth Road', 'Other'
  String roadCondition; // 'Good', 'Fair', 'Poor'
  String vehicleAccessibility; // 'All Vehicles', 'Cars & Light Vehicles', 'Motorcycles / 3-Wheelers only'
  List<String> utilities;

  LocationData({
    this.latitude = 7.2405,
    this.longitude = 80.5925,
    this.nearestTown = '',
    this.startingJunction = '',
    this.accessDirections = '',
    this.distanceFromTownKm = 0.0,
    this.accessRoadWidthFt = 15.0,
    this.roadSurface = 'Carpet',
    this.roadCondition = 'Good',
    this.vehicleAccessibility = 'All Vehicles',
    List<String>? utilities,
  }) : utilities = utilities ?? [
    'CEB Electricity (Single Phase)',
    'NWSDB Piped Water',
    'Telecommunications',
    'Public Bus Route',
  ];

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'nearestTown': nearestTown,
    'startingJunction': startingJunction,
    'accessDirections': accessDirections,
    'distanceFromTownKm': distanceFromTownKm,
    'accessRoadWidthFt': accessRoadWidthFt,
    'roadSurface': roadSurface,
    'roadCondition': roadCondition,
    'vehicleAccessibility': vehicleAccessibility,
    'utilities': utilities,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: (json['latitude'] as num?)?.toDouble() ?? 7.2405,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 80.5925,
    nearestTown: json['nearestTown'] ?? '',
    startingJunction: json['startingJunction'] ?? '',
    accessDirections: json['accessDirections'] ?? '',
    distanceFromTownKm: (json['distanceFromTownKm'] as num?)?.toDouble() ?? 0.0,
    accessRoadWidthFt: (json['accessRoadWidthFt'] as num?)?.toDouble() ?? 15.0,
    roadSurface: json['roadSurface'] ?? 'Carpet',
    roadCondition: json['roadCondition'] ?? 'Good',
    vehicleAccessibility: json['vehicleAccessibility'] ?? 'All Vehicles',
    utilities: List<String>.from(json['utilities'] ?? []),
  );
}
