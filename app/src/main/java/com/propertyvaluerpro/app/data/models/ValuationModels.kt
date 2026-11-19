package com.propertyvaluerpro.app.data.models

import kotlinx.serialization.Serializable
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale
import kotlin.math.roundToLong

object AppConstants {
    const val APP_NAME = "Property Valuer Pro"
    const val APP_VERSION = "1.0.0 (Build 1)"
    const val FREE_TIER_TEMPLATE_LIMIT = 3
    const val MONTHLY_FREE_REPORT_LIMIT = 10
    const val AD_PROVIDER_META = "Meta Audience Network"
    const val AD_PROVIDER_ADMOB = "Google AdMob"
    const val DEFAULT_META_INTERSTITIAL_ID = "VID_HD_9_16_39S_APP_INSTALL#YOUR_PLACEMENT_ID"

    val WORKFLOW_STEPS = listOf(
        "Dashboard",
        "Valuer Profile",
        "Title Deed",
        "Survey Plan",
        "Purpose & Statutory",
        "Location & Access",
        "A3 Mini-CAD",
        "Building Details",
        "Valuation Math",
        "Review & Generate",
    )

    const val STATUS_DRAFT = "Draft"
    const val STATUS_IN_PROGRESS = "In Progress"
    const val STATUS_READY = "Ready to Generate"
    const val STATUS_COMPLETED = "Completed"
}

object CurrencyFormatter {
    private val formatter = DecimalFormat("#,##0.00", DecimalFormatSymbols(Locale.US))
    fun format(value: Double): String = formatter.format(value)
    fun formatLkr(value: Double): String = "LKR ${formatter.format(value)}"
}

@Serializable
data class ValuerProfile(
    val id: String = "draft_default",
    val draftName: String = "Default Profile",
    val valuerName: String = "",
    val qualifications: String = "",
    val professionalMembership: String = "",
    val registrationNumber: String = "",
    val officeAddress: String = "",
    val emailAddress: String = "",
    val contactNumber: String = "",
    val contactNumber2: String = "",
    val additionalContactDetails: String = "",
    val uploadedTemplates: List<String> = emptyList(),
    val reportStyleSummary: String = "",
    val reportFormat: String = "",
    val reportStyle: String = "",
    val reportType: String = "",
    val lastModifiedEpochMs: Long = System.currentTimeMillis(),
) {
    val isDocumentAnalysisComplete: Boolean
        get() = uploadedTemplates.isNotEmpty() && (reportFormat.isNotEmpty() || reportStyleSummary.isNotEmpty())

    val isConfigured: Boolean
        get() = valuerName.isNotBlank() &&
            qualifications.isNotBlank() &&
            registrationNumber.isNotBlank() &&
            officeAddress.isNotBlank() &&
            contactNumber.isNotBlank()
}

@Serializable
data class DeedData(
    val deedNumber: String = "",
    val executionDate: String = "",
    val notaryPublicName: String = "",
    val notaryPublicStation: String = "",
    val landRegistry: String = "",
    val registrationDate: String = "",
    val dayBookNumber: String = "",
    val registerFolioNumber: String = "",
    val vendeeName: String = "",
    val vendeeNic: String = "",
    val vendeeAddress: String = "",
    val vendorName: String = "",
    val vendorNic: String = "",
    val vendorAddress: String = "",
    val purchaseConsideration: Double = 0.0,
    val documentFilePaths: List<String> = emptyList(),
    val uncertainFields: Map<String, Boolean> = emptyMap(),
)

@Serializable
data class PlanLot(
    val lotNumber: String = "1",
    val acres: Int = 0,
    val roods: Int = 0,
    val perches: Double = 0.0,
    val northBoundary: String = "",
    val eastBoundary: String = "",
    val southBoundary: String = "",
    val westBoundary: String = "",
    val isSelected: Boolean = true,
) {
    val totalPerches: Double
        get() = (acres * 160.0) + (roods * 40.0) + perches
}

@Serializable
data class SurveyPlanData(
    val planNumber: String = "",
    val surveyDate: String = "",
    val certificationDate: String = "",
    val surveyorName: String = "",
    val surveyorRegistrationNumber: String = "",
    val landName: String = "",
    val priorPlanReference: String = "",
    val lots: List<PlanLot> = listOf(PlanLot()),
    val documentFilePaths: List<String> = emptyList(),
) {
    val selectedTotalPerches: Double
        get() = lots.filter { it.isSelected }.sumOf { it.totalPerches }
}

@Serializable
data class StatutoryItem(
    val name: String,
    val status: String = "Pending Verification",
    val remarks: String = "",
)

@Serializable
data class InspectionData(
    val targetInstitution: String = "People's Bank",
    val bankBranch: String = "",
    val valuationPurpose: String = "Mortgage Security",
    val dateOfInspection: String = "",
    val village: String = "",
    val gnDivision: String = "",
    val korale: String = "",
    val divisionalSecretariat: String = "",
    val localAuthority: String = "",
    val assessmentNumber: String = "",
    val statutoryCompliances: List<StatutoryItem> = defaultStatutoryCompliances(),
) {
    companion object {
        fun defaultStatutoryCompliances() = listOf(
            StatutoryItem(name = "Street Lines", status = "Applicable"),
            StatutoryItem(name = "Building Limits", status = "Applicable"),
            StatutoryItem(name = "NBRO Clearance", status = "Pending Verification"),
            StatutoryItem(name = "Other Statutory Restrictions", status = "Not Applicable"),
        )
    }
}

@Serializable
data class LocationData(
    val latitude: Double = 7.2405,
    val longitude: Double = 80.5925,
    val nearestTown: String = "",
    val startingJunction: String = "",
    val accessDirections: String = "",
    val distanceFromTownKm: Double = 2.5,
    val accessRoadWidthFt: Double = 15.0,
    val roadSurface: String = "Carpet",
    val roadCondition: String = "Good",
    val vehicleAccessibility: String = "All Vehicles",
    val utilities: List<String> = listOf(
        "CEB Electricity (Single Phase)",
        "NWSDB Piped Water",
        "Telecommunications & Optical Fiber",
        "Public Bus Route Frontage",
    ),
)

@Serializable
enum class SketchTool {
    LINE,
    RECTANGLE,
    CIRCLE,
    FREEHAND,
    DIMENSION,
    TEXT,
}

@Serializable
data class SketchPoint(
    val x: Float,
    val y: Float,
    val pressure: Float = 1f,
)

@Serializable
data class SketchElement(
    val id: String,
    val tool: SketchTool,
    val points: List<SketchPoint>,
    val textLabel: String = "",
    val strokeWidth: Float = 3f,
    val colorArgb: Long = 0xFF16324F,
)

@Serializable
data class BuildingSketch(
    val isBareLand: Boolean = false,
    val isLandscape: Boolean = true,
    val scaleRatio: Double = 20.0,
    val elements: List<SketchElement> = emptyList(),
)

@Serializable
data class RoomCounter(
    val name: String,
    val count: Int = 0,
)

@Serializable
data class PropertyPhoto(
    val slotName: String,
    val filePath: String = "",
    val description: String = "",
)

@Serializable
data class BuildingSpecification(
    val buildingName: String = "Main Residential Building",
    val roofType: String = "Asbestos on Timber Rafters",
    val wallType: String = "Brick Masonry, Plastered & Painted",
    val floorType: String = "Ceramic Tiled",
    val doorsWindows: String = "Timber Panel & Window Grills",
    val bathFittings: String = "Commode, Wash Basin, Complete",
    val ageYears: Int = 5,
    val structuralCondition: String = "Good",
    val occupancy: String = "Owner Occupied",
    val groundFloorAreaSqFt: Double = 1500.0,
    val upperFloorAreaSqFt: Double = 0.0,
    val roomCounters: List<RoomCounter> = defaultRooms(),
) {
    val totalFloorAreaSqFt: Double
        get() = groundFloorAreaSqFt + upperFloorAreaSqFt

    companion object {
        fun defaultRooms() = listOf(
            RoomCounter("Verandah", 1),
            RoomCounter("Living Room", 1),
            RoomCounter("Dining Room", 1),
            RoomCounter("Kitchen / Pantry", 1),
            RoomCounter("Bedrooms", 3),
            RoomCounter("Bathrooms", 2),
            RoomCounter("Lavatories", 1),
            RoomCounter("Garage / Car Porch", 1),
        )
    }
}

@Serializable
data class BuildingDetails(
    val hasBuilding: Boolean = true,
    val buildings: List<BuildingSpecification> = listOf(BuildingSpecification()),
    val landShape: String = "Regular",
    val landTopography: String = "Flat at road grade",
    val subsoilCondition: String = "Firm, gravelly clay loam",
    val boundaryDemarcations: String = "Parapet wall and barbed wire fence",
    val additionalRemarks: String = "",
    val photographs: List<PropertyPhoto> = defaultPhotos(),
) {
    val totalBuiltUpArea: Double
        get() = if (!hasBuilding) 0.0 else buildings.sumOf { it.totalFloorAreaSqFt }

    companion object {
        fun defaultPhotos() = listOf(
            PropertyPhoto("Front Elevation"),
            PropertyPhoto("Side / Rear View"),
            PropertyPhoto("Interior (Living/Dining)"),
            PropertyPhoto("Boundary / Entrance Road"),
        )
    }
}

@Serializable
data class ComparableProperty(
    val location: String = "",
    val saleDate: String = "",
    val landExtentPerches: Double = 0.0,
    val salePrice: Double = 0.0,
    val ratePerPerch: Double = 0.0,
    val sourceEvidence: String = "Local Registry & Broker Transactions",
    val adjustmentRemarks: String = "Similar access and shape",
)

@Serializable
data class ValuationData(
    val methodology: String = "Combined Approach",
    val adoptedLandRatePerPerch: Double = 350000.0,
    val buildingReplacementCostPerSqFt: Double = 7000.0,
    val depreciationPercentage: Double = 10.0,
    val fsvPercentage: Double = 75.0,
    val customSayValue: Double = 0.0,
    val strengths: String = "Well-demarcated boundaries, motorable carpet road frontage, high residential demand.",
    val weaknesses: String = "Interior access road narrows to 15ft.",
    val opportunities: String = "Proximity to expressway interchange and central commercial node.",
    val constraints: String = "Subject to standard street line and building limit statutory setbacks.",
    val collateralRating: String = "Class A / Prime Collateral",
    val marketEvidence: List<ComparableProperty> = listOf(
        ComparableProperty(
            location = "Within 200m along Main Road",
            saleDate = "Recent 6 Months",
            landExtentPerches = 15.0,
            salePrice = 5550000.0,
            ratePerPerch = 370000.0,
            sourceEvidence = "Direct Inquiry / Local Brokers",
            adjustmentRemarks = "Slightly higher elevation, adopted conservative rate.",
        ),
    ),
) {
    fun computeLandValue(extentPerches: Double): Double = extentPerches * adoptedLandRatePerPerch

    fun computeGrc(totalFloorAreaSqFt: Double, hasBuilding: Boolean): Double =
        if (!hasBuilding) 0.0 else totalFloorAreaSqFt * buildingReplacementCostPerSqFt

    fun computeDepreciation(grc: Double): Double = grc * (depreciationPercentage / 100.0)

    fun computeDepreciatedBuildingValue(grc: Double, depreciation: Double): Double = grc - depreciation

    fun computeTotalMarketValue(
        extentPerches: Double,
        totalFloorAreaSqFt: Double,
        hasBuilding: Boolean,
    ): Double {
        val landVal = computeLandValue(extentPerches)
        if (!hasBuilding) return landVal
        val grc = computeGrc(totalFloorAreaSqFt, true)
        val dep = computeDepreciation(grc)
        return landVal + computeDepreciatedBuildingValue(grc, dep)
    }

    fun computeSayValue(computedMarketValue: Double): Double {
        if (customSayValue > 0) return customSayValue
        return if (computedMarketValue >= 10_000_000.0) {
            (computedMarketValue / 100_000.0).roundToLong() * 100_000.0
        } else {
            (computedMarketValue / 50_000.0).roundToLong() * 50_000.0
        }
    }

    fun computeFsv(sayValue: Double): Double = sayValue * (fsvPercentage / 100.0)
}

@Serializable
data class ValuationProject(
    val id: String,
    val projectName: String = "Untitled Valuation",
    val clientOrBank: String = "People's Bank",
    val status: String = AppConstants.STATUS_DRAFT,
    val createdAtEpochMs: Long = System.currentTimeMillis(),
    val updatedAtEpochMs: Long = System.currentTimeMillis(),
    val targetPageCount: Int = 4,
    val deedData: DeedData = DeedData(),
    val surveyPlanData: SurveyPlanData = SurveyPlanData(),
    val inspectionData: InspectionData = InspectionData(),
    val locationData: LocationData = LocationData(),
    val buildingSketch: BuildingSketch = BuildingSketch(),
    val buildingDetails: BuildingDetails = BuildingDetails(),
    val valuationData: ValuationData = ValuationData(),
    val generatedDocxPath: String = "",
)

data class MonthlyUsageState(
    val monthIdentifier: String = "",
    val usedClicks: Int = 0,
    val maxAllowance: Int = AppConstants.MONTHLY_FREE_REPORT_LIMIT,
    val isPaid: Boolean = false,
) {
    val isLimitReached: Boolean get() = !isPaid && usedClicks >= maxAllowance
    val canAcceptClick: Boolean get() = isPaid || usedClicks < maxAllowance
    val remainingClicks: Int get() = if (isPaid) 999999 else (maxAllowance - usedClicks).coerceIn(0, maxAllowance)
}

@Serializable
data class ReportAnalysisResult(
    val reportFormat: String = "Chartered 10-Point Schedule & Executive Appraisal Table",
    val reportStyle: String = "Formal Chartered Practitioner Terminology & LKR Rounding",
    val reportType: String = "Real Estate Mortgage Collateral & Bank Panel Valuation",
    val detailedBlueprint: String = "",
)
