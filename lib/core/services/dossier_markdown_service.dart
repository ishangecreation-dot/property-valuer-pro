import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/valuation_project.dart';
import '../../models/valuer_profile.dart';
import '../storage/storage_service.dart';

/// Service responsible for maintaining a comprehensive Markdown (.md) case dossier
/// collecting all details across workflow steps (Profile, Deed, Survey Plan, Inspection,
/// Location, Building, SWOC, Valuation Engine) to guide final report creation.
class DossierMarkdownService {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  /// Generates the complete, structured Markdown dossier content
  static String buildDossierMarkdown({
    required ValuerProfile profile,
    ValuationProject? project,
  }) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final projName = project?.projectName.isNotEmpty == true ? project!.projectName : 'Valuation Dossier';
    final targetBank = project?.clientOrBank.isNotEmpty == true ? project!.clientOrBank : "Financial Institution";
    final targetPages = project?.targetPageCount ?? 4;

    final buffer = StringBuffer();

    // Header & Metadata
    buffer.writeln('# Chartered Valuation Report Case Dossier');
    buffer.writeln();
    buffer.writeln('> **Case Title:** $projName  ');
    buffer.writeln('> **Target Client / Banking Panel:** $targetBank  ');
    buffer.writeln('> **Target Page Budget:** $targetPages Pages  ');
    buffer.writeln('> **Last Updated:** $dateStr  ');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 1: Valuer Profile & Practitioner Credentials
    buffer.writeln('## 1. Practitioner & Chambers Profile (Step 2)');
    buffer.writeln('- **Valuer Name:** ${profile.valuerName.isNotEmpty ? profile.valuerName : '[Pending Entry]'}');
    buffer.writeln('- **Qualifications:** ${profile.qualifications.isNotEmpty ? profile.qualifications : '[Pending Entry]'}');
    buffer.writeln('- **Registration Number:** ${profile.registrationNumber.isNotEmpty ? profile.registrationNumber : '[Pending Entry]'}');
    buffer.writeln('- **Professional Membership:** ${profile.professionalMembership.isNotEmpty ? profile.professionalMembership : 'Associate / Fellow Member'}');
    buffer.writeln('- **Chambers Office Address:** ${profile.officeAddress.isNotEmpty ? profile.officeAddress : '[Pending Entry]'}');
    buffer.writeln('- **Primary Phone:** ${profile.contactNumber.isNotEmpty ? profile.contactNumber : '[Pending Entry]'}');
    if (profile.contactNumber2.isNotEmpty) {
      buffer.writeln('- **Secondary Phone:** ${profile.contactNumber2}');
    }
    if (profile.emailAddress.isNotEmpty) {
      buffer.writeln('- **Official Dispatch Email:** ${profile.emailAddress}');
    }
    if (profile.additionalContactDetails.isNotEmpty) {
      buffer.writeln('- **Authorized Bank Panels / Notes:** ${profile.additionalContactDetails}');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 2: AI Document Analysis Baseline
    buffer.writeln('## 2. AI Document Analysis Baseline (Step 2)');
    if (profile.uploadedTemplates.isNotEmpty) {
      buffer.writeln('- **Source Draft Reports Analyzed:** ${profile.uploadedTemplates.join(', ')}');
      buffer.writeln('- **Report Format:** ${profile.reportFormat.isNotEmpty ? profile.reportFormat : 'Chartered 10-Point Schedule with Executive Appraisal Table'}');
      buffer.writeln('- **Report Style:** ${profile.reportStyle.isNotEmpty ? profile.reportStyle : 'Formal Chartered Practitioner Terminology & LKR Rounding'}');
      buffer.writeln('- **Report Type:** ${profile.reportType.isNotEmpty ? profile.reportType : 'Real Estate Mortgage Collateral & Bank Panel Valuation'}');
      buffer.writeln();
      buffer.writeln('### Extracted Formatting & Styling Blueprint');
      buffer.writeln(profile.reportStyleSummary.isNotEmpty
          ? profile.reportStyleSummary
          : '• Standard chartered executive summary table.\n• Extent in Acres-Roods-Perches with Perch rate.\n• GRC itemization with age depreciation schedule.\n• Professional impartiality certificate.');
    } else {
      buffer.writeln('*No sample draft reports uploaded yet. SKILL.md official chartered baseline format will be applied.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 3: Title Deed Extraction Particulars (Step 3)
    buffer.writeln('## 3. Title Deed Extraction Particulars & Devolution (Step 3)');
    if (project != null && project.deedData.deedNumber.isNotEmpty) {
      final d = project.deedData;
      buffer.writeln('- **Deed Number:** ${d.deedNumber}');
      buffer.writeln('- **Date of Execution:** ${d.dateOfExecution}');
      buffer.writeln('- **Attesting Notary Public:** ${d.notaryName}');
      buffer.writeln('- **Notary Judicial Zone / Station:** ${d.judicialZone}');
      buffer.writeln('- **Land Registry Office:** ${d.landRegistry}');
      buffer.writeln('- **Registration Folio:** Volume ${d.volumeNumber}, Folio ${d.folioNumber} (Day Book: ${d.dayBookNumber})');
      buffer.writeln('- **Current Owner / Vendee:** ${d.purchaserName}');
      if (d.purchaserNic.isNotEmpty) buffer.writeln('- **Vendee NIC:** ${d.purchaserNic}');
      if (d.purchaserAddress.isNotEmpty) buffer.writeln('- **Vendee Address:** ${d.purchaserAddress}');
      buffer.writeln('- **Prior Vendor (Seller):** ${d.sellerName}');
      buffer.writeln('- **Prior Consideration Amount:** LKR ${_currencyFormat.format(d.priorConsiderationAmount)}');
      if (d.priorDeedReference.isNotEmpty) buffer.writeln('- **Prior Deed Reference:** ${d.priorDeedReference}');
    } else {
      buffer.writeln('*Title Deed extraction pending execution in Step 3.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 4: Cadastral Survey Plan Particulars & Allotments (Step 4)
    buffer.writeln('## 4. Cadastral Survey Plan Particulars & Exact Lots (Step 4)');
    if (project != null && project.surveyPlanData.planNumber.isNotEmpty) {
      final sp = project.surveyPlanData;
      buffer.writeln('- **Plan Number:** ${sp.planNumber}');
      buffer.writeln('- **Date of Survey:** ${sp.surveyDate}');
      buffer.writeln('- **Licensed Surveyor:** ${sp.surveyorName} (Reg: ${sp.surveyorRegistrationNumber})');
      buffer.writeln('- **Land / Estate Name:** ${sp.landName}');
      if (sp.priorPlanReference.isNotEmpty) buffer.writeln('- **Prior Plan Reference:** ${sp.priorPlanReference}');
      buffer.writeln('- **Surveyed Lots Breakdown:**');
      buffer.writeln('| Lot No | Extent (A-R-P) | Perches | North Boundary | East Boundary | South Boundary | West Boundary | Selected |');
      buffer.writeln('|:---:|:---:|:---:|:---|:---|:---|:---|:---:|');
      for (final lot in sp.lots) {
        final arp = '${lot.acres}A ${lot.roods}R ${lot.perches.toStringAsFixed(2)}P';
        buffer.writeln('| ${lot.lotNumber} | $arp | ${lot.totalPerches.toStringAsFixed(2)} | ${lot.northBoundary} | ${lot.eastBoundary} | ${lot.southBoundary} | ${lot.westBoundary} | ${lot.isSelected ? "Yes" : "No"} |');
      }
    } else {
      buffer.writeln('*Cadastral survey plan extraction pending execution in Step 4.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 5: Purpose of Valuation & Site Inspection (Step 5)
    buffer.writeln('## 5. Purpose of Valuation & Site Inspection (Step 5)');
    if (project != null && project.inspectionData.dateOfInspection.isNotEmpty) {
      final ins = project.inspectionData;
      buffer.writeln('- **Valuation Purpose:** ${ins.purposeOfValuation}');
      buffer.writeln('- **Date of Inspection:** ${ins.dateOfInspection}');
      buffer.writeln('- **Weather Conditions:** ${ins.weatherCondition}');
      buffer.writeln('- **Persons Present on Site:** ${ins.presentAtInspection}');
      buffer.writeln('- **Local Authority Jurisdiction:** ${ins.localAuthority}');
      buffer.writeln('- **Street Line Conformity:** ${ins.streetLineConformity}');
      buffer.writeln('- **Building Limits & Reservations:** ${ins.buildingLineConformity}');
    } else {
      buffer.writeln('*Site inspection particulars pending execution in Step 5.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 6: Situation, Accessibility & GIS Geolocation (Step 6)
    buffer.writeln('## 6. Situation, Accessibility & GIS Geolocation (Step 6)');
    if (project != null && project.locationData.nearestTown.isNotEmpty) {
      final loc = project.locationData;
      buffer.writeln('- **GPS Coordinates:** Latitude ${loc.latitude.toStringAsFixed(6)}, Longitude ${loc.longitude.toStringAsFixed(6)}');
      buffer.writeln('- **Locality & Distance:** ${loc.distanceFromTown} km from ${loc.nearestTown}');
      buffer.writeln('- **Frontage Road Width:** ${loc.roadWidthFeet} ft');
      buffer.writeln('- **Road Surface:** ${loc.roadType}');
      buffer.writeln('- **Motorable Access Level:** ${loc.accessType}');
      buffer.writeln('- **Public Utilities:** '
          'CEB Electricity: ${loc.hasElectricity ? "Available" : "Not Available"}, '
          'NWSDB Pipe Water: ${loc.hasPipeWater ? "Available" : "Not Available"}, '
          'Telecom: ${loc.hasTelecom ? "Available" : "Not Available"}, '
          'Drainage: ${loc.hasDrainage ? "Available" : "Not Available"}');
      if (loc.directionNotes.isNotEmpty) buffer.writeln('- **Access Directions:** ${loc.directionNotes}');
    } else {
      buffer.writeln('*Situation and access particulars pending execution in Step 6.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 7: Building Improvements & Specifications (Step 7 & 8)
    buffer.writeln('## 7. Building Improvements & CAD Specifications (Step 7 & 8)');
    if (project != null && (project.buildingDetails.buildings.isNotEmpty || project.buildingSketch.isBareLand)) {
      if (project.buildingSketch.isBareLand) {
        buffer.writeln('- **Property Classification:** Bare Land (No structural improvements).');
      } else {
        buffer.writeln('- **Property Classification:** Improved Real Estate.');
        for (int i = 0; i < project.buildingDetails.buildings.length; i++) {
          final b = project.buildingDetails.buildings[i];
          buffer.writeln('### Improvement #${i + 1}: ${b.buildingName}');
          buffer.writeln('- **Gross Floor Area:** ${b.totalFloorAreaSqFt} sq.ft.');
          buffer.writeln('- **Estimated Age:** ${b.ageYears} years');
          buffer.writeln('- **Condition:** ${b.condition}');
          buffer.writeln('- **Roof:** ${b.roofType} | **Ceiling:** ${b.ceilingType} | **Walls:** ${b.wallType} | **Floors:** ${b.floorType} | **Doors/Windows:** ${b.doorsWindowsType}');
          buffer.writeln('- **Accommodation Breakdown:** ${b.accommodation}');
        }
      }
    } else {
      buffer.writeln('*Building specifications pending execution in Step 7 and 8.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 8: Land Physical Characteristics & SWOC Matrix (Step 8)
    buffer.writeln('## 8. Land Physicality & SWOC Risk Matrix (Step 8)');
    if (project != null && project.valuationData.adoptedLandRatePerPerch > 0) {
      final vd = project.valuationData;
      buffer.writeln('- **Topography:** ${vd.topography}');
      buffer.writeln('- **SWOC Risk Matrix:**');
      buffer.writeln('  - **Strengths (S):** ${vd.swocStrengths.isNotEmpty ? vd.swocStrengths : "Clear title, prominent frontage, rapid appreciation."}');
      buffer.writeln('  - **Weaknesses (W):** ${vd.swocWeaknesses.isNotEmpty ? vd.swocWeaknesses : "Narrow bend on approach road."}');
      buffer.writeln('  - **Opportunities (O):** ${vd.swocOpportunities.isNotEmpty ? vd.swocOpportunities : "Expanding urban commercial hub."}');
      buffer.writeln('  - **Constraints (C):** ${vd.swocConstraints.isNotEmpty ? vd.swocConstraints : "Statutory local authority street lines."}');
    } else {
      buffer.writeln('*Land characteristics and SWOC analysis pending in Step 8.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 9: Chartered Valuation Engine & Calculations (Step 9)
    buffer.writeln('## 9. Chartered Valuation Engine & Calculations (Step 9)');
    if (project != null && project.valuationData.adoptedLandRatePerPerch > 0) {
      final vd = project.valuationData;
      buffer.writeln('### Land Valuation');
      buffer.writeln('- **Evaluated Extent:** ${vd.evaluatedPerches.toStringAsFixed(2)} Perches');
      buffer.writeln('- **Adopted Market Rate:** LKR ${_currencyFormat.format(vd.adoptedLandRatePerPerch)} / Perch');
      buffer.writeln('- **Total Land Value:** **LKR ${_currencyFormat.format(vd.totalLandValue)}**');
      buffer.writeln();
      buffer.writeln('### Building Valuation (Depreciated Replacement Cost)');
      buffer.writeln('- **Gross Replacement Cost (GRC):** LKR ${_currencyFormat.format(vd.totalBuildingGrc)}');
      buffer.writeln('- **Depreciation Allowance (${vd.buildingDepreciationPercentage}%):** LKR ${_currencyFormat.format(vd.totalBuildingGrc * (vd.buildingDepreciationPercentage / 100.0))}');
      buffer.writeln('- **Depreciated Net Building Value:** **LKR ${_currencyFormat.format(vd.depreciatedBuildingValue)}**');
      buffer.writeln();
      buffer.writeln('### Executive Valuation Summary');
      buffer.writeln('- **Total Unrounded Market Value:** LKR ${_currencyFormat.format(vd.unroundedMarketValue)}');
      buffer.writeln('- **CERTIFIED MARKET VALUE (SAY):** **LKR ${_currencyFormat.format(vd.certifiedMarketValueSay)}**');
      buffer.writeln('- **Forced Sale Value Discount:** ${vd.forcedSaleValuePercentage}%');
      buffer.writeln('- **FORCED SALE VALUE (FSV):** **LKR ${_currencyFormat.format(vd.forcedSaleValue)}**');
      buffer.writeln('- **Collateral Risk Underwriting Rating:** **${vd.collateralRiskRating}**');
    } else {
      buffer.writeln('*Valuation computations pending execution in Step 9.*');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // Section 10: Report Directives & Certification Block
    buffer.writeln('## 10. Report Directives & Certification Block (Step 10)');
    buffer.writeln('- **Valuation Standard:** Conforming to Sri Lanka Standards for Property Valuation and RICS Appraisal guidelines.');
    buffer.writeln('- **Impartiality Declaration:** The valuer declares no present or prospective interest in the subject property.');
    buffer.writeln('- **Annexures Scheduled:** Annexure I (Title Deed Schedule), Annexure II (SWOC Analysis Matrix), Annexure III (Photo Register).');
    buffer.writeln('- **Signatory:** ${profile.valuerName.isNotEmpty ? profile.valuerName : "Chartered Valuation Practitioner"}, ${profile.qualifications} (${profile.registrationNumber})');

    return buffer.toString();
  }

  /// Updates and persists the dossier markdown locally and in device documents directory
  static Future<String> updateDossier({
    required ValuerProfile profile,
    ValuationProject? project,
  }) async {
    final mdContent = buildDossierMarkdown(profile: profile, project: project);

    // Save into SharedPreferences
    await StorageService.saveDossierMarkdown(mdContent);

    // Also write to application documents directory
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/VALUATION_CASE_DOSSIER.md');
      await file.writeAsString(mdContent, flush: true);
      return file.path;
    } catch (_) {
      return '';
    }
  }
}
