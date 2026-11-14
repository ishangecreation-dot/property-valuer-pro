class DeedData {
  String deedNumber;
  String executionDate;
  String notaryPublicName;
  String notaryPublicStation;
  String landRegistry;
  String registrationDate;
  String dayBookNumber;
  String registerFolioNumber;
  String vendeeName;
  String vendeeNic;
  String vendeeAddress;
  String vendorName;
  String vendorNic;
  String vendorAddress;
  double purchaseConsideration;
  List<String> documentFilePaths;
  Map<String, bool> uncertainFields;

  DeedData({
    this.deedNumber = '',
    this.executionDate = '',
    this.notaryPublicName = '',
    this.notaryPublicStation = '',
    this.landRegistry = '',
    this.registrationDate = '',
    this.dayBookNumber = '',
    this.registerFolioNumber = '',
    this.vendeeName = '',
    this.vendeeNic = '',
    this.vendeeAddress = '',
    this.vendorName = '',
    this.vendorNic = '',
    this.vendorAddress = '',
    this.purchaseConsideration = 0.0,
    List<String>? documentFilePaths,
    Map<String, bool>? uncertainFields,
  })  : documentFilePaths = documentFilePaths ?? [],
        uncertainFields = uncertainFields ?? {};

  Map<String, dynamic> toJson() => {
    'deedNumber': deedNumber,
    'executionDate': executionDate,
    'notaryPublicName': notaryPublicName,
    'notaryPublicStation': notaryPublicStation,
    'landRegistry': landRegistry,
    'registrationDate': registrationDate,
    'dayBookNumber': dayBookNumber,
    'registerFolioNumber': registerFolioNumber,
    'vendeeName': vendeeName,
    'vendeeNic': vendeeNic,
    'vendeeAddress': vendeeAddress,
    'vendorName': vendorName,
    'vendorNic': vendorNic,
    'vendorAddress': vendorAddress,
    'purchaseConsideration': purchaseConsideration,
    'documentFilePaths': documentFilePaths,
    'uncertainFields': uncertainFields,
  };

  factory DeedData.fromJson(Map<String, dynamic> json) => DeedData(
    deedNumber: json['deedNumber'] ?? '',
    executionDate: json['executionDate'] ?? '',
    notaryPublicName: json['notaryPublicName'] ?? '',
    notaryPublicStation: json['notaryPublicStation'] ?? '',
    landRegistry: json['landRegistry'] ?? '',
    registrationDate: json['registrationDate'] ?? '',
    dayBookNumber: json['dayBookNumber'] ?? '',
    registerFolioNumber: json['registerFolioNumber'] ?? '',
    vendeeName: json['vendeeName'] ?? '',
    vendeeNic: json['vendeeNic'] ?? '',
    vendeeAddress: json['vendeeAddress'] ?? '',
    vendorName: json['vendorName'] ?? '',
    vendorNic: json['vendorNic'] ?? '',
    vendorAddress: json['vendorAddress'] ?? '',
    purchaseConsideration: (json['purchaseConsideration'] as num?)?.toDouble() ?? 0.0,
    documentFilePaths: List<String>.from(json['documentFilePaths'] ?? []),
    uncertainFields: Map<String, bool>.from(json['uncertainFields'] ?? {}),
  );
}
