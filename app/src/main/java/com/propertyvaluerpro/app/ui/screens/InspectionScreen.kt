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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.InspectionData
import com.propertyvaluerpro.app.ui.components.LabeledTextField
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.components.SelectableChipGroup
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun InspectionScreen(
    uiState: AppUiState,
    onSaveInspection: (InspectionData) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val initial = uiState.activeProject?.inspectionData ?: InspectionData()
    val today = remember { SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date()) }

    var bank by remember(initial) { mutableStateOf(initial.targetInstitution) }
    var branch by remember(initial) { mutableStateOf(initial.bankBranch) }
    var purpose by remember(initial) { mutableStateOf(initial.valuationPurpose) }
    var inspectionDate by remember(initial) { mutableStateOf(initial.dateOfInspection.ifBlank { today }) }
    var village by remember(initial) { mutableStateOf(initial.village) }
    var gnDivision by remember(initial) { mutableStateOf(initial.gnDivision) }
    var korale by remember(initial) { mutableStateOf(initial.korale) }
    var dsDivision by remember(initial) { mutableStateOf(initial.divisionalSecretariat) }
    var localAuthority by remember(initial) { mutableStateOf(initial.localAuthority) }
    var assessmentNo by remember(initial) { mutableStateOf(initial.assessmentNumber) }
    var compliances by remember(initial) {
        mutableStateOf(initial.statutoryCompliances.ifEmpty { InspectionData.defaultStatutoryCompliances() })
    }

    val bankOptions = listOf(
        "People's Bank",
        "Bank of Ceylon",
        "Commercial Bank",
        "Sampath Bank",
        "Hatton National Bank",
        "SMIB",
        "National Savings Bank",
        "Seylan Bank",
        "DFCC Bank",
        "Nations Trust Bank",
    )
    val purposeOptions = listOf(
        "Mortgage Security",
        "Bank Guarantee",
        "Credit Facility",
        "Balance Sheet / Accounting",
        "Auction Reserve Price",
        "Purchase Decision",
    )
    val statusOptions = listOf("Applicable", "Not Applicable", "Obtained", "Not Obtained", "Pending Verification")

    fun buildInspection() = InspectionData(
        targetInstitution = bank,
        bankBranch = branch.trim(),
        valuationPurpose = purpose,
        dateOfInspection = inspectionDate.trim(),
        village = village.trim(),
        gnDivision = gnDivision.trim(),
        korale = korale.trim(),
        divisionalSecretariat = dsDivision.trim(),
        localAuthority = localAuthority.trim(),
        assessmentNumber = assessmentNo.trim(),
        statutoryCompliances = compliances,
    )

    ResponsiveWorkflowScaffold(
        currentStep = 5,
        title = "Purpose & Statutory Compliance",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = {
            onSaveInspection(buildInspection())
            onNavigateToStep(it)
        },
        onOpenSettings = onOpenSettings,
        onBack = {
            onSaveInspection(buildInspection())
            onBack()
        },
        onNext = {
            onSaveInspection(buildInspection())
            onNext()
        },
        nextLabel = "Save & Continue to Location",
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
            SectionCard(
                title = "Target Institution & Facility Purpose",
                subtitle = "Specify the lending bank and loan facility context.",
                isMandatory = true,
            ) {
                SelectableChipGroup(
                    label = "Select Lending Bank / Financial Institution",
                    options = bankOptions,
                    selected = bank,
                    selectedColor = AppColors.PrimaryNavy,
                    onSelected = { bank = it },
                )
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Bank Branch", branch, { branch = it }, "e.g. Pilimathalawa", modifier = Modifier.weight(1f))
                    LabeledTextField("Inspection Date", inspectionDate, { inspectionDate = it }, "YYYY-MM-DD", modifier = Modifier.weight(1f))
                }
                SelectableChipGroup(
                    label = "Valuation Purpose",
                    options = purposeOptions,
                    selected = purpose,
                    selectedColor = AppColors.PrimaryActionTeal,
                    onSelected = { purpose = it },
                )
            }

            SectionCard(
                title = "Administrative & Statutory Location",
                subtitle = "Official divisions according to statutory valuation reporting standards.",
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Village / Locality", village, { village = it }, "e.g. Handessa", modifier = Modifier.weight(1f))
                    LabeledTextField("GN Division", gnDivision, { gnDivision = it }, "e.g. Handessa South", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Korale", korale, { korale = it }, "e.g. Medapalatha", modifier = Modifier.weight(1f))
                    LabeledTextField("Divisional Secretariat", dsDivision, { dsDivision = it }, "e.g. Udunuwara", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Local Authority Limits", localAuthority, { localAuthority = it }, "Pradeshiya Sabha / MC", modifier = Modifier.weight(1f))
                    LabeledTextField("Assessment Number", assessmentNo, { assessmentNo = it }, "e.g. No. 84", modifier = Modifier.weight(1f))
                }
            }

            SectionCard(
                title = "Statutory Compliance Matrix",
                subtitle = "Verify street lines, building limits, and NBRO clearance status.",
            ) {
                compliances.forEachIndexed { idx, item ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 12.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(AppColors.SurfaceContainerLow)
                            .border(1.dp, AppColors.Borders, RoundedCornerShape(8.dp))
                            .padding(12.dp),
                    ) {
                        SelectableChipGroup(
                            label = item.name,
                            options = statusOptions,
                            selected = item.status,
                            selectedColor = when (item.status) {
                                "Obtained" -> AppColors.Success
                                "Pending Verification" -> AppColors.Warning
                                else -> AppColors.PrimaryNavy
                            },
                            onSelected = { newStatus ->
                                compliances = compliances.toMutableList().apply { this[idx] = item.copy(status = newStatus) }
                            },
                        )
                        OutlinedTextField(
                            value = item.remarks,
                            onValueChange = { r ->
                                compliances = compliances.toMutableList().apply { this[idx] = item.copy(remarks = r) }
                            },
                            placeholder = { Text("Custom remarks (Ref No, clearance date)", fontSize = 12.sp) },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                }
            }
        }
    }
}
