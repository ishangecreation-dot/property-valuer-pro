class ValuerProfile {
  String id;
  String draftName;
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
  String reportStyleSummary;
  String reportFormat;
  String reportStyle;
  String reportType;
  Map<String, String> templateStyleNotes;
  DateTime? lastModified;

  ValuerProfile({
    String? id,
    this.draftName = 'Default Profile',
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
    this.reportStyleSummary = '',
    this.reportFormat = '',
    this.reportStyle = '',
    this.reportType = '',
    Map<String, String>? templateStyleNotes,
    this.lastModified,
  })  : id = id ?? (valuerName.isNotEmpty ? 'draft_${valuerName.hashCode.abs()}' : 'draft_default'),
        uploadedTemplates = uploadedTemplates ?? [],
        templateStyleNotes = templateStyleNotes ?? {};

  /// Helper getter and setter for Contact Number 1
  String get contactNumber1 => contactNumber;
  set contactNumber1(String value) => contactNumber = value;

  Map<String, dynamic> toJson() => {
    'id': id,
    'draftName': draftName,
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
    'reportStyleSummary': reportStyleSummary,
    'reportFormat': reportFormat,
    'reportStyle': reportStyle,
    'reportType': reportType,
    'templateStyleNotes': templateStyleNotes,
    'lastModified': lastModified?.toIso8601String(),
  };

  factory ValuerProfile.fromJson(Map<String, dynamic> json) => ValuerProfile(
    id: json['id']?.toString() ?? 'draft_default',
    draftName: json['draftName']?.toString() ?? 'Default Profile',
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
    reportStyleSummary: json['reportStyleSummary']?.toString() ?? '',
    reportFormat: json['reportFormat']?.toString() ?? '',
    reportStyle: json['reportStyle']?.toString() ?? '',
    reportType: json['reportType']?.toString() ?? '',
    templateStyleNotes: Map<String, String>.from(json['templateStyleNotes'] ?? {}),
    lastModified: json['lastModified'] != null
        ? DateTime.tryParse(json['lastModified'].toString())
        : null,
  );

  ValuerProfile copyWith({
    String? id,
    String? draftName,
    String? valuerName,
    String? qualifications,
    String? professionalMembership,
    String? registrationNumber,
    String? officeAddress,
    String? emailAddress,
    String? contactNumber,
    String? contactNumber2,
    String? additionalContactDetails,
    List<String>? uploadedTemplates,
    String? reportStyleSummary,
    String? reportFormat,
    String? reportStyle,
    String? reportType,
    Map<String, String>? templateStyleNotes,
    DateTime? lastModified,
  }) {
    return ValuerProfile(
      id: id ?? this.id,
      draftName: draftName ?? this.draftName,
      valuerName: valuerName ?? this.valuerName,
      qualifications: qualifications ?? this.qualifications,
      professionalMembership: professionalMembership ?? this.professionalMembership,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      officeAddress: officeAddress ?? this.officeAddress,
      emailAddress: emailAddress ?? this.emailAddress,
      contactNumber: contactNumber ?? this.contactNumber,
      contactNumber2: contactNumber2 ?? this.contactNumber2,
      additionalContactDetails: additionalContactDetails ?? this.additionalContactDetails,
      uploadedTemplates: uploadedTemplates ?? List.from(this.uploadedTemplates),
      reportStyleSummary: reportStyleSummary ?? this.reportStyleSummary,
      reportFormat: reportFormat ?? this.reportFormat,
      reportStyle: reportStyle ?? this.reportStyle,
      reportType: reportType ?? this.reportType,
      templateStyleNotes: templateStyleNotes ?? Map.from(this.templateStyleNotes),
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Whether document analysis has been performed on uploaded draft reports
  bool get isDocumentAnalysisComplete =>
      uploadedTemplates.isNotEmpty &&
      (reportFormat.isNotEmpty || reportStyleSummary.isNotEmpty);

  /// Checks if minimum required professional credentials have been configured
  bool get isConfigured =>
      valuerName.trim().isNotEmpty &&
      qualifications.trim().isNotEmpty &&
      registrationNumber.trim().isNotEmpty &&
      officeAddress.trim().isNotEmpty &&
      contactNumber.trim().isNotEmpty;
}
