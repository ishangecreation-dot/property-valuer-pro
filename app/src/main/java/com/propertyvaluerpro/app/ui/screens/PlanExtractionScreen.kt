package com.propertyvaluerpro.app.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.propertyvaluerpro.app.data.models.PlanLot
import com.propertyvaluerpro.app.data.models.SurveyPlanData
import com.propertyvaluerpro.app.ui.components.LabeledTextField
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import java.io.File

@Composable
fun PlanExtractionScreen(
    uiState: AppUiState,
    onSavePlan: (SurveyPlanData) -> Unit,
    onExtractPlanWithAi: (List<String>, (SurveyPlanData) -> Unit) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val context = LocalContext.current
    val initial = uiState.activeProject?.surveyPlanData ?: SurveyPlanData()

    var planNumber by remember(initial) { mutableStateOf(initial.planNumber) }
    var surveyDate by remember(initial) { mutableStateOf(initial.surveyDate) }
    var surveyorName by remember(initial) { mutableStateOf(initial.surveyorName) }
    var surveyorReg by remember(initial) { mutableStateOf(initial.surveyorRegistrationNumber) }
    var landName by remember(initial) { mutableStateOf(initial.landName) }
    var priorPlan by remember(initial) { mutableStateOf(initial.priorPlanReference) }
    var lots by remember(initial) { mutableStateOf(initial.lots.ifEmpty { listOf(PlanLot()) }) }
    var filePaths by remember(initial) { mutableStateOf(initial.documentFilePaths) }
    var pendingCameraFile by remember { mutableStateOf<File?>(null) }

    fun buildPlan() = SurveyPlanData(
        planNumber = planNumber.trim(),
        surveyDate = surveyDate.trim(),
        surveyorName = surveyorName.trim(),
        surveyorRegistrationNumber = surveyorReg.trim(),
        landName = landName.trim(),
        priorPlanReference = priorPlan.trim(),
        lots = lots,
        documentFilePaths = filePaths,
    )

    val pdfPicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
        uri?.let { filePaths = (filePaths + it.toString()).distinct() }
    }
    val photoPicker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri: Uri? ->
        uri?.let { filePaths = (filePaths + it.toString()).distinct() }
    }
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        val f = pendingCameraFile
        if (success && f != null && f.exists()) filePaths = (filePaths + f.absolutePath).distinct()
    }
    val cameraPerm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            val (file, uri) = createCaptureFile(context, "plan")
            pendingCameraFile = file
            cameraLauncher.launch(uri)
        }
    }

    val combinedPerches = lots.filter { it.isSelected }.sumOf { it.totalPerches }

    ResponsiveWorkflowScaffold(
        currentStep = 4,
        title = "Survey Plan & Lot Selection",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = {
            onSavePlan(buildPlan())
            onNavigateToStep(it)
        },
        onOpenSettings = onOpenSettings,
        onBack = {
            onSavePlan(buildPlan())
            onBack()
        },
        onNext = {
            onSavePlan(buildPlan())
            onNext()
        },
        nextLabel = "Save & Continue to Purpose",
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
                title = "Survey Plan Document",
                subtitle = "Upload Plan PDF, plan images, or photograph with back camera.",
                isMandatory = true,
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(onClick = { pdfPicker.launch(arrayOf("application/pdf")) }, modifier = Modifier.weight(1f).height(44.dp), shape = RoundedCornerShape(8.dp)) {
                        Icon(Icons.Default.PictureAsPdf, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("PDF", fontSize = 12.sp)
                    }
                    OutlinedButton(
                        onClick = { photoPicker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)) },
                        modifier = Modifier.weight(1f).height(44.dp),
                        shape = RoundedCornerShape(8.dp),
                    ) {
                        Icon(Icons.Default.PhotoLibrary, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Images", fontSize = 12.sp)
                    }
                    Button(
                        onClick = {
                            if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                                val (f, u) = createCaptureFile(context, "plan")
                                pendingCameraFile = f
                                cameraLauncher.launch(u)
                            } else {
                                cameraPerm.launch(Manifest.permission.CAMERA)
                            }
                        },
                        modifier = Modifier.weight(1f).height(44.dp),
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.ProfessionalBlue),
                    ) {
                        Icon(Icons.Default.CameraAlt, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Camera", fontSize = 12.sp)
                    }
                }
                if (filePaths.isNotEmpty()) {
                    Spacer(Modifier.height(10.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(AppColors.SurfaceContainerLow).padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = AppColors.Success, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("${filePaths.size} survey plan file(s) attached", fontSize = 13.sp, modifier = Modifier.weight(1f))
                        TextButton(onClick = { filePaths = emptyList() }) { Text("Clear", color = AppColors.Error) }
                    }
                }
                Spacer(Modifier.height(12.dp))
                Button(
                    onClick = {
                        onExtractPlanWithAi(filePaths) { extracted ->
                            planNumber = extracted.planNumber
                            surveyDate = extracted.surveyDate
                            surveyorName = extracted.surveyorName
                            surveyorReg = extracted.surveyorRegistrationNumber
                            landName = extracted.landName
                            priorPlan = extracted.priorPlanReference
                            lots = extracted.lots
                        }
                    },
                    enabled = !uiState.isExtracting,
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                ) {
                    if (uiState.isExtracting) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
                        Spacer(Modifier.width(8.dp))
                        Text(uiState.extractionStatus.ifBlank { "Analyzing..." }, fontSize = 13.sp)
                    } else {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("SUBMIT / EXTRACT SURVEY PLAN", fontWeight = FontWeight.Bold)
                    }
                }
            }

            SectionCard(title = "Survey Plan Particulars", subtitle = "Cadastral reference for report certification.") {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Plan Number", planNumber, { planNumber = it }, "e.g. 2418/SP", modifier = Modifier.weight(1f))
                    LabeledTextField("Survey Date", surveyDate, { surveyDate = it }, "YYYY-MM-DD", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Licensed Surveyor", surveyorName, { surveyorName = it }, "e.g. Gamini Ratnayake", modifier = Modifier.weight(1f))
                    LabeledTextField("Surveyor Reg. No.", surveyorReg, { surveyorReg = it }, "e.g. LS/1842", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Name of the Land", landName, { landName = it }, "e.g. Kotakumbura (Part)", modifier = Modifier.weight(1f))
                    LabeledTextField("Prior Plan Ref.", priorPlan, { priorPlan = it }, "e.g. Plan No. 1102", modifier = Modifier.weight(1f))
                }
            }

            SectionCard(
                title = "Exact Lot Selection & Boundaries",
                subtitle = "Select which lots to include in the valuation computation.",
                trailing = {
                    TextButton(onClick = { lots = lots + PlanLot(lotNumber = "${lots.size + 1}") }) {
                        Icon(Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                        Text("Add Lot", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    }
                },
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 14.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(AppColors.PrimaryNavy)
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("COMBINED EVALUATED EXTENT", color = Color.White.copy(alpha = 0.75f), fontSize = 11.sp, fontWeight = FontWeight.Bold)
                        Text("Selected lots aggregated automatically", color = Color.White.copy(alpha = 0.55f), fontSize = 11.sp)
                    }
                    Text(
                        text = "${"%.2f".format(combinedPerches)} Perches",
                        fontFamily = JetBrainsMonoFontFamily,
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.AntiqueGold,
                    )
                }

                lots.forEachIndexed { idx, lot ->
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 14.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (lot.isSelected) Color.White else AppColors.SurfaceContainerLow)
                            .border(
                                width = if (lot.isSelected) 1.5.dp else 1.dp,
                                color = if (lot.isSelected) AppColors.PrimaryActionTeal else AppColors.Borders,
                                shape = RoundedCornerShape(8.dp),
                            )
                            .padding(12.dp),
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(
                                checked = lot.isSelected,
                                onCheckedChange = { checked ->
                                    lots = lots.toMutableList().apply { this[idx] = lot.copy(isSelected = checked) }
                                },
                                colors = CheckboxDefaults.colors(checkedColor = AppColors.PrimaryActionTeal),
                            )
                            Text(
                                text = "Lot No. ${lot.lotNumber}",
                                fontFamily = ManropeFontFamily,
                                fontSize = 15.5.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (lot.isSelected) AppColors.PrimaryNavy else AppColors.SecondaryText,
                                modifier = Modifier.weight(1f),
                            )
                            Text(
                                text = "${"%.2f".format(lot.totalPerches)} P",
                                fontFamily = JetBrainsMonoFontFamily,
                                fontWeight = FontWeight.Bold,
                                fontSize = 13.sp,
                                color = AppColors.PrimaryNavy,
                            )
                        }
                        HorizontalDivider(color = AppColors.Borders, modifier = Modifier.padding(vertical = 8.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            LabeledTextField(
                                label = "Acres (A)",
                                value = lot.acres.toString(),
                                onValueChange = { v -> lots = lots.toMutableList().apply { this[idx] = lot.copy(acres = v.toIntOrNull() ?: 0) } },
                                keyboardType = KeyboardType.Number,
                                modifier = Modifier.weight(1f),
                            )
                            LabeledTextField(
                                label = "Roods (R)",
                                value = lot.roods.toString(),
                                onValueChange = { v -> lots = lots.toMutableList().apply { this[idx] = lot.copy(roods = v.toIntOrNull() ?: 0) } },
                                keyboardType = KeyboardType.Number,
                                modifier = Modifier.weight(1f),
                            )
                            LabeledTextField(
                                label = "Perches (P)",
                                value = if (lot.perches == 0.0) "" else lot.perches.toString(),
                                onValueChange = { v -> lots = lots.toMutableList().apply { this[idx] = lot.copy(perches = v.toDoubleOrNull() ?: 0.0) } },
                                hint = "0.0",
                                keyboardType = KeyboardType.Decimal,
                                modifier = Modifier.weight(1f),
                            )
                        }
                        LabeledTextField("North Boundary", lot.northBoundary, { v -> lots = lots.toMutableList().apply { this[idx] = lot.copy(northBoundary = v) } }, "e.g. Lot 2 of the same land")
                        LabeledTextField("East Boundary", lot.eastBoundary, { v -> lots = lots.toMutableList().apply { this[idx] = lot.copy(eastBoundary = v) } }, "e.g. Access Road (15ft Wide)")
                        LabeledTextField("South Boundary", lot.southBoundary, { v -> lots = lots.toMutableList().apply { this[idx] = lot.copy(southBoundary = v) } }, "e.g. Adjoining land")
                        LabeledTextField("West Boundary", lot.westBoundary, { v -> lots = lots.toMutableList().apply { this[idx] = lot.copy(westBoundary = v) } }, "e.g. Drainage stream")
                    }
                }
            }
        }
    }
}
