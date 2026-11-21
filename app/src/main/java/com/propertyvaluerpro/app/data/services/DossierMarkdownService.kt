package com.propertyvaluerpro.app.data.services

import android.content.Context
import com.propertyvaluerpro.app.data.models.CurrencyFormatter
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.data.models.ValuerProfile
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object DossierMarkdownService {
    fun buildDossierMarkdown(
        profile: ValuerProfile,
        project: ValuationProject?,
    ): String {
        val dateStr = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US).format(Date())
        val projName = project?.projectName?.ifBlank { "Valuation Dossier" } ?: "Valuation Dossier"
        val targetBank = project?.clientOrBank?.ifBlank { "Financial Institution" } ?: "Financial Institution"
        val targetPages = project?.targetPageCount ?: 4

        return buildString {
            appendLine("# Chartered Valuation Report Case Dossier")
            appendLine()
            appendLine("> **Case Title:** $projName")
            appendLine("> **Target Client / Banking Panel:** $targetBank")
            appendLine("> **Target Page Budget:** $targetPages Pages")
            appendLine("> **Last Updated:** $dateStr")
            appendLine()
            appendLine("---")
            appendLine()
            appendLine("## 1. Practitioner & Chambers Profile (Step 2)")
            appendLine("- **Valuer Name:** ${profile.valuerName.ifBlank { "[Pending Entry]" }}")
            appendLine("- **Qualifications:** ${profile.qualifications.ifBlank { "[Pending Entry]" }}")
            appendLine("- **Registration Number:** ${profile.registrationNumber.ifBlank { "[Pending Entry]" }}")
            appendLine("- **Professional Membership:** ${profile.professionalMembership.ifBlank { "Associate / Fellow Member" }}")
            appendLine("- **Chambers Office Address:** ${profile.officeAddress.ifBlank { "[Pending Entry]" }}")
            appendLine("- **Primary Phone:** ${profile.contactNumber.ifBlank { "[Pending Entry]" }}")
            if (profile.contactNumber2.isNotBlank()) appendLine("- **Secondary Phone:** ${profile.contactNumber2}")
            if (profile.emailAddress.isNotBlank()) appendLine("- **Official Dispatch Email:** ${profile.emailAddress}")
            if (profile.additionalContactDetails.isNotBlank()) appendLine("- **Authorized Bank Panels:** ${profile.additionalContactDetails}")
            appendLine()
            appendLine("## 2. AI Document Analysis Baseline (Step 2)")
            if (profile.uploadedTemplates.isNotEmpty()) {
                appendLine("- **Draft Reports Analyzed:** ${profile.uploadedTemplates.joinToString(", ")}")
                appendLine("- **Report Format:** ${profile.reportFormat.ifBlank { "Chartered 10-Point Schedule" }}")
                appendLine("- **Report Style:** ${profile.reportStyle.ifBlank { "Formal Chartered Terminology" }}")
                appendLine("- **Report Type:** ${profile.reportType.ifBlank { "Real Estate Mortgage Collateral" }}")
                if (profile.reportContentFeatures.isNotBlank()) appendLine("- **Content & Features:** ${profile.reportContentFeatures}")
                if (profile.reportSectionOrder.isNotBlank()) appendLine("- **Section Order:** ${profile.reportSectionOrder}")
            } else {
                appendLine("*No sample draft reports uploaded yet. Official chartered baseline format applied.*")
            }
            appendLine()
            appendLine("## 3. Title Deed Extraction Particulars (Step 3)")
            val deed = project?.deedData
            if (deed != null && deed.deedNumber.isNotBlank()) {
                appendLine("- **Deed Number:** ${deed.deedNumber} (Executed: ${deed.executionDate})")
                appendLine("- **Notary Public:** ${deed.notaryPublicName} (${deed.notaryPublicStation})")
                appendLine("- **Land Registry:** ${deed.landRegistry} | Folio: ${deed.registerFolioNumber}")
                appendLine("- **Current Owner / Vendee:** ${deed.vendeeName} (NIC: ${deed.vendeeNic})")
                appendLine("- **Vendor:** ${deed.vendorName} | Consideration: ${CurrencyFormatter.formatLkr(deed.purchaseConsideration)}")
            } else {
                appendLine("*Title Deed extraction pending in Step 3.*")
            }
            appendLine()
            appendLine("## 4. Cadastral Survey Plan & Lots (Step 4)")
            val plan = project?.surveyPlanData
            if (plan != null && plan.planNumber.isNotBlank()) {
                appendLine("- **Plan No:** ${plan.planNumber} | **Survey Date:** ${plan.surveyDate}")
                appendLine("- **Surveyor:** ${plan.surveyorName} (${plan.surveyorRegistrationNumber})")
                appendLine("- **Land Name:** ${plan.landName} | **Selected Extent:** ${"%.2f".format(plan.selectedTotalPerches)} Perches")
            } else {
                appendLine("*Survey Plan details pending in Step 4.*")
            }
            appendLine()
            appendLine("## 5. Inspection, Location & Building (Steps 5-8)")
            if (project != null) {
                val ins = project.inspectionData
                val loc = project.locationData
                appendLine("- **Institution:** ${ins.targetInstitution} (${ins.bankBranch}) | **Purpose:** ${ins.valuationPurpose}")
                appendLine("- **Locality:** ${loc.nearestTown.ifBlank { "Pending" }} (${loc.distanceFromTownKm} km) | Road: ${loc.accessRoadWidthFt} ft ${loc.roadSurface}")
                appendLine("- **Building:** ${if (project.buildingDetails.hasBuilding && !project.buildingSketch.isBareLand) "${project.buildingDetails.totalBuiltUpArea.toInt()} sq.ft." else "Bare Land"}")
            }
            appendLine()
            appendLine("## 6. Valuation Engine Summary (Step 9)")
            if (project != null) {
                val vd = project.valuationData
                val perches = project.surveyPlanData.selectedTotalPerches.takeIf { it > 0 } ?: 15.0
                val hasBuilding = project.buildingDetails.hasBuilding && !project.buildingSketch.isBareLand
                val area = project.buildingDetails.totalBuiltUpArea
                val raw = vd.computeTotalMarketValue(perches, area, hasBuilding)
                val say = vd.computeSayValue(raw)
                val fsv = vd.computeFsv(say)
                appendLine("- **Evaluated Extent:** ${"%.2f".format(perches)} Perches @ ${CurrencyFormatter.formatLkr(vd.adoptedLandRatePerPerch)}/P")
                appendLine("- **CERTIFIED MARKET VALUE (SAY):** ${CurrencyFormatter.formatLkr(say)}")
                appendLine("- **FORCED SALE VALUE (${vd.fsvPercentage.toInt()}% FSV):** ${CurrencyFormatter.formatLkr(fsv)}")
                appendLine("- **Collateral Rating:** ${vd.collateralRating}")
            }
            appendLine()
            if (profile.reportStyleSpecMd.isNotBlank()) {
                appendLine("## 7. Learned Report Style Specification (AI Draft Analysis)")
                appendLine("The final issued report must reproduce the format, style, content and features below:")
                appendLine()
                appendLine(profile.reportStyleSpecMd.trim())
            }
        }
    }

    fun persistDossierFile(context: Context, profile: ValuerProfile, project: ValuationProject?): String {
        val md = buildDossierMarkdown(profile, project)
        return runCatching {
            val file = File(context.filesDir, "VALUATION_CASE_DOSSIER.md")
            file.writeText(md)
            file.absolutePath
        }.getOrDefault("")
    }
}
