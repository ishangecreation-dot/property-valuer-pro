class ValuerProfile {
  String valuerName;
  String qualifications;
  String professionalMembership;
  String registrationNumber;
  String officeAddress;
  String emailAddress;
  String contactNumber;
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
    this.additionalContactDetails = '',
    List<String>? uploadedTemplates,
  }) : uploadedTemplates = uploadedTemplates ?? [];

  Map<String, dynamic> toJson() => {
    'valuerName': valuerName,
    'qualifications': qualifications,
    'professionalMembership': professionalMembership,
    'registrationNumber': registrationNumber,
    'officeAddress': officeAddress,
    'emailAddress': emailAddress,
    'contactNumber': contactNumber,
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
    contactNumber: json['contactNumber'] ?? '',
    additionalContactDetails: json['additionalContactDetails'] ?? '',
    uploadedTemplates: List<String>.from(json['uploadedTemplates'] ?? []),
  );

  bool get isConfigured => valuerName.trim().isNotEmpty && registrationNumber.trim().isNotEmpty;
}
