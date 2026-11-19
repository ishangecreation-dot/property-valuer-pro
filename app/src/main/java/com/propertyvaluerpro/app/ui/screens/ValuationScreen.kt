package com.propertyvaluerpro.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.ComparableProperty
import com.propertyvaluerpro.app.data.models.CurrencyFormatter
import com.propertyvaluerpro.app.data.models.ValuationData
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.ui.components.LabeledTextField
import com.propertyvaluerpro.app.ui.components.LiveCalculationCard
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.components.SelectableChipGroup
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState

@Composable
fun ValuationScreen(
    uiState: AppUiState,
    onSaveValuation: (ValuationData) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val activeProject = uiState.activeProject ?: ValuationProject(id = "temp")
    val initial = activeProject.valuationData

    var methodology by remember(initial) { mutableStateOf(initial.methodology) }
    var landRateText by remember(initial) { mutableStateOf(initial.adoptedLandRatePerPerch.toLong().toString()) }
    var grcRateText by remember(initial) { mutableStateOf(initial.buildingReplacementCostPerSqFt.toLong().toString()) }
    var depText by remember(initial) { mutableStateOf(initial.depreciationPercentage.toString()) }
    var fsvText by remember(initial) { mutableStateOf(initial.fsvPercentage.toString()) }
    var customSayText by remember(initial) {
        mutableStateOf(if (initial.customSayValue > 0) initial.customSayValue.toLong().toString() else "")
    }
    var strengths by remember(initial) { mutableStateOf(initial.strengths) }
    var weaknesses by remember(initial) { mutableStateOf(initial.weaknesses) }
    var opportunities by remember(initial) { mutableStateOf(initial.opportunities) }
    var constraints by remember(initial) { mutableStateOf(initial.constraints) }
    var collateralRating by remember(initial) { mutableStateOf(initial.collateralRating) }
    var comparables by remember(initial) { mutableStateOf(initial.marketEvidence) }

    var showAddComparableDialog by remember { mutableStateOf(false) }

    val methodologyOptions = listOf(
        "Combined Approach",
        "Contractor's Method (Cost Approach)",
        "Market Comparison Approach",
        "Investment / Income Method",
    )
    val ratingOptions = listOf(
        "Class A / Prime Collateral",
        "Class B / Good Collateral",
        "Class C / Average Marketability",
        "Class D / Restricted Security",
    )

    fun buildValuationData() = ValuationData(
        methodology = methodology,
        adoptedLandRatePerPerch = landRateText.replace(",", "").toDoubleOrNull() ?: initial.adoptedLandRatePerPerch,
        buildingReplacementCostPerSqFt = grcRateText.replace(",", "").toDoubleOrNull() ?: initial.buildingReplacementCostPerSqFt,
        depreciationPercentage = (depText.toDoubleOrNull() ?: initial.depreciationPercentage).coerceIn(0.0, 95.0),
        fsvPercentage = (fsvText.toDoubleOrNull() ?: initial.fsvPercentage).coerceIn(40.0, 100.0),
        customSayValue = customSayText.replace(",", "").toDoubleOrNull() ?: 0.0,
        strengths = strengths.trim(),
        weaknesses = weaknesses.trim(),
        opportunities = opportunities.trim(),
        constraints = constraints.trim(),
        collateralRating = collateralRating,
        marketEvidence = comparables,
    )

    val liveProject = activeProject.copy(valuationData = buildValuationData())

    if (showAddComparableDialog) {
        AddComparableDialog(
            onAdd = { comp ->
                comparables = comparables + comp
                showAddComparableDialog = false
            },
            onDismiss = { showAddComparableDialog = false },
        )
    }

    ResponsiveWorkflowScaffold(
        currentStep = 9,
        title = "Valuation Engine & SWOC",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = { step ->
            onSaveValuation(buildValuationData())
            onNavigateToStep(step)
        },
        onOpenSettings = onOpenSettings,
        onBack = {
            onSaveValuation(buildValuationData())
            onBack()
        },
        onNext = {
            onSaveValuation(buildValuationData())
            onNext()
        },
        nextLabel = "Save & Final Review",
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
            // Live Calculation Card updates on every keystroke
            LiveCalculationCard(project = liveProject)

            Spacer(Modifier.height(14.dp))

            SectionCard(
                title = "Valuation Parameters & Rates",
                subtitle = "Updates Land Value, GRC, Depreciation, SAY Market Value, and FSV in real time.",
                isMandatory = true,
            ) {
                SelectableChipGroup(
                    label = "Valuation Methodology",
                    options = methodologyOptions,
                    selected = methodology,
                    onSelected = { methodology = it },
                )
                LabeledTextField(
                    label = "Adopted Land Rate per Perch (LKR)",
                    value = landRateText,
                    onValueChange = { landRateText = it },
                    hint = "e.g., 350000",
                    isRequired = true,
                    keyboardType = KeyboardType.Number,
                    testTag = "land_rate_input",
                )
                if (activeProject.buildingDetails.hasBuilding && !activeProject.buildingSketch.isBareLand) {
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        LabeledTextField(
                            label = "Replacement Cost / sq.ft. (LKR)",
                            value = grcRateText,
                            onValueChange = { grcRateText = it },
                            hint = "7000",
                            keyboardType = KeyboardType.Number,
                            testTag = "grc_rate_input",
                            modifier = Modifier.weight(1.2f),
                        )
                        LabeledTextField(
                            label = "Depreciation (%)",
                            value = depText,
                            onValueChange = { depText = it },
                            hint = "10",
                            keyboardType = KeyboardType.Decimal,
                            testTag = "depreciation_input",
                            modifier = Modifier.weight(0.8f),
                        )
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField(
                        label = "Forced Sale Value (%)",
                        value = fsvText,
                        onValueChange = { fsvText = it },
                        hint = "75",
                        keyboardType = KeyboardType.Decimal,
                        testTag = "fsv_percent_input",
                        modifier = Modifier.weight(0.9f),
                    )
                    LabeledTextField(
                        label = "Override SAY Value (Optional)",
                        value = customSayText,
                        onValueChange = { customSayText = it },
                        hint = "Auto-rounded if blank",
                        keyboardType = KeyboardType.Number,
                        modifier = Modifier.weight(1.1f),
                    )
                }
            }

            SectionCard(
                title = "Market Evidence & Comparable Sales",
                subtitle = "Comparable land transactions supporting the adopted rate per perch.",
                trailing = {
                    OutlinedButton(
                        onClick = { showAddComparableDialog = true },
                        modifier = Modifier.testTag("add_comparable_button"),
                        shape = RoundedCornerShape(8.dp),
                    ) {
                        Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Add", fontSize = 12.sp, fontWeight = FontWeight.Bold)
                    }
                },
            ) {
                if (comparables.isEmpty()) {
                    Text("No comparable sales recorded yet.", fontSize = 12.5.sp, color = AppColors.SecondaryText)
                } else {
                    comparables.forEachIndexed { idx, comp ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = 8.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(AppColors.SurfaceContainerLow)
                                .border(1.dp, AppColors.Borders, RoundedCornerShape(8.dp))
                                .padding(10.dp),
                            verticalAlignment = Alignment.Top,
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(comp.location.ifBlank { "Comparable #${idx + 1}" }, fontWeight = FontWeight.Bold, fontSize = 13.sp, color = AppColors.PrimaryNavy)
                                Text(
                                    text = "${"%.2f".format(comp.landExtentPerches)} P • ${CurrencyFormatter.formatLkr(comp.ratePerPerch)}/P • ${comp.saleDate}",
                                    fontFamily = JetBrainsMonoFontFamily,
                                    fontSize = 11.5.sp,
                                    color = AppColors.PrimaryActionTeal,
                                )
                                if (comp.adjustmentRemarks.isNotBlank()) {
                                    Text(comp.adjustmentRemarks, fontSize = 11.5.sp, color = AppColors.SecondaryText)
                                }
                            }
                            IconButton(
                                onClick = {
                                    comparables = comparables.toMutableList().also { it.removeAt(idx) }
                                },
                                modifier = Modifier.size(32.dp),
                            ) {
                                Icon(Icons.Default.DeleteOutline, contentDescription = "Remove Comparable", tint = AppColors.Error, modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                }
            }

            SectionCard(
                title = "SWOC Analysis & Bank Collateral Rating",
                subtitle = "Strengths, Weaknesses, Opportunities, and Constraints for credit committee review.",
            ) {
                SelectableChipGroup(
                    label = "Collateral Security Rating",
                    options = ratingOptions,
                    selected = collateralRating,
                    selectedColor = AppColors.PrimaryActionTeal,
                    onSelected = { collateralRating = it },
                )
                LabeledTextField("Strengths", strengths, { strengths = it }, minLines = 2, maxLines = 4)
                LabeledTextField("Weaknesses", weaknesses, { weaknesses = it }, minLines = 2, maxLines = 4)
                LabeledTextField("Opportunities", opportunities, { opportunities = it }, minLines = 2, maxLines = 4)
                LabeledTextField("Constraints / Risks", constraints, { constraints = it }, minLines = 2, maxLines = 4)
            }

            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun AddComparableDialog(
    onAdd: (ComparableProperty) -> Unit,
    onDismiss: () -> Unit,
) {
    var location by remember { mutableStateOf("") }
    var saleDate by remember { mutableStateOf("Recent 6 Months") }
    var extent by remember { mutableStateOf("15.0") }
    var rate by remember { mutableStateOf("360000") }
    var remarks by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Add Comparable Property", fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy) },
        text = {
            Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
                LabeledTextField("Location / Distance", location, { location = it }, "e.g., 150m along Main Road", isRequired = true)
                LabeledTextField("Sale Date / Period", saleDate, { saleDate = it }, "e.g., Jan 2025")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    LabeledTextField("Extent (P)", extent, { extent = it }, "15.0", keyboardType = KeyboardType.Decimal, modifier = Modifier.weight(1f))
                    LabeledTextField("Rate/P (LKR)", rate, { rate = it }, "360000", keyboardType = KeyboardType.Number, modifier = Modifier.weight(1.2f))
                }
                LabeledTextField("Adjustment Remarks", remarks, { remarks = it }, "Similar road access & elevation", minLines = 2, maxLines = 3)
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val ext = extent.toDoubleOrNull() ?: 10.0
                    val rt = rate.replace(",", "").toDoubleOrNull() ?: 0.0
                    onAdd(
                        ComparableProperty(
                            location = location.trim().ifBlank { "Nearby Comparable Lot" },
                            saleDate = saleDate.trim(),
                            landExtentPerches = ext,
                            salePrice = ext * rt,
                            ratePerPerch = rt,
                            adjustmentRemarks = remarks.trim(),
                        ),
                    )
                },
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
            ) { Text("Add Evidence") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
    )
}
