package com.propertyvaluerpro.app.ui.screens

import android.Manifest
import android.content.Context
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
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudUpload
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.propertyvaluerpro.app.data.models.DeedData
import com.propertyvaluerpro.app.ui.components.LabeledTextField
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import java.io.File

@Composable
fun DeedExtractionScreen(
    uiState: AppUiState,
    onSaveDeed: (DeedData) -> Unit,
    onExtractWithAi: (List<String>, (DeedData) -> Unit) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val context = LocalContext.current
    val initial = uiState.activeProject?.deedData ?: DeedData()

    var deedNumber by remember(initial) { mutableStateOf(initial.deedNumber) }
    var executionDate by remember(initial) { mutableStateOf(initial.executionDate) }
    var notaryName by remember(initial) { mutableStateOf(initial.notaryPublicName) }
    var notaryStation by remember(initial) { mutableStateOf(initial.notaryPublicStation) }
    var landRegistry by remember(initial) { mutableStateOf(initial.landRegistry) }
    var regDate by remember(initial) { mutableStateOf(initial.registrationDate) }
    var dayBook by remember(initial) { mutableStateOf(initial.dayBookNumber) }
    var folio by remember(initial) { mutableStateOf(initial.registerFolioNumber) }
    var consideration by remember(initial) {
        mutableStateOf(if (initial.purchaseConsideration > 0) initial.purchaseConsideration.toLong().toString() else "")
    }
    var vendeeName by remember(initial) { mutableStateOf(initial.vendeeName) }
    var vendeeNic by remember(initial) { mutableStateOf(initial.vendeeNic) }
    var vendeeAddress by remember(initial) { mutableStateOf(initial.vendeeAddress) }
    var vendorName by remember(initial) { mutableStateOf(initial.vendorName) }
    var vendorNic by remember(initial) { mutableStateOf(initial.vendorNic) }
    var vendorAddress by remember(initial) { mutableStateOf(initial.vendorAddress) }
    var filePaths by remember(initial) { mutableStateOf(initial.documentFilePaths) }
    var uncertainFields by remember(initial) { mutableStateOf(initial.uncertainFields) }
    var pendingCameraFile by remember { mutableStateOf<File?>(null) }

    fun buildDeed() = DeedData(
        deedNumber = deedNumber.trim(),
        executionDate = executionDate.trim(),
        notaryPublicName = notaryName.trim(),
        notaryPublicStation = notaryStation.trim(),
        landRegistry = landRegistry.trim(),
        registrationDate = regDate.trim(),
        dayBookNumber = dayBook.trim(),
        registerFolioNumber = folio.trim(),
        vendeeName = vendeeName.trim(),
        vendeeNic = vendeeNic.trim(),
        vendeeAddress = vendeeAddress.trim(),
        vendorName = vendorName.trim(),
        vendorNic = vendorNic.trim(),
        vendorAddress = vendorAddress.trim(),
        purchaseConsideration = consideration.trim().toDoubleOrNull() ?: 0.0,
        documentFilePaths = filePaths,
        uncertainFields = uncertainFields,
    )

    fun applyExtracted(d: DeedData) {
        deedNumber = d.deedNumber
        executionDate = d.executionDate
        notaryName = d.notaryPublicName
        notaryStation = d.notaryPublicStation
        landRegistry = d.landRegistry
        regDate = d.registrationDate
        dayBook = d.dayBookNumber
        folio = d.registerFolioNumber
        consideration = if (d.purchaseConsideration > 0) d.purchaseConsideration.toLong().toString() else ""
        vendeeName = d.vendeeName
        vendeeNic = d.vendeeNic
        vendeeAddress = d.vendeeAddress
        vendorName = d.vendorName
        vendorNic = d.vendorNic
        vendorAddress = d.vendorAddress
        uncertainFields = d.uncertainFields
    }

    val pdfPicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri: Uri? ->
        uri?.let { filePaths = (filePaths + it.toString()).distinct() }
    }
    val photoPicker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri: Uri? ->
        uri?.let { filePaths = (filePaths + it.toString()).distinct() }
    }
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        val f = pendingCameraFile
        if (success && f != null && f.exists()) {
            filePaths = (filePaths + f.absolutePath).distinct()
        }
    }
    val cameraPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            val (file, uri) = createCaptureFile(context, "deed")
            pendingCameraFile = file
            cameraLauncher.launch(uri)
        }
    }

    fun launchCamera() {
        val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            val (file, uri) = createCaptureFile(context, "deed")
            pendingCameraFile = file
            cameraLauncher.launch(uri)
        } else {
            cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    ResponsiveWorkflowScaffold(
        currentStep = 3,
        title = "Title Deed Extraction",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = {
            onSaveDeed(buildDeed())
            onNavigateToStep(it)
        },
        onOpenSettings = onOpenSettings,
        onBack = {
            onSaveDeed(buildDeed())
            onBack()
        },
        onNext = {
            onSaveDeed(buildDeed())
            onNext()
        },
        nextLabel = if (uiState.screens3To10Frozen) "Save Deed (Steps 4-10 Frozen)" else "Save & Continue to Plan",
        snackbarMessage = uiState.snackbarMessage,
        snackbarIsError = uiState.snackbarIsError,
        onSnackbarDismissed = onSnackbarDismissed,
    ) { isTablet ->
        val uploadCard: @Composable () -> Unit = {
            SectionCard(
                title = "Title Deed Document",
                subtitle = "Upload Deed PDF, pick scan photos, or capture pages using back camera.",
                isMandatory = true,
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedButton(
                        onClick = { pdfPicker.launch(arrayOf("application/pdf")) },
                        modifier = Modifier.weight(1f).height(44.dp),
                        shape = RoundedCornerShape(8.dp),
                    ) {
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
                        onClick = { launchCamera() },
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
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(AppColors.SurfaceContainerLow)
                            .padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Default.CheckCircle, contentDescription = null, tint = AppColors.Success, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("${filePaths.size} page(s) ready", fontSize = 13.sp, modifier = Modifier.weight(1f))
                        TextButton(onClick = { filePaths = emptyList() }) { Text("Clear", color = AppColors.Error) }
                    }
                }
                Spacer(Modifier.height(12.dp))
                Button(
                    onClick = { onExtractWithAi(filePaths) { applyExtracted(it) } },
                    enabled = !uiState.isExtracting,
                    modifier = Modifier.fillMaxWidth().height(48.dp).testTag("extract_deed_ai_button"),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                ) {
                    if (uiState.isExtracting) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
                        Spacer(Modifier.width(8.dp))
                        Text(uiState.extractionStatus.ifBlank { "Extracting..." }, fontSize = 13.sp)
                    } else {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("SUBMIT / EXTRACT WITH AI", fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        val deedFormContent: @Composable () -> Unit = {
            SectionCard(
                title = "Legal Instrument Particulars",
                subtitle = "Verify deed registration, notary, and Land Registry references.",
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Deed Number", deedNumber, { deedNumber = it }, "e.g. 4821", modifier = Modifier.weight(1f))
                    LabeledTextField("Execution Date", executionDate, { executionDate = it }, "YYYY-MM-DD", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Notary Public Name", notaryName, { notaryName = it }, "e.g. K. M. Senanayake", modifier = Modifier.weight(1f))
                    LabeledTextField("Notary Station", notaryStation, { notaryStation = it }, "e.g. Kandy", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField("Land Registry", landRegistry, { landRegistry = it }, "e.g. Kandy Land Registry", modifier = Modifier.weight(1f))
                    LabeledTextField("Registration Date", regDate, { regDate = it }, "YYYY-MM-DD", modifier = Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField(
                        label = "Day Book / Reg No.",
                        value = dayBook,
                        onValueChange = { dayBook = it },
                        hint = "e.g. D/2019/8491",
                        isUncertain = uncertainFields["dayBookNumber"] == true,
                        modifier = Modifier.weight(1f),
                    )
                    LabeledTextField("Register Folio No.", folio, { folio = it }, "e.g. F 184/92", modifier = Modifier.weight(1f))
                }
                LabeledTextField(
                    label = "Purchase Consideration Stated in Deed (LKR)",
                    value = consideration,
                    onValueChange = { consideration = it },
                    hint = "e.g. 4500000",
                    keyboardType = KeyboardType.Number,
                    isUncertain = uncertainFields["purchaseConsideration"] == true,
                )
            }

            SectionCard(
                title = "Ownership & Devolution Parties",
                subtitle = "Current Vendee (Buyer) and Vendor (Previous Owner) details.",
            ) {
                LabeledTextField("Vendee / Current Owner Full Name", vendeeName, { vendeeName = it }, "e.g. P. G. Sunil Jayawardena")
                LabeledTextField("Owner NIC Number", vendeeNic, { vendeeNic = it }, "e.g. 741920831V")
                LabeledTextField("Owner Residential Address", vendeeAddress, { vendeeAddress = it }, "e.g. No. 45, Temple Road, Pilimathalawa")
                HorizontalDivider(color = AppColors.Borders, modifier = Modifier.padding(vertical = 8.dp))
                LabeledTextField("Vendor / Previous Owner Full Name", vendorName, { vendorName = it }, "e.g. M. B. Wimalasiri Bandara")
                LabeledTextField("Vendor NIC Number", vendorNic, { vendorNic = it }, "e.g. 621048392V")
                LabeledTextField("Vendor Address", vendorAddress, { vendorAddress = it }, "e.g. Kotakumbura Watte, Handessa")
            }
        }

        if (isTablet) {
            Row(modifier = Modifier.fillMaxSize().padding(16.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(
                    modifier = Modifier
                        .weight(4f)
                        .fillMaxHeight()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.White)
                        .border(1.dp, AppColors.Borders, RoundedCornerShape(12.dp)),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth().background(AppColors.SurfaceContainerLow).padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Default.Visibility, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Original Deed Preview", fontWeight = FontWeight.Bold, fontSize = 13.sp, color = AppColors.PrimaryNavy)
                    }
                    Column(
                        modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(12.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        uploadCard()
                        if (filePaths.isEmpty()) {
                            Spacer(Modifier.height(24.dp))
                            Icon(Icons.Default.CloudUpload, contentDescription = null, tint = AppColors.SecondaryText.copy(alpha = 0.4f), modifier = Modifier.size(44.dp))
                            Spacer(Modifier.height(8.dp))
                            Text("Attach deed PDF or photos to preview alongside fields.", fontSize = 12.sp, color = AppColors.SecondaryText, textAlign = TextAlign.Center)
                        } else {
                            filePaths.forEachIndexed { idx, path ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 4.dp)
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(AppColors.SurfaceContainerLow)
                                        .padding(10.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Icon(Icons.Default.Description, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(18.dp))
                                    Spacer(Modifier.width(8.dp))
                                    Text("Page ${idx + 1}: ${path.substringAfterLast('/')}", fontSize = 12.sp)
                                }
                            }
                        }
                    }
                }
                Column(modifier = Modifier.weight(6f).verticalScroll(rememberScrollState())) {
                    deedFormContent()
                }
            }
        } else {
            Column(modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
                uploadCard()
                deedFormContent()
            }
        }
    }
}

internal fun createCaptureFile(context: Context, prefix: String): Pair<File, Uri> {
    val dir = File(context.cacheDir, "captures").apply { mkdirs() }
    val file = File(dir, "${prefix}_${System.currentTimeMillis()}.jpg")
    val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
    return file to uri
}
