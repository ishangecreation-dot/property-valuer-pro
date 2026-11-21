package com.propertyvaluerpro.app.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.PersonOutline
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.UploadFile
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.AppConstants
import com.propertyvaluerpro.app.data.models.ValuerProfile
import com.propertyvaluerpro.app.ui.components.DossierPreviewSheet
import com.propertyvaluerpro.app.ui.components.LabeledTextField
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.components.WorkflowGuideSheet
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState

@Composable
fun ProfileScreen(
    uiState: AppUiState,
    onSaveProfile: (ValuerProfile, Boolean) -> Boolean,
    onSwitchDraft: (ValuerProfile) -> Unit,
    onCreateDraft: () -> Unit,
    onUploadTemplates: (List<Uri>) -> Unit,
    onRemoveTemplate: (Int) -> Unit,
    onClearTemplates: () -> Unit,
    buildDossierMarkdown: () -> String,
    onBack: () -> Unit,
    onNextToDeed: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val context = LocalContext.current
    val p = uiState.profile

    var draftName by remember(p.id) { mutableStateOf(p.draftName) }
    var valuerName by remember(p.id) { mutableStateOf(p.valuerName) }
    var qualifications by remember(p.id) { mutableStateOf(p.qualifications) }
    var regNo by remember(p.id) { mutableStateOf(p.registrationNumber) }
    var membership by remember(p.id) { mutableStateOf(p.professionalMembership) }
    var officeAddress by remember(p.id) { mutableStateOf(p.officeAddress) }
    var phone1 by remember(p.id) { mutableStateOf(p.contactNumber) }
    var phone2 by remember(p.id) { mutableStateOf(p.contactNumber2) }
    var email by remember(p.id) { mutableStateOf(p.emailAddress) }
    var bankPanels by remember(p.id) { mutableStateOf(p.additionalContactDetails) }

    var showGuideSheet by remember { mutableStateOf(false) }
    var showDossierSheet by remember { mutableStateOf(false) }
    var showStyleSpecSheet by remember { mutableStateOf(false) }
    var draftMenuExpanded by remember { mutableStateOf(false) }

    LaunchedEffect(p) {
        draftName = p.draftName
        valuerName = p.valuerName
        qualifications = p.qualifications
        regNo = p.registrationNumber
        membership = p.professionalMembership
        officeAddress = p.officeAddress
        phone1 = p.contactNumber
        phone2 = p.contactNumber2
        email = p.emailAddress
        bankPanels = p.additionalContactDetails
    }

    fun currentEditedProfile() = p.copy(
        draftName = draftName.ifBlank { "Default Profile" },
        valuerName = valuerName.trim(),
        qualifications = qualifications.trim(),
        registrationNumber = regNo.trim(),
        professionalMembership = membership.trim(),
        officeAddress = officeAddress.trim(),
        contactNumber = phone1.trim(),
        contactNumber2 = phone2.trim(),
        emailAddress = email.trim(),
        additionalContactDetails = bankPanels.trim(),
    )

    val templatePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenMultipleDocuments(),
    ) { uris: List<Uri> ->
        if (uris.isNotEmpty()) {
            onUploadTemplates(uris)
        }
    }

    if (showGuideSheet) {
        WorkflowGuideSheet(onDismiss = { showGuideSheet = false })
    }
    if (showDossierSheet) {
        DossierPreviewSheet(markdown = buildDossierMarkdown(), onDismiss = { showDossierSheet = false })
    }
    if (showStyleSpecSheet) {
        DossierPreviewSheet(
            markdown = p.reportStyleSpecMd.ifBlank { defaultStyleSpecFallback() },
            title = "Learned Report Style Spec (.md)",
            onDismiss = { showStyleSpecSheet = false },
        )
    }

    ResponsiveWorkflowScaffold(
        currentStep = 2,
        title = "Valuer Profile Setup",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = onNavigateToStep,
        onOpenSettings = onOpenSettings,
        onBack = onBack,
        onNext = {
            if (onSaveProfile(currentEditedProfile(), false)) {
                onNextToDeed()
            }
        },
        nextLabel = "Save & Next to Deed",
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
            // Info & Guide Banner
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 14.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(AppColors.PrimaryNavy.copy(alpha = 0.06f))
                    .border(1.dp, AppColors.Borders, RoundedCornerShape(8.dp))
                    .padding(12.dp),
            ) {
                Row(verticalAlignment = Alignment.Top) {
                    Icon(Icons.Default.VerifiedUser, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(10.dp))
                    Text(
                        text = "Enter your chartered practitioner credentials. Your details are saved on this device for all future valuation reports.",
                        fontSize = 12.5.sp,
                        color = AppColors.MainText,
                        lineHeight = 18.sp,
                    )
                }
                Spacer(Modifier.height(6.dp))
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = { showDossierSheet = true }) {
                        Icon(Icons.Default.Description, contentDescription = null, tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("Case Dossier (.md)", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryActionTeal)
                    }
                    TextButton(onClick = { showGuideSheet = true }) {
                        Icon(Icons.Default.MenuBook, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("10-Step Guide", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
                    }
                }
            }

            // Profile Draft Management
            SectionCard(
                title = "Profile Draft Management",
                subtitle = "Save multiple practice profiles or branches.",
                trailing = {
                    TextButton(onClick = onCreateDraft) {
                        Icon(Icons.Default.AddCircleOutline, contentDescription = null, tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(4.dp))
                        Text("New Draft", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryActionTeal)
                    }
                },
            ) {
                if (uiState.profileDrafts.size > 1) {
                    Text("Select Saved Profile Draft:", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = AppColors.SecondaryText)
                    Spacer(Modifier.height(6.dp))
                    Box {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .background(AppColors.SurfaceContainerLow)
                                .border(1.dp, AppColors.Borders, RoundedCornerShape(8.dp))
                                .clickable { draftMenuExpanded = true }
                                .padding(horizontal = 12.dp, vertical = 10.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(draftName.ifBlank { "Default Profile" }, fontSize = 13.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryNavy)
                            Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = AppColors.PrimaryNavy)
                        }
                        DropdownMenu(expanded = draftMenuExpanded, onDismissRequest = { draftMenuExpanded = false }) {
                            uiState.profileDrafts.forEach { d ->
                                DropdownMenuItem(
                                    text = { Text("${d.draftName} ${if (d.valuerName.isNotBlank()) "(${d.valuerName})" else ""}") },
                                    onClick = {
                                        draftMenuExpanded = false
                                        onSwitchDraft(d)
                                    },
                                )
                            }
                        }
                    }
                    Spacer(Modifier.height(10.dp))
                }
                LabeledTextField(
                    label = "Draft Label / Chambers Name",
                    value = draftName,
                    onValueChange = { draftName = it },
                    hint = "e.g. Primary Practice, Colombo Head Office",
                    leadingIcon = Icons.Default.EditNote,
                )
            }

            // A. Professional Details
            SectionCard(
                title = "Professional Details",
                subtitle = "Chartered credentials and registration identifiers.",
                isMandatory = true,
            ) {
                LabeledTextField(
                    label = "Valuer Name",
                    value = valuerName,
                    onValueChange = { valuerName = it },
                    hint = "YOUR NAME HERE",
                    isRequired = true,
                    leadingIcon = Icons.Default.PersonOutline,
                    testTag = "valuer_name_input",
                )
                LabeledTextField(
                    label = "Qualifications",
                    value = qualifications,
                    onValueChange = { qualifications = it },
                    hint = "e.g. B.Sc. (Estate Mgmt & Valuation), AIV (SL)",
                    isRequired = true,
                    minLines = 2,
                    maxLines = 3,
                    leadingIcon = Icons.Default.School,
                    testTag = "qualifications_input",
                )
                LabeledTextField(
                    label = "Registration Number",
                    value = regNo,
                    onValueChange = { regNo = it },
                    hint = "e.g. IVSL/REG/1248",
                    isRequired = true,
                    leadingIcon = Icons.Default.Badge,
                    testTag = "registration_number_input",
                )
                LabeledTextField(
                    label = "Professional Membership (Optional)",
                    value = membership,
                    onValueChange = { membership = it },
                    hint = "e.g. Associate Member (AIV), MRICS, FIV",
                    leadingIcon = Icons.Default.Verified,
                )
            }

            // B. Office & Contact Details
            SectionCard(
                title = "Office and Contact Details",
                subtitle = "Chambers address and communication channels.",
                isMandatory = true,
            ) {
                LabeledTextField(
                    label = "Office Address",
                    value = officeAddress,
                    onValueChange = { officeAddress = it },
                    hint = "Enter your office address",
                    isRequired = true,
                    minLines = 2,
                    maxLines = 3,
                    leadingIcon = Icons.Default.LocationOn,
                    testTag = "office_address_input",
                )
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField(
                        label = "Contact Number 1",
                        value = phone1,
                        onValueChange = { phone1 = it },
                        hint = "+94 77 123 4567",
                        isRequired = true,
                        keyboardType = KeyboardType.Phone,
                        leadingIcon = Icons.Default.Phone,
                        testTag = "contact_number_1_input",
                        modifier = Modifier.weight(1f),
                    )
                    LabeledTextField(
                        label = "Contact Number 2",
                        value = phone2,
                        onValueChange = { phone2 = it },
                        hint = "Optional",
                        keyboardType = KeyboardType.Phone,
                        leadingIcon = Icons.Default.Phone,
                        modifier = Modifier.weight(1f),
                    )
                }
                LabeledTextField(
                    label = "Official Dispatch Email (Optional)",
                    value = email,
                    onValueChange = { email = it },
                    hint = "valuer@example.com",
                    keyboardType = KeyboardType.Email,
                    leadingIcon = Icons.Default.Email,
                )
                LabeledTextField(
                    label = "Authorized Bank Panels / Notes (Optional)",
                    value = bankPanels,
                    onValueChange = { bankPanels = it },
                    hint = "e.g. People's Bank, BOC, Commercial Bank PLC",
                    leadingIcon = Icons.Default.AccountBalance,
                )
            }

            // Save Buttons Row
            Row(
                modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                OutlinedButton(
                    onClick = { onSaveProfile(currentEditedProfile(), true) },
                    modifier = Modifier.weight(1f).height(48.dp).testTag("save_profile_button"),
                    shape = RoundedCornerShape(8.dp),
                    border = BorderStroke(1.5.dp, AppColors.PrimaryNavy),
                ) {
                    Icon(Icons.Default.Save, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Save Profile", fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
                }
                Button(
                    onClick = {
                        if (onSaveProfile(currentEditedProfile(), false)) {
                            onNextToDeed()
                        }
                    },
                    modifier = Modifier.weight(1f).height(48.dp).testTag("save_and_next_to_deed_button"),
                    shape = RoundedCornerShape(8.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
                ) {
                    Text("Next to Deed", fontWeight = FontWeight.Bold)
                    Spacer(Modifier.width(6.dp))
                    Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(18.dp))
                }
            }

            // C. Draft Report Style Analysis
            SectionCard(
                title = "Draft Report Style Templates",
                subtitle = "Upload up to ${AppConstants.FREE_TIER_TEMPLATE_LIMIT} sample DOCX/PDF reports for Gemini AI formatting analysis.",
                trailing = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "${p.uploadedTemplates.size}/${AppConstants.FREE_TIER_TEMPLATE_LIMIT}",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.PrimaryActionTeal,
                        )
                        if (p.uploadedTemplates.isNotEmpty()) {
                            Spacer(Modifier.width(8.dp))
                            Text(
                                text = "Clear",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = AppColors.Error,
                                modifier = Modifier.clickable { onClearTemplates() },
                            )
                        }
                    }
                },
            ) {
                if (uiState.isAnalyzingTemplates) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 10.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(AppColors.ProfessionalBlue.copy(alpha = 0.08f))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp, color = AppColors.ProfessionalBlue)
                        Spacer(Modifier.width(10.dp))
                        Text("Gemini AI analyzing report format, style & type...", fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.ProfessionalBlue)
                    }
                }

                p.uploadedTemplates.forEachIndexed { idx, fileName ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(AppColors.SurfaceContainerLow)
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Default.Description, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(fileName, fontSize = 12.5.sp, modifier = Modifier.weight(1f), color = AppColors.MainText)
                        IconButton(onClick = { onRemoveTemplate(idx) }, modifier = Modifier.size(28.dp)) {
                            Icon(Icons.Default.Close, contentDescription = "Remove template", tint = AppColors.Error, modifier = Modifier.size(16.dp))
                        }
                    }
                }

                if (p.isDocumentAnalysisComplete) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 10.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(AppColors.SuccessBg)
                            .border(1.dp, AppColors.Success.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                            .padding(10.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, tint = AppColors.Success, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(6.dp))
                            Text("AI Style Blueprint Active", fontSize = 12.5.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
                        }
                        if (p.reportFormat.isNotBlank()) Text("Format: ${p.reportFormat}", fontSize = 11.5.sp, color = AppColors.MainText)
                        if (p.reportStyle.isNotBlank()) Text("Style: ${p.reportStyle}", fontSize = 11.5.sp, color = AppColors.MainText)
                        if (p.reportType.isNotBlank()) Text("Type: ${p.reportType}", fontSize = 11.5.sp, color = AppColors.MainText)
                    }
                }

                OutlinedButton(
                    onClick = {
                        templatePicker.launch(
                            arrayOf(
                                "application/pdf",
                                "application/msword",
                                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                                "image/*",
                            ),
                        )
                    },
                    modifier = Modifier.fillMaxWidth().height(46.dp),
                    shape = RoundedCornerShape(8.dp),
                ) {
                    Icon(Icons.Default.UploadFile, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(8.dp))
                    Text("Upload Draft Reports (DOCX / PDF / Images)", fontWeight = FontWeight.SemiBold)
                }

                if (p.reportStyleSpecMd.isNotBlank()) {
                    Spacer(Modifier.height(8.dp))
                    OutlinedButton(
                        onClick = { showStyleSpecSheet = true },
                        modifier = Modifier.fillMaxWidth().height(42.dp),
                        shape = RoundedCornerShape(8.dp),
                        border = BorderStroke(1.5.dp, AppColors.PrimaryActionTeal),
                    ) {
                        Icon(Icons.Default.MenuBook, contentDescription = null, tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("View Learned Report Style Spec (.md)", fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryActionTeal)
                    }
                } else {
                    Spacer(Modifier.height(8.dp))
                    OutlinedButton(
                        onClick = { onCreateDraft() },
                        modifier = Modifier.fillMaxWidth().height(42.dp),
                        shape = RoundedCornerShape(8.dp),
                        border = BorderStroke(1.5.dp, AppColors.PrimaryActionTeal),
                    ) {
                        Icon(Icons.Default.AddCircleOutline, contentDescription = null, tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("New Draft Profile", fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryActionTeal)
                    }
                }
            }
        }
    }
}

private fun defaultStyleSpecFallback(): String =
    "### AI Report Style Blueprint\n" +
        "• Executive Summary: Professional 2-column key metrics table with Valuation Purpose & Forced Sale Value discount.\n" +
        "• Land Valuation Table: Extent in Acres-Roods-Perches with Perch rate, Total Land Value, and Local Authority conformity.\n" +
        "• Building Valuation: Gross Replacement Cost (GRC) itemization, physical age depreciation percentage, and Net Building Value.\n" +
        "• Statutory Declarations: Formal declaration of impartiality, physical site inspection certification, and Chartered Valuer seal block."
