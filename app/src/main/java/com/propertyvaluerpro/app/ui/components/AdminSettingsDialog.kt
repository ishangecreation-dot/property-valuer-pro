package com.propertyvaluerpro.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentPaste
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Login
import androidx.compose.material.icons.filled.NetworkCheck
import androidx.compose.material.icons.filled.Psychology
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.VpnKey
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.propertyvaluerpro.app.data.models.AppConstants
import com.propertyvaluerpro.app.data.services.AiService
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.ValuationViewModel
import kotlinx.coroutines.launch

@Composable
fun AdminSettingsDialog(
    viewModel: ValuationViewModel,
    onDismiss: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val clipboard = LocalClipboardManager.current

    var isAuthenticated by remember { mutableStateOf(false) }
    var password by remember { mutableStateOf("") }
    var obscurePassword by remember { mutableStateOf(true) }
    var showAccessDenied by remember { mutableStateOf(false) }

    var apiKey by remember { mutableStateOf(viewModel.secureStorage.getAiApiKey()) }
    var obscureApiKey by remember { mutableStateOf(true) }
    var selectedModel by remember { mutableStateOf(AiService.resolveModelId(viewModel.secureStorage.getAiProvider())) }
    var availableModels by remember { mutableStateOf(AiService.DEFAULT_WORKING_MODELS) }
    var modelDropdownExpanded by remember { mutableStateOf(false) }
    var isFetchingModels by remember { mutableStateOf(false) }
    var isTesting by remember { mutableStateOf(false) }
    var testMessage by remember { mutableStateOf<String?>(null) }
    var testSuccess by remember { mutableStateOf<Boolean?>(null) }

    var isPaidTier by remember { mutableStateOf(viewModel.repository.isPaidTier()) }
    var adsEnabled by remember { mutableStateOf(viewModel.repository.isAdsEnabled()) }
    var screensFrozen by remember { mutableStateOf(viewModel.repository.areScreens3To10Frozen()) }
    var usageState by remember { mutableStateOf(viewModel.repository.getMonthlyUsage()) }

    fun applyModelDefault(list: List<String>) {
        if (list.isNotEmpty()) {
            availableModels = list
            val currentResolved = AiService.resolveModelId(selectedModel)
            if (!list.contains(currentResolved) || currentResolved.isEmpty()) {
                selectedModel = when {
                    list.contains(AiService.DEFAULT_MODEL_ID) -> AiService.DEFAULT_MODEL_ID
                    list.contains(AiService.SECONDARY_DEFAULT_MODEL_ID) -> AiService.SECONDARY_DEFAULT_MODEL_ID
                    list.any { it.contains("3.1") && it.contains("flash-lite") } -> list.first { it.contains("3.1") && it.contains("flash-lite") }
                    list.any { it.contains("3.5") && it.contains("flash-lite") } -> list.first { it.contains("3.5") && it.contains("flash-lite") }
                    else -> list.first()
                }
                viewModel.secureStorage.saveAiProvider(selectedModel)
            }
        }
    }

    LaunchedEffect(isAuthenticated) {
        if (isAuthenticated && apiKey.isNotBlank()) {
            val fetched = viewModel.fetchModels(apiKey)
            applyModelDefault(fetched)
        }
    }

    if (showAccessDenied) {
        AlertDialog(
            onDismissRequest = { showAccessDenied = false },
            title = { Text("Access Denied", fontWeight = FontWeight.Bold, color = AppColors.Error) },
            text = { Text("Incorrect password. Please contact your app creator Admin.") },
            confirmButton = {
                Button(
                    onClick = { showAccessDenied = false },
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                ) { Text("OK") }
            },
        )
    }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth(0.92f)
                .padding(vertical = 20.dp),
            shape = RoundedCornerShape(16.dp),
            color = Color.White,
        ) {
            Column(
                modifier = Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(20.dp),
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = if (isAuthenticated) Icons.Default.VpnKey else Icons.Default.AdminPanelSettings,
                            contentDescription = null,
                            tint = AppColors.PrimaryNavy,
                            modifier = Modifier.size(24.dp),
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            text = if (isAuthenticated) "AI API Key Settings" else "Administrator Authentication",
                            fontFamily = ManropeFontFamily,
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.PrimaryNavy,
                        )
                    }
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
                HorizontalDivider(color = AppColors.Borders, modifier = Modifier.padding(vertical = 8.dp))

                if (!isAuthenticated) {
                    Text(
                        text = "Enter the administrator password to access AI API key and quota settings.",
                        fontSize = 13.5.sp,
                        color = AppColors.SecondaryText,
                    )
                    Spacer(Modifier.height(14.dp))
                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Administrator Password") },
                        placeholder = { Text("Default: admin@valuer") },
                        singleLine = true,
                        visualTransformation = if (obscurePassword) PasswordVisualTransformation() else VisualTransformation.None,
                        leadingIcon = { Icon(Icons.Default.Lock, contentDescription = null, modifier = Modifier.size(20.dp)) },
                        trailingIcon = {
                            IconButton(onClick = { obscurePassword = !obscurePassword }) {
                                Icon(if (obscurePassword) Icons.Default.Visibility else Icons.Default.VisibilityOff, contentDescription = "Toggle visibility")
                            }
                        },
                        modifier = Modifier.fillMaxWidth().testTag("admin_password_input"),
                    )
                    Spacer(Modifier.height(20.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End,
                    ) {
                        OutlinedButton(onClick = onDismiss) { Text("Cancel") }
                        Spacer(Modifier.width(10.dp))
                        Button(
                            onClick = {
                                if (viewModel.secureStorage.verifyAdminPassword(password)) {
                                    isAuthenticated = true
                                } else {
                                    password = ""
                                    showAccessDenied = true
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                            modifier = Modifier.testTag("admin_login_button"),
                        ) {
                            Icon(Icons.Default.Login, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(6.dp))
                            Text("Login", fontWeight = FontWeight.Bold)
                        }
                    }
                } else {
                    Text("Enter Your Gemini API Key", fontFamily = ManropeFontFamily, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
                    Spacer(Modifier.height(4.dp))
                    Text("Paste your Gemini API key below to enable AI document extraction.", fontSize = 12.5.sp, color = AppColors.SecondaryText)
                    Spacer(Modifier.height(10.dp))

                    OutlinedTextField(
                        value = apiKey,
                        onValueChange = { apiKey = it },
                        placeholder = { Text("Paste Gemini API Key (AIzaSy...)") },
                        singleLine = obscureApiKey,
                        visualTransformation = if (obscureApiKey) PasswordVisualTransformation() else VisualTransformation.None,
                        trailingIcon = {
                            Row {
                                IconButton(
                                    onClick = {
                                        clipboard.getText()?.text?.trim()?.let { pasted ->
                                            apiKey = pasted
                                            scope.launch {
                                                val list = viewModel.fetchModels(pasted)
                                                applyModelDefault(list)
                                            }
                                        }
                                    },
                                ) {
                                    Icon(Icons.Default.ContentPaste, contentDescription = "Paste API Key", tint = AppColors.PrimaryNavy, modifier = Modifier.size(19.dp))
                                }
                                IconButton(onClick = { obscureApiKey = !obscureApiKey }) {
                                    Icon(if (obscureApiKey) Icons.Default.Visibility else Icons.Default.VisibilityOff, contentDescription = "Toggle key", modifier = Modifier.size(19.dp))
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth().testTag("gemini_api_key_input"),
                    )
                    Spacer(Modifier.height(12.dp))

                    // AI Engine Model Picker
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(AppColors.SurfaceContainerLow)
                            .border(1.dp, AppColors.Borders, RoundedCornerShape(10.dp))
                            .padding(12.dp),
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Psychology, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(18.dp))
                                Spacer(Modifier.width(6.dp))
                                Text("AI Engine Model", fontFamily = ManropeFontFamily, fontSize = 13.5.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
                            }
                            if (isFetchingModels) {
                                CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                            } else {
                                Row(
                                    modifier = Modifier.clickable {
                                        scope.launch {
                                            isFetchingModels = true
                                            val list = viewModel.fetchModels(apiKey)
                                            applyModelDefault(list)
                                            isFetchingModels = false
                                        }
                                    },
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Icon(Icons.Default.Sync, contentDescription = "Fetch Models", tint = AppColors.ProfessionalBlue, modifier = Modifier.size(14.dp))
                                    Spacer(Modifier.width(4.dp))
                                    Text("Fetch Models", fontSize = 11.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.ProfessionalBlue)
                                }
                            }
                        }
                        Spacer(Modifier.height(8.dp))
                        Box {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color.White)
                                    .border(1.dp, AppColors.Borders, RoundedCornerShape(8.dp))
                                    .clickable { modelDropdownExpanded = true }
                                    .padding(horizontal = 12.dp, vertical = 10.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Text(AiService.formatModelLabel(selectedModel), fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryNavy)
                                Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = AppColors.PrimaryNavy)
                            }
                            DropdownMenu(expanded = modelDropdownExpanded, onDismissRequest = { modelDropdownExpanded = false }) {
                                availableModels.forEach { modelId ->
                                    val isRecommended = modelId == AiService.DEFAULT_MODEL_ID ||
                                        modelId == AiService.SECONDARY_DEFAULT_MODEL_ID ||
                                        modelId.contains("3.1-flash-lite") ||
                                        modelId.contains("3.5-flash-lite")
                                    DropdownMenuItem(
                                        text = {
                                            Row(verticalAlignment = Alignment.CenterVertically) {
                                                Icon(
                                                    imageVector = if (isRecommended) Icons.Default.CheckCircle else Icons.Default.Psychology,
                                                    contentDescription = null,
                                                    tint = if (isRecommended) AppColors.Success else AppColors.SecondaryText,
                                                    modifier = Modifier.size(16.dp),
                                                )
                                                Spacer(Modifier.width(8.dp))
                                                Text(
                                                    text = AiService.formatModelLabel(modelId),
                                                    fontSize = 13.sp,
                                                    fontWeight = if (isRecommended) FontWeight.Bold else FontWeight.Normal,
                                                    color = if (isRecommended) AppColors.PrimaryNavy else AppColors.MainText,
                                                )
                                            }
                                        },
                                        onClick = {
                                            selectedModel = modelId
                                            viewModel.secureStorage.saveAiProvider(modelId)
                                            modelDropdownExpanded = false
                                        },
                                    )
                                }
                            }
                        }
                        Spacer(Modifier.height(6.dp))
                        Text(
                            text = "Target: models/$selectedModel",
                            fontFamily = JetBrainsMonoFontFamily,
                            fontSize = 11.sp,
                            color = AppColors.SecondaryText,
                        )
                    }

                    if (!testMessage.isNullOrBlank()) {
                        Spacer(Modifier.height(10.dp))
                        val isOk = testSuccess == true
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .background((if (isOk) AppColors.Success else AppColors.Error).copy(alpha = 0.12f))
                                .border(1.dp, if (isOk) AppColors.Success else AppColors.Error, RoundedCornerShape(8.dp))
                                .padding(10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(
                                imageVector = if (isOk) Icons.Default.CheckCircle else Icons.Default.ErrorOutline,
                                contentDescription = null,
                                tint = if (isOk) AppColors.Success else AppColors.Error,
                                modifier = Modifier.size(18.dp),
                            )
                            Spacer(Modifier.width(8.dp))
                            Text(testMessage!!, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = if (isOk) AppColors.Success else AppColors.Error)
                        }
                    }

                    Spacer(Modifier.height(12.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(
                            onClick = {
                                if (apiKey.isBlank()) {
                                    testSuccess = false
                                    testMessage = "Please enter your API key first."
                                } else {
                                    viewModel.secureStorage.saveAiApiKey(apiKey)
                                    val resolvedModel = AiService.resolveModelId(selectedModel)
                                    viewModel.secureStorage.saveAiProvider(resolvedModel)
                                    testSuccess = true
                                    testMessage = "Settings saved: $resolvedModel is active."
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                            modifier = Modifier.testTag("save_api_key_button"),
                        ) {
                            Icon(Icons.Default.Save, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(6.dp))
                            Text("Save Key", fontSize = 13.sp)
                        }
                        OutlinedButton(
                            onClick = {
                                if (apiKey.isBlank()) {
                                    testSuccess = false
                                    testMessage = "Please enter your API key first."
                                } else {
                                    viewModel.secureStorage.saveAiApiKey(apiKey)
                                    viewModel.secureStorage.saveAiProvider(selectedModel)
                                    scope.launch {
                                        isTesting = true
                                        val res = viewModel.testApiConnection()
                                        isTesting = false
                                        testSuccess = res.success
                                        testMessage = res.message
                                    }
                                }
                            },
                            enabled = !isTesting,
                        ) {
                            if (isTesting) {
                                CircularProgressIndicator(modifier = Modifier.size(14.dp), strokeWidth = 2.dp)
                            } else {
                                Icon(Icons.Default.NetworkCheck, contentDescription = null, modifier = Modifier.size(16.dp))
                            }
                            Spacer(Modifier.width(6.dp))
                            Text("Test", fontSize = 13.sp)
                        }
                    }

                    Spacer(Modifier.height(16.dp))
                    HorizontalDivider(color = AppColors.Borders)
                    Spacer(Modifier.height(12.dp))

                    Text("Quota, Licensing & Workflow Controls", fontFamily = ManropeFontFamily, fontSize = 13.5.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
                    Spacer(Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text("Usage (${usageState.monthIdentifier}): ${usageState.usedClicks}/${usageState.maxAllowance}", fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold)
                        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            TextButton(onClick = { usageState = viewModel.repository.setSimulatedMonthlyCount(0) }) {
                                Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(14.dp))
                                Spacer(Modifier.width(2.dp))
                                Text("Reset", fontSize = 11.5.sp)
                            }
                            TextButton(onClick = { usageState = viewModel.repository.setSimulatedMonthlyCount(10) }) {
                                Text("Sim 10/10", fontSize = 11.5.sp)
                            }
                        }
                    }

                    AdminToggleRow(
                        title = "Paid Tier Entitlement (Unlimited)",
                        subtitle = "Bypasses 10/month limit and disables ads",
                        checked = isPaidTier,
                        onCheckedChange = {
                            isPaidTier = it
                            viewModel.repository.setPaidTier(it)
                            usageState = viewModel.repository.getMonthlyUsage()
                        },
                    )
                    AdminToggleRow(
                        title = "Enable Interstitial & Banner Ads",
                        subtitle = "Displays partner ad placements in free tier",
                        checked = adsEnabled,
                        onCheckedChange = {
                            adsEnabled = it
                            viewModel.repository.setAdsEnabled(it)
                        },
                    )
                    AdminToggleRow(
                        title = "Freeze Screens 4 to 10",
                        subtitle = "Lock Steps 4-10 to focus verification on Steps 1-3",
                        checked = screensFrozen,
                        onCheckedChange = {
                            screensFrozen = it
                            viewModel.repository.setScreens3To10Frozen(it)
                        },
                    )

                    Spacer(Modifier.height(8.dp))
                    Text("${AppConstants.APP_NAME} v${AppConstants.APP_VERSION}", fontSize = 11.sp, color = AppColors.SecondaryText)
                }
            }
        }
    }
}

@Composable
private fun AdminToggleRow(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f).padding(end = 10.dp)) {
            Text(title, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = AppColors.MainText)
            Text(subtitle, fontSize = 11.sp, color = AppColors.SecondaryText)
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(checkedTrackColor = AppColors.PrimaryActionTeal),
        )
    }
}
