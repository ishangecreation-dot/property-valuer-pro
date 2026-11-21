package com.propertyvaluerpro.app.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
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
import androidx.compose.material.icons.filled.AddCircleOutline
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.FolderOpen
import androidx.compose.material.icons.filled.LockClock
import androidx.compose.material.icons.filled.PieChartOutline
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material.icons.filled.WorkspacePremium
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.ExitToApp
import androidx.compose.material.icons.filled.Key
import androidx.compose.material.icons.filled.Login
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.propertyvaluerpro.app.data.models.AppConstants
import com.propertyvaluerpro.app.data.models.FirebaseUserProfile
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun DashboardScreen(
    uiState: AppUiState,
    onCreateNewValuation: () -> Unit,
    onResumeProject: (ValuationProject) -> Unit,
    onDeleteProject: (String) -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onOpenLimitDialog: () -> Unit,
    onSnackbarDismissed: () -> Unit,
    onGoogleSignIn: () -> Unit = {},
    onManualSignIn: (String, String) -> Unit = { _, _ -> },
    onSignOut: () -> Unit = {},
) {
    val dateFormat = SimpleDateFormat("dd/MM/yyyy", Locale.US)
    var showQuickSignInDialog by remember { mutableStateOf(false) }

    ResponsiveWorkflowScaffold(
        currentStep = 1,
        title = AppConstants.APP_NAME,
        screens3To10Frozen = uiState.screens3To10Frozen,
        showBottomNav = false,
        showAdBanner = true,
        adsEnabled = uiState.adsEnabled,
        isPaidTier = uiState.usageState.isPaid,
        adProvider = uiState.adProvider,
        onStepSelected = onNavigateToStep,
        onOpenSettings = onOpenSettings,
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
            // Welcome & Branding Hero Banner
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(
                        Brush.linearGradient(
                            colors = listOf(AppColors.PrimaryNavy, AppColors.PrimaryNavyLight),
                        ),
                    )
                    .padding(20.dp),
            ) {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Professional Real Estate Appraisal",
                                color = AppColors.AntiqueGold,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 0.5.sp,
                            )
                            Spacer(Modifier.height(4.dp))
                            Text(
                                text = if (uiState.profile.valuerName.isNotBlank()) {
                                    "Welcome, ${uiState.profile.valuerName}"
                                } else {
                                    "Welcome, Valuer"
                                },
                                fontFamily = ManropeFontFamily,
                                fontSize = 21.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color.White,
                            )
                        }
                        Box(
                            modifier = Modifier
                                .size(44.dp)
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color.White.copy(alpha = 0.12f)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Default.VerifiedUser, contentDescription = "Chartered Valuer", tint = AppColors.AntiqueGold)
                        }
                    }
                    Spacer(Modifier.height(10.dp))
                    Text(
                        text = "Prepare chartered, institutional valuation reports with AI-assisted title deed extraction, A3 sketching, and editable Word DOCX exports.",
                        color = Color.White.copy(alpha = 0.78f),
                        fontSize = 13.sp,
                        lineHeight = 19.sp,
                    )
                    Spacer(Modifier.height(18.dp))
                    Button(
                        onClick = onCreateNewValuation,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(50.dp)
                            .testTag("create_new_valuation_button"),
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = AppColors.PrimaryActionTeal,
                            contentColor = Color.White,
                        ),
                    ) {
                        Icon(Icons.Default.AddCircleOutline, contentDescription = null, modifier = Modifier.size(20.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("+ Create New Valuation", fontSize = 15.5.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }

            Spacer(Modifier.height(16.dp))

            // Firebase Authentication & User Profile Section
            val fbUser = uiState.firebaseUser
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = BorderStroke(1.dp, if (fbUser?.isAdmin == true) AppColors.PrimaryNavy else Color(0xFFE2E8F0)),
                shape = RoundedCornerShape(12.dp),
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    if (fbUser == null) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text("Cloud Firestore & Authentication", fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy, fontSize = 14.5.sp)
                                Text("Sign in with Google to sync quota, tokens & reports", fontSize = 12.sp, color = AppColors.NeutralGray)
                            }
                            Button(
                                onClick = onGoogleSignIn,
                                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                                shape = RoundedCornerShape(8.dp),
                            ) {
                                Icon(Icons.Default.Login, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(Modifier.width(6.dp))
                                Text("Google Sign-In", fontSize = 12.5.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                        Spacer(Modifier.height(8.dp))
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                            TextButton(
                                onClick = { showQuickSignInDialog = true },
                                modifier = Modifier.height(28.dp),
                            ) {
                                Text("Quick Test / Admin Sign-In", fontSize = 11.5.sp, color = AppColors.PrimaryActionTeal)
                            }
                        }
                    } else {
                        // User Profile Display
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                                Box(
                                    modifier = Modifier
                                        .size(40.dp)
                                        .clip(CircleShape)
                                        .background(if (fbUser.isAdmin) AppColors.PrimaryNavy else AppColors.PrimaryActionTeal),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Text(
                                        text = fbUser.name.take(1).uppercase().ifBlank { "U" },
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        fontSize = 17.sp,
                                    )
                                }
                                Spacer(Modifier.width(10.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            text = fbUser.name,
                                            fontWeight = FontWeight.Bold,
                                            color = AppColors.TextDark,
                                            fontSize = 14.sp,
                                        )
                                        Spacer(Modifier.width(6.dp))
                                        Surface(
                                            color = if (fbUser.isAdmin) AppColors.PrimaryNavy else Color(0xFFE2E8F0),
                                            shape = RoundedCornerShape(4.dp),
                                        ) {
                                            Text(
                                                text = fbUser.role.uppercase(),
                                                color = if (fbUser.isAdmin) Color.White else Color(0xFF475569),
                                                fontSize = 9.sp,
                                                fontWeight = FontWeight.Bold,
                                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                            )
                                        }
                                    }
                                    Text(
                                        text = fbUser.email,
                                        fontSize = 12.sp,
                                        color = AppColors.NeutralGray,
                                    )
                                }
                            }

                            Row {
                                if (fbUser.isAdmin) {
                                    IconButton(onClick = onOpenSettings) {
                                        Icon(Icons.Default.AdminPanelSettings, contentDescription = "Admin Panel", tint = AppColors.PrimaryNavy)
                                    }
                                }
                                IconButton(onClick = onSignOut) {
                                    Icon(Icons.Default.ExitToApp, contentDescription = "Sign Out", tint = Color(0xFFDC2626))
                                }
                            }
                        }

                        Spacer(Modifier.height(10.dp))
                        HorizontalDivider(color = Color(0xFFF1F5F9))
                        Spacer(Modifier.height(8.dp))

                        // Stats Grid: Generated Report, Model, In/Out Tokens, Avg
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column {
                                Text("Generated Reports", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                                Text(fbUser.generatedReport, fontSize = 12.5.sp, fontWeight = FontWeight.Bold, color = AppColors.TextDark)
                            }
                            Column {
                                Text("API Model in App", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                                Text(fbUser.apiModel, fontSize = 12.5.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryActionTeal)
                            }
                            Column {
                                Text("Token Usage (In/Out)", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                                Text("${fbUser.apiTokenUsageIn} / ${fbUser.apiTokenUsageOut}", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = AppColors.TextDark)
                            }
                            Column {
                                Text("AVG Token / Req", fontSize = 10.5.sp, color = AppColors.NeutralGray)
                                Text(String.format(Locale.US, "%.1f", fbUser.avgApiTokenUsage), fontSize = 12.5.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(16.dp))

            // Monthly Quota Status Card
            val usage = uiState.usageState
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = when {
                        usage.isLimitReached -> AppColors.ErrorBg
                        usage.isPaid -> AppColors.SuccessBg
                        else -> Color.White
                    },
                ),
                border = BorderStroke(
                    1.dp,
                    when {
                        usage.isLimitReached -> AppColors.Error.copy(alpha = 0.4f)
                        usage.isPaid -> AppColors.Success.copy(alpha = 0.4f)
                        else -> AppColors.Borders
                    },
                ),
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        imageVector = when {
                            usage.isLimitReached -> Icons.Default.LockClock
                            usage.isPaid -> Icons.Default.WorkspacePremium
                            else -> Icons.Default.PieChartOutline
                        },
                        contentDescription = null,
                        tint = when {
                            usage.isLimitReached -> AppColors.Error
                            usage.isPaid -> AppColors.Success
                            else -> AppColors.PrimaryNavy
                        },
                        modifier = Modifier.size(24.dp),
                    )
                    Spacer(Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text(
                                text = if (usage.isPaid) {
                                    "ValuerPro Paid Version"
                                } else {
                                    "Free Reports Used: ${usage.usedClicks} / ${usage.maxAllowance}"
                                },
                                fontFamily = ManropeFontFamily,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (usage.isLimitReached) AppColors.Error else AppColors.PrimaryNavy,
                            )
                            Text(
                                text = usage.monthIdentifier,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = AppColors.SecondaryText,
                            )
                        }
                        Spacer(Modifier.height(4.dp))
                        if (!usage.isPaid) {
                            LinearProgressIndicator(
                                progress = { (usage.usedClicks.toFloat() / usage.maxAllowance.toFloat()).coerceIn(0f, 1f) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(5.dp)
                                    .clip(RoundedCornerShape(3.dp)),
                                color = if (usage.isLimitReached) AppColors.Error else AppColors.PrimaryActionTeal,
                                trackColor = Color.Black.copy(alpha = 0.07f),
                            )
                            Spacer(Modifier.height(3.dp))
                            Text(
                                text = if (usage.isLimitReached) {
                                    "Monthly limit reached (10/10). Tap Upgrade."
                                } else {
                                    "${usage.remainingClicks} free report generations remaining this month."
                                },
                                fontSize = 11.sp,
                                color = if (usage.isLimitReached) AppColors.Error else AppColors.SecondaryText,
                            )
                        } else {
                            Text(
                                text = "Unlimited monthly reports enabled",
                                fontSize = 11.sp,
                                color = AppColors.Success,
                            )
                        }
                    }
                    if (usage.isLimitReached) {
                        TextButton(onClick = onOpenLimitDialog) {
                            Text("Upgrade", fontWeight = FontWeight.Bold, color = AppColors.Error)
                        }
                    }
                }
            }

            // Continue Active Valuation Card
            uiState.activeProject?.let { active ->
                Spacer(Modifier.height(20.dp))
                Text(
                    text = "Continue Valuation",
                    fontFamily = ManropeFontFamily,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.PrimaryNavy,
                )
                Spacer(Modifier.height(8.dp))
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White),
                    border = BorderStroke(1.dp, AppColors.Borders),
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = active.projectName,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = AppColors.MainText,
                                modifier = Modifier.weight(1f),
                            )
                            StatusBadge(active.status)
                        }
                        Spacer(Modifier.height(6.dp))
                        Text(
                            text = "Target Bank: ${active.clientOrBank} • Updated: ${dateFormat.format(Date(active.updatedAtEpochMs))}",
                            fontSize = 12.sp,
                            color = AppColors.SecondaryText,
                        )
                        Spacer(Modifier.height(12.dp))
                        OutlinedButton(
                            onClick = { onResumeProject(active) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(46.dp)
                                .testTag("resume_workflow_button"),
                            shape = RoundedCornerShape(10.dp),
                        ) {
                            Text("Resume Guided Workflow", fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryNavy)
                        }
                    }
                }
            }

            Spacer(Modifier.height(20.dp))

            // Recent Projects Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Recent Projects",
                    fontFamily = ManropeFontFamily,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.PrimaryNavy,
                )
                Text("${uiState.projects.size} Total", fontSize = 13.sp, color = AppColors.SecondaryText)
            }
            Spacer(Modifier.height(8.dp))

            if (uiState.projects.isEmpty()) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Icon(Icons.Default.FolderOpen, contentDescription = null, tint = AppColors.SecondaryText.copy(alpha = 0.4f), modifier = Modifier.size(48.dp))
                    Spacer(Modifier.height(10.dp))
                    Text(
                        text = "No valuation projects yet.\nTap \"+ Create New Valuation\" to get started.",
                        textAlign = TextAlign.Center,
                        color = AppColors.SecondaryText,
                        fontSize = 13.5.sp,
                    )
                }
            } else {
                uiState.projects.forEach { proj ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 10.dp)
                            .clickable { onResumeProject(proj) },
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = BorderStroke(1.dp, AppColors.Borders),
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(AppColors.SurfaceContainerLow),
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(Icons.Default.Description, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(22.dp))
                            }
                            Spacer(Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(proj.projectName, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = AppColors.MainText)
                                Text(
                                    text = "${proj.clientOrBank} • Target: ${proj.targetPageCount} Pages",
                                    fontSize = 12.sp,
                                    color = AppColors.SecondaryText,
                                )
                            }
                            StatusBadge(proj.status)
                            IconButton(onClick = { onDeleteProject(proj.id) }) {
                                Icon(Icons.Default.DeleteOutline, contentDescription = "Delete project", tint = AppColors.SecondaryText, modifier = Modifier.size(19.dp))
                            }
                        }
                    }
                }
            }
        }
    }

    if (showQuickSignInDialog) {
        var quickEmail by remember { mutableStateOf("ishangecreation@gmail.com") }
        var quickName by remember { mutableStateOf("Ishange Creation (Admin)") }

        AlertDialog(
            onDismissRequest = { showQuickSignInDialog = false },
            title = { Text("Quick Sign-In (Firebase)", fontWeight = FontWeight.Bold) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "Direct sign-in for testing admin control and Firestore synchronization without requiring Google Play Services on emulator:",
                        fontSize = 12.sp,
                        color = AppColors.NeutralGray,
                    )
                    OutlinedTextField(
                        value = quickEmail,
                        onValueChange = { quickEmail = it },
                        label = { Text("Email") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                    OutlinedTextField(
                        value = quickName,
                        onValueChange = { quickName = it },
                        label = { Text("Display Name") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        onManualSignIn(quickEmail, quickName)
                        showQuickSignInDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                ) {
                    Text("Sign In")
                }
            },
            dismissButton = {
                TextButton(onClick = { showQuickSignInDialog = false }) {
                    Text("Cancel")
                }
            },
        )
    }
}

@Composable
private fun StatusBadge(status: String) {
    val color = when (status) {
        AppConstants.STATUS_COMPLETED -> AppColors.Success
        AppConstants.STATUS_READY -> AppColors.PrimaryActionTeal
        AppConstants.STATUS_IN_PROGRESS -> AppColors.Warning
        else -> AppColors.SecondaryText
    }
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(6.dp))
            .background(color.copy(alpha = 0.14f))
            .padding(horizontal = 8.dp, vertical = 3.dp),
    ) {
        Text(
            text = status.uppercase(),
            fontSize = 10.5.sp,
            fontWeight = FontWeight.Bold,
            color = color,
        )
    }
}
