package com.propertyvaluerpro.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.LockClock
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.WarningAmber
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.CurrencyFormatter
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.ui.components.InterstitialAdDialog
import com.propertyvaluerpro.app.ui.components.LiveCalculationCard
import com.propertyvaluerpro.app.ui.components.DossierPreviewSheet
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState

@Composable
fun FinalReviewScreen(
    uiState: AppUiState,
    onUpdatePageCount: (Int) -> Unit,
    onGenerateDocx: () -> Unit,
    onOpenLimitDialog: () -> Unit,
    onBack: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val project = uiState.activeProject ?: ValuationProject(id = "temp")
    val profile = uiState.profile
    val usage = uiState.usageState

    var showInterstitial by remember { mutableStateOf(false) }
    var showStyleSpec by remember { mutableStateOf(false) }

    if (showStyleSpec) {
        DossierPreviewSheet(
            markdown = profile.reportStyleSpecMd,
            title = "Learned Report Style Spec (.md)",
            onDismiss = { showStyleSpec = false },
        )
    }

    if (showInterstitial) {
        InterstitialAdDialog(
            adProvider = uiState.adProvider,
            onAdClosed = {
                showInterstitial = false
                onGenerateDocx()
            },
        )
    }

    data class AuditRow(val step: Int, val title: String, val summary: String, val isComplete: Boolean)

    val auditRows = listOf(
        AuditRow(
            step = 2,
            title = "Valuer Profile & Chambers",
            summary = if (profile.isConfigured) "${profile.valuerName} (${profile.registrationNumber})" else "Profile credentials incomplete",
            isComplete = profile.isConfigured,
        ),
        AuditRow(
            step = 3,
            title = "Title Deed & Devolution",
            summary = if (project.deedData.deedNumber.isNotBlank()) "Deed No. ${project.deedData.deedNumber} • ${project.deedData.vendeeName}" else "Manual or AI deed details pending",
            isComplete = project.deedData.deedNumber.isNotBlank(),
        ),
        AuditRow(
            step = 4,
            title = "Cadastral Survey Plan",
            summary = "Plan ${project.surveyPlanData.planNumber.ifBlank { "Pending" }} • ${"%.2f".format(project.surveyPlanData.selectedTotalPerches)} Perches",
            isComplete = project.surveyPlanData.planNumber.isNotBlank() && project.surveyPlanData.selectedTotalPerches > 0,
        ),
        AuditRow(
            step = 5,
            title = "Inspection & Statutory",
            summary = "${project.inspectionData.targetInstitution} (${project.inspectionData.valuationPurpose})",
            isComplete = project.inspectionData.targetInstitution.isNotBlank(),
        ),
        AuditRow(
            step = 6,
            title = "Situation & GIS Location",
            summary = "${project.locationData.nearestTown.ifBlank { "Nearest town pending" }} • ${"%.4f".format(project.locationData.latitude)}°N",
            isComplete = project.locationData.nearestTown.isNotBlank(),
        ),
        AuditRow(
            step = 7,
            title = "A3 Building Sketch",
            summary = if (project.buildingSketch.isBareLand) "Bare Land Mode (No Building)" else "${project.buildingSketch.elements.size} CAD vector element(s)",
            isComplete = project.buildingSketch.isBareLand || project.buildingSketch.elements.isNotEmpty(),
        ),
        AuditRow(
            step = 8,
            title = "Building Specs & Photos",
            summary = if (!project.buildingDetails.hasBuilding) "Bare Land Parcel" else "${project.buildingDetails.totalBuiltUpArea.toInt()} sq.ft. • ${project.buildingDetails.photographs.count { it.filePath.isNotBlank() }}/4 photos",
            isComplete = true,
        ),
        AuditRow(
            step = 9,
            title = "Valuation Math & SWOC",
            summary = "Land @ ${CurrencyFormatter.formatLkr(project.valuationData.adoptedLandRatePerPerch)}/P • ${project.valuationData.collateralRating}",
            isComplete = project.valuationData.adoptedLandRatePerPerch > 0,
        ),
    )

    ResponsiveWorkflowScaffold(
        currentStep = 10,
        title = "Final Review & Generate",
        screens3To10Frozen = uiState.screens3To10Frozen,
        showBottomNav = false,
        showAdBanner = true,
        adsEnabled = uiState.adsEnabled,
        isPaidTier = usage.isPaid,
        adProvider = uiState.adProvider,
        onStepSelected = onNavigateToStep,
        onOpenSettings = onOpenSettings,
        onBack = onBack,
        snackbarMessage = uiState.snackbarMessage,
        snackbarIsError = uiState.snackbarIsError,
        onSnackbarDismissed = onSnackbarDismissed,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
        ) {
            // Monthly Quota Banner
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (usage.isLimitReached) AppColors.Error.copy(alpha = 0.08f) else AppColors.PrimaryNavy)
                    .border(
                        1.dp,
                        if (usage.isLimitReached) AppColors.Error else AppColors.PrimaryNavyBorder,
                        RoundedCornerShape(12.dp),
                    )
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(
                    imageVector = if (usage.isLimitReached) Icons.Default.LockClock else Icons.Default.Verified,
                    contentDescription = null,
                    tint = if (usage.isLimitReached) AppColors.Error else AppColors.AntiqueGold,
                    modifier = Modifier.size(26.dp),
                )
                Spacer(Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = if (usage.isPaid) "Paid Commercial License Active" else "Free Monthly Quota (${usage.monthIdentifier})",
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.5.sp,
                        color = if (usage.isLimitReached) AppColors.Error else Color.White,
                    )
                    Text(
                        text = if (usage.isPaid) {
                            "Unlimited Microsoft Word (.docx) report generations enabled."
                        } else {
                            "${usage.usedClicks} of ${usage.maxAllowance} reports generated this month (${usage.remainingClicks} remaining)."
                        },
                        fontSize = 12.sp,
                        color = if (usage.isLimitReached) AppColors.MainText else Color.White.copy(alpha = 0.8f),
                    )
                }
            }

            Spacer(Modifier.height(14.dp))

            // Mandatory Page Budget Selector
            SectionCard(
                title = "Report Page Budget (Mandatory)",
                subtitle = "Select the target length for the compiled Microsoft Word (.docx) valuation dossier.",
                isMandatory = true,
            ) {
                val options = listOf(
                    3 to ("3 Pages — Concise Summary" to "Compact bank executive layout for straightforward residential / bare land plots."),
                    4 to ("4 Pages — Standard Bank Panel" to "Balanced Chartered Valuer format with full schedule, SWOC, and market evidence."),
                    5 to ("5 Pages — Comprehensive Full Report" to "Extended institutional appraisal with detailed methodology, annexures, and photo register."),
                )
                options.forEach { (pages, pair) ->
                    val isSel = project.targetPageCount == pages
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (isSel) AppColors.PrimaryActionTeal.copy(alpha = 0.08f) else AppColors.SurfaceContainerLow)
                            .border(
                                1.2.dp,
                                if (isSel) AppColors.PrimaryActionTeal else AppColors.Borders,
                                RoundedCornerShape(10.dp),
                            )
                            .clickable { onUpdatePageCount(pages) }
                            .padding(10.dp)
                            .testTag("page_budget_$pages"),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(
                            selected = isSel,
                            onClick = { onUpdatePageCount(pages) },
                            colors = RadioButtonDefaults.colors(selectedColor = AppColors.PrimaryActionTeal),
                        )
                        Column(modifier = Modifier.weight(1f)) {
                            Text(pair.first, fontWeight = FontWeight.Bold, fontSize = 13.5.sp, color = AppColors.PrimaryNavy)
                            Text(pair.second, fontSize = 11.5.sp, color = AppColors.SecondaryText)
                        }
                    }
                }
            }

            // Live Valuation Summary
            LiveCalculationCard(project = project)

            Spacer(Modifier.height(14.dp))

            // 8-Step Pre-Generation Audit Checklist
            SectionCard(
                title = "Pre-Generation Audit Checklist (Steps 2–9)",
                subtitle = "Verify every section before compiling the editable .docx report.",
            ) {
                auditRows.forEachIndexed { idx, row ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(
                            modifier = Modifier
                                .size(28.dp)
                                .clip(CircleShape)
                                .background(if (row.isComplete) AppColors.Success.copy(alpha = 0.14f) else AppColors.Warning.copy(alpha = 0.14f)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(
                                imageVector = if (row.isComplete) Icons.Default.CheckCircle else Icons.Default.WarningAmber,
                                contentDescription = null,
                                tint = if (row.isComplete) AppColors.Success else AppColors.Warning,
                                modifier = Modifier.size(16.dp),
                            )
                        }
                        Spacer(Modifier.width(10.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Step ${row.step}: ${row.title}", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = AppColors.PrimaryNavy)
                            Text(row.summary, fontSize = 11.5.sp, color = AppColors.SecondaryText)
                        }
                        TextButton(onClick = { onNavigateToStep(row.step) }) {
                            Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(15.dp))
                            Spacer(Modifier.width(4.dp))
                            Text("Edit", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    if (idx < auditRows.lastIndex) HorizontalDivider(color = AppColors.Borders)
                }
            }

            // Primary Generate Report CTA
            if (uiState.isGeneratingDocx) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(AppColors.PrimaryNavy)
                        .padding(20.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    CircularProgressIndicator(color = AppColors.AntiqueGold, strokeWidth = 3.dp)
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = uiState.generationProgress.ifBlank { "Compiling OpenXML Word (.docx) Dossier..." },
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.5.sp,
                    )
                }
            } else {
                Button(
                    onClick = {
                        if (usage.isLimitReached) {
                            onOpenLimitDialog()
                        } else if (uiState.adsEnabled && !usage.isPaid) {
                            showInterstitial = true
                        } else {
                            onGenerateDocx()
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(54.dp)
                        .testTag("generate_report_button"),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (usage.isLimitReached) AppColors.Error else AppColors.PrimaryActionTeal,
                        contentColor = Color.White,
                    ),
                ) {
                    Icon(
                        imageVector = if (usage.isLimitReached) Icons.Default.LockClock else Icons.Default.Description,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                    )
                    Spacer(Modifier.width(10.dp))
                    Text(
                        text = if (usage.isLimitReached) "MONTHLY LIMIT REACHED — UPGRADE" else "GENERATE EDITABLE WORD (.DOCX) REPORT",
                        fontFamily = ManropeFontFamily,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 13.5.sp,
                    )
                }
            }

            Spacer(Modifier.height(20.dp))
        }
    }
}
