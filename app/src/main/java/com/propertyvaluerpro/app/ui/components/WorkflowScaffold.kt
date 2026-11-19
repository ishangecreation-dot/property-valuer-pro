package com.propertyvaluerpro.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.AcUnit
import androidx.compose.material.icons.filled.AllInclusive
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.AppConstants
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ResponsiveWorkflowScaffold(
    currentStep: Int,
    title: String,
    screens3To10Frozen: Boolean,
    showBottomNav: Boolean = true,
    showAdBanner: Boolean = false,
    adsEnabled: Boolean = false,
    isPaidTier: Boolean = false,
    adProvider: String = AppConstants.AD_PROVIDER_META,
    onStepSelected: (Int) -> Unit = {},
    onOpenSettings: () -> Unit,
    onBack: (() -> Unit)? = null,
    onNext: (() -> Unit)? = null,
    nextLabel: String = "Next Step",
    isNextEnabled: Boolean = true,
    snackbarMessage: String? = null,
    snackbarIsError: Boolean = false,
    onSnackbarDismissed: () -> Unit = {},
    content: @Composable (isTablet: Boolean) -> Unit,
) {
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(snackbarMessage) {
        if (!snackbarMessage.isNullOrBlank()) {
            snackbarHostState.showSnackbar(snackbarMessage)
            onSnackbarDismissed()
        }
    }

    Scaffold(
        containerColor = AppColors.Background,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = title,
                        fontFamily = ManropeFontFamily,
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                },
                navigationIcon = {
                    if (onBack != null && currentStep > 1) {
                        IconButton(
                            onClick = onBack,
                            modifier = Modifier.testTag("top_back_button"),
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = Color.White,
                            )
                        }
                    }
                },
                actions = {
                    IconButton(
                        onClick = onOpenSettings,
                        modifier = Modifier.testTag("admin_settings_button"),
                    ) {
                        Icon(
                            imageVector = Icons.Default.Settings,
                            contentDescription = "Admin Settings",
                            tint = Color.White,
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = AppColors.PrimaryNavy,
                ),
            )
        },
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState) { data ->
                Snackbar(
                    snackbarData = data,
                    containerColor = if (snackbarIsError) AppColors.Error else AppColors.PrimaryNavy,
                    contentColor = Color.White,
                )
            }
        },
    ) { innerPadding ->
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            val isTablet = maxWidth >= 720.dp

            Row(modifier = Modifier.fillMaxSize()) {
                if (isTablet) {
                    TabletNavigationRail(
                        currentStep = currentStep,
                        screens3To10Frozen = screens3To10Frozen,
                        onStepSelected = onStepSelected,
                    )
                }

                Column(modifier = Modifier.weight(1f).fillMaxHeight()) {
                    if (!isTablet && currentStep > 1) {
                        WorkflowHeader(currentStep = currentStep)
                    }

                    Box(modifier = Modifier.weight(1f).fillMaxWidth()) {
                        content(isTablet)
                    }

                    if (showAdBanner && adsEnabled && !isPaidTier) {
                        AdBannerPlaceholder(adProvider = adProvider)
                    }

                    if (showBottomNav && (onBack != null || onNext != null)) {
                        Surface(
                            color = Color.White,
                            shadowElevation = 6.dp,
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Column {
                                HorizontalDivider(color = AppColors.Borders)
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .navigationBarsPadding()
                                        .padding(horizontal = 16.dp, vertical = 12.dp),
                                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    if (onBack != null) {
                                        OutlinedButton(
                                            onClick = onBack,
                                            modifier = Modifier
                                                .weight(1f)
                                                .height(48.dp)
                                                .testTag("workflow_back_button"),
                                            shape = RoundedCornerShape(10.dp),
                                            colors = ButtonDefaults.outlinedButtonColors(
                                                contentColor = AppColors.PrimaryNavy,
                                            ),
                                        ) {
                                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, modifier = Modifier.size(18.dp))
                                            Spacer(Modifier.width(6.dp))
                                            Text("Back", fontWeight = FontWeight.SemiBold, maxLines = 1)
                                        }
                                    }
                                    if (onNext != null) {
                                        Button(
                                            onClick = onNext,
                                            enabled = isNextEnabled,
                                            modifier = Modifier
                                                .weight(2f)
                                                .height(48.dp)
                                                .testTag("workflow_next_button"),
                                            shape = RoundedCornerShape(10.dp),
                                            colors = ButtonDefaults.buttonColors(
                                                containerColor = AppColors.PrimaryActionTeal,
                                                contentColor = Color.White,
                                            ),
                                            contentPadding = PaddingValues(horizontal = 12.dp),
                                        ) {
                                            Text(
                                                text = nextLabel,
                                                fontWeight = FontWeight.Bold,
                                                fontSize = 14.sp,
                                                maxLines = 1,
                                                overflow = TextOverflow.Ellipsis,
                                            )
                                            Spacer(Modifier.width(6.dp))
                                            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(18.dp))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun WorkflowHeader(currentStep: Int) {
    val step = currentStep.coerceIn(1, 10)
    val progress = step / 10f
    val stepTitle = AppConstants.WORKFLOW_STEPS[step - 1]

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White)
            .padding(horizontal = 16.dp, vertical = 10.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(AppColors.PrimaryNavy)
                        .padding(horizontal = 8.dp, vertical = 3.dp),
                ) {
                    Text(
                        text = "STEP $step OF 10",
                        color = AppColors.AntiqueGold,
                        fontWeight = FontWeight.ExtraBold,
                        fontSize = 11.sp,
                        letterSpacing = 0.5.sp,
                    )
                }
                Spacer(Modifier.width(8.dp))
                Text(
                    text = stepTitle,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.5.sp,
                    color = AppColors.MainText,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Text(
                text = "${(progress * 100).toInt()}%",
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp,
                color = AppColors.PrimaryActionTeal,
            )
        }
        Spacer(Modifier.height(8.dp))
        LinearProgressIndicator(
            progress = { progress },
            modifier = Modifier
                .fillMaxWidth()
                .height(5.dp)
                .clip(RoundedCornerShape(4.dp)),
            color = AppColors.PrimaryActionTeal,
            trackColor = AppColors.Borders,
        )
    }
    HorizontalDivider(color = AppColors.Borders)
}

@Composable
fun TabletNavigationRail(
    currentStep: Int,
    screens3To10Frozen: Boolean,
    onStepSelected: (Int) -> Unit,
) {
    Column(
        modifier = Modifier
            .width(232.dp)
            .fillMaxHeight()
            .background(AppColors.PrimaryNavy)
            .verticalScroll(rememberScrollState())
            .padding(vertical = 12.dp, horizontal = 10.dp),
    ) {
        Text(
            text = "VALUATION WORKFLOW",
            color = AppColors.AntiqueGold,
            fontSize = 11.sp,
            fontWeight = FontWeight.ExtraBold,
            letterSpacing = 0.8.sp,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
        )
        AppConstants.WORKFLOW_STEPS.forEachIndexed { idx, label ->
            val stepNum = idx + 1
            val isSelected = stepNum == currentStep
            val isCompleted = stepNum < currentStep
            val isLocked = screens3To10Frozen && stepNum > 3

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 2.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(if (isSelected) Color.White.copy(alpha = 0.14f) else Color.Transparent)
                    .clickable { onStepSelected(stepNum) }
                    .padding(horizontal = 10.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    modifier = Modifier
                        .size(24.dp)
                        .clip(CircleShape)
                        .background(
                            when {
                                isSelected -> AppColors.PrimaryActionTeal
                                isCompleted -> AppColors.Success
                                isLocked -> Color.White.copy(alpha = 0.1f)
                                else -> Color.White.copy(alpha = 0.16f)
                            },
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    when {
                        isLocked -> Icon(Icons.Default.Lock, contentDescription = null, tint = Color.White.copy(alpha = 0.6f), modifier = Modifier.size(13.dp))
                        isCompleted -> Icon(Icons.Default.Check, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                        else -> Text("$stepNum", color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    }
                }
                Spacer(Modifier.width(10.dp))
                Text(
                    text = label,
                    color = when {
                        isSelected -> Color.White
                        isLocked -> Color.White.copy(alpha = 0.45f)
                        else -> Color.White.copy(alpha = 0.82f)
                    },
                    fontSize = 13.sp,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

@Composable
fun AdBannerPlaceholder(adProvider: String) {
    val isMeta = adProvider == AppConstants.AD_PROVIDER_META
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp)
            .background(if (isMeta) AppColors.MetaBannerBg else AppColors.SurfaceContainerLow)
            .border(1.dp, AppColors.Borders)
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
    ) {
        if (isMeta) {
            Box(
                modifier = Modifier
                    .size(18.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(AppColors.MetaBlue),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Default.AllInclusive, contentDescription = null, tint = Color.White, modifier = Modifier.size(12.dp))
            }
            Spacer(Modifier.width(6.dp))
        }
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(4.dp))
                .background(if (isMeta) AppColors.MetaBlue.copy(alpha = 0.12f) else AppColors.SecondaryText.copy(alpha = 0.2f))
                .padding(horizontal = 6.dp, vertical = 2.dp),
        ) {
            Text(
                text = "SPONSORED",
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                color = if (isMeta) AppColors.MetaBlue else AppColors.SecondaryText,
            )
        }
        Spacer(Modifier.width(8.dp))
        Text(
            text = "$adProvider Banner",
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = AppColors.MainText,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
fun FrozenStepContent(
    stepNumber: Int,
    stepName: String,
    onReturnToDeed: () -> Unit,
    onReturnToProfile: () -> Unit = {},
    onReturnToDashboard: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(AppColors.ProfessionalBlue.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Default.AcUnit, contentDescription = "Frozen Step", tint = AppColors.ProfessionalBlue, modifier = Modifier.size(38.dp))
        }
        Spacer(Modifier.height(20.dp))
        Text(
            text = "Step $stepNumber is Frozen",
            fontFamily = ManropeFontFamily,
            fontSize = 20.sp,
            fontWeight = FontWeight.ExtraBold,
            color = AppColors.PrimaryNavy,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(10.dp))
        Text(
            text = "$stepName is currently locked. Screens 3 to 10 are frozen for focused verification of Screens 0 to 2.",
            fontSize = 13.5.sp,
            color = AppColors.SecondaryText,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = onReturnToDeed,
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
            shape = RoundedCornerShape(10.dp),
        ) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text("Return to Title Deed (Screen 2)")
        }
        Spacer(Modifier.height(10.dp))
        OutlinedButton(
            onClick = onReturnToProfile,
            shape = RoundedCornerShape(10.dp),
        ) {
            Icon(Icons.Default.Person, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text("Return to Valuer Profile (Screen 1)")
        }
        Spacer(Modifier.height(10.dp))
        OutlinedButton(
            onClick = onReturnToDashboard,
            shape = RoundedCornerShape(10.dp),
        ) {
            Icon(Icons.Default.Dashboard, contentDescription = null, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
            Text("Return to Dashboard (Screen 0)")
        }
    }
}
