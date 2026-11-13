class StatutoryItem {
  String name;
  String status; // 'Applicable', 'Not Applicable', 'Obtained', 'Not Obtained', 'Pending Verification'
  String remarks;

  StatutoryItem({
    required this.name,
    this.status = 'Pending Verification',
    this.remarks = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status,
    'remarks': remarks,
  };

  factory StatutoryItem.fromJson(Map<String, dynamic> json) => StatutoryItem(
    name: json['name'] ?? '',
    status: json['status'] ?? 'Pending Verification',
    remarks: json['remarks'] ?? '',
  );
}

class InspectionData {
  String targetInstitution;
  String bankBranch;
  String valuationPurpose;
  String dateOfInspection;
  String village;
  String gnDivision;
  String korale;
  String divisionalSecretariat;
  String localAuthority; // Pradeshiya Sabha or Municipal Council
  String assessmentNumber;
  List<StatutoryItem> statutoryCompliances;

  InspectionData({
    this.targetInstitution = "People's Bank",
    this.bankBranch = '',
    this.valuationPurpose = 'Mortgage Security',
    this.dateOfInspection = '',
    this.village = '',
    this.gnDivision = '',
    this.korale = '',
    this.divisionalSecretariat = '',
    this.localAuthority = '',
    this.assessmentNumber = '',
    List<StatutoryItem>? statutoryCompliances,
  }) : statutoryCompliances = statutoryCompliances ?? [
    StatutoryItem(name: 'Street Lines', status: 'Applicable'),
    StatutoryItem(name: 'Building Limits', status: 'Applicable'),
    StatutoryItem(name: 'NBRO Clearance', status: 'Pending Verification'),
    StatutoryItem(name: 'Other Statutory Restrictions', status: 'Not Applicable'),
  ];

  Map<String, dynamic> toJson() => {
    'targetInstitution': targetInstitution,
    'bankBranch': bankBranch,
    'valuationPurpose': valuationPurpose,
    'dateOfInspection': dateOfInspection,
    'village': village,
    'gnDivision': gnDivision,
    'korale': korale,
    'divisionalSecretariat': divisionalSecretariat,
    'localAuthority': localAuthority,
    'assessmentNumber': assessmentNumber,
    'statutoryCompliances': statutoryCompliances.map((s) => s.toJson()).toList(),
  };

  factory InspectionData.fromJson(Map<String, dynamic> json) => InspectionData(
    targetInstitution: json['targetInstitution'] ?? "People's Bank",
    bankBranch: json['bankBranch'] ?? '',
    valuationPurpose: json['valuationPurpose'] ?? 'Mortgage Security',
    dateOfInspection: json['dateOfInspection'] ?? '',
    village: json['village'] ?? '',
    gnDivision: json['gnDivision'] ?? '',
    korale: json['korale'] ?? '',
    divisionalSecretariat: json['divisionalSecretariat'] ?? '',
    localAuthority: json['localAuthority'] ?? '',
    assessmentNumber: json['assessmentNumber'] ?? '',
    statutoryCompliances: (json['statutoryCompliances'] as List?)
        ?.map((s) => StatutoryItem.fromJson(s))
        .toList() ?? [],
  );
}
