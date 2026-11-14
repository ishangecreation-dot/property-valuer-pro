class ValuerProfile {
  String valuerName;
  String qualifications;
  String professionalMembership;
  String registrationNumber;
  String officeAddress;
  String emailAddress;
  String contactNumber; // Contact Number 1 (Primary)
  String contactNumber2; // Contact Number 2 (Optional)
  String additionalContactDetails;
  List<String> uploadedTemplates;

  ValuerProfile({
    this.valuerName = '',
    this.qualifications = '',
    this.professionalMembership = '',
    this.registrationNumber = '',
    this.officeAddress = '',
    this.emailAddress = '',
    this.contactNumber = '',
    this.contactNumber2 = '',
    this.additionalContactDetails = '',
    List<String>? uploadedTemplates,
  }) : uploadedTemplates = uploadedTemplates ?? [];

  /// Helper getter and setter for Contact Number 1
  String get contactNumber1 => contactNumber;
  set contactNumber1(String value) => contactNumber = value;

  Map<String, dynamic> toJson() => {
    'valuerName': valuerName,
    'qualifications': qualifications,
    'professionalMembership': professionalMembership,
    'registrationNumber': registrationNumber,
    'officeAddress': officeAddress,
    'emailAddress': emailAddress,
    'contactNumber': contactNumber,
    'contactNumber1': contactNumber,
    'contactNumber2': contactNumber2,
    'additionalContactDetails': additionalContactDetails,
    'uploadedTemplates': uploadedTemplates,
  };

  factory ValuerProfile.fromJson(Map<String, dynamic> json) => ValuerProfile(
    valuerName: json['valuerName'] ?? '',
    qualifications: json['qualifications'] ?? '',
    professionalMembership: json['professionalMembership'] ?? '',
    registrationNumber: json['registrationNumber'] ?? '',
    officeAddress: json['officeAddress'] ?? '',
    emailAddress: json['emailAddress'] ?? '',
    contactNumber: json['contactNumber1'] ?? json['contactNumber'] ?? '',
    contactNumber2: json['contactNumber2'] ?? '',
    additionalContactDetails: json['additionalContactDetails'] ?? '',
    uploadedTemplates: List<String>.from(json['uploadedTemplates'] ?? []),
  );

  /// Checks if minimum required professional credentials have been configured
  bool get isConfigured =>
      valuerName.trim().isNotEmpty &&
      qualifications.trim().isNotEmpty &&
      registrationNumber.trim().isNotEmpty &&
      officeAddress.trim().isNotEmpty &&
      contactNumber.trim().isNotEmpty;
}
