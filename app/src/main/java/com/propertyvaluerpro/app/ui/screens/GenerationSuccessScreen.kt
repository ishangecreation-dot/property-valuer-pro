package com.propertyvaluerpro.app.ui.screens

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.Archive
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.propertyvaluerpro.app.data.models.CurrencyFormatter
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import java.io.File

private const val DOCX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

@Composable
fun GenerationSuccessScreen(
    uiState: AppUiState,
    onShowMessage: (String, Boolean) -> Unit,
    onBackToReview: () -> Unit,
    onReturnToDashboard: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val context = LocalContext.current
    val project = uiState.activeProject ?: ValuationProject(id = "temp")
    val docxFile = File(project.generatedDocxPath)
    val fileName = docxFile.name.ifBlank { "Valuation_Report.docx" }

    val perches = project.surveyPlanData.selectedTotalPerches.takeIf { it > 0 } ?: 15.0
    val hasBuilding = project.buildingDetails.hasBuilding && !project.buildingSketch.isBareLand
    val totalArea = project.buildingDetails.totalBuiltUpArea.takeIf { it > 0 } ?: if (hasBuilding) 1500.0 else 0.0
    val computedMv = project.valuationData.computeTotalMarketValue(perches, totalArea, hasBuilding)
    val sayVal = project.valuationData.computeSayValue(computedMv)
    val fsvVal = project.valuationData.computeFsv(sayVal)

    fun openDocx() {
        if (!docxFile.exists()) {
            onShowMessage("Report file not found on device. Tap Regenerate.", true)
            return
        }
        runCatching {
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", docxFile)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, DOCX_MIME_TYPE)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(intent, "Open Editable DOCX Report"))
        }.onFailure {
            onShowMessage("No Microsoft Word / DOCX viewer installed. Use Share to export.", true)
        }
    }

    fun shareDocx() {
        if (!docxFile.exists()) {
            onShowMessage("Report file not found on device. Tap Regenerate.", true)
            return
        }
        runCatching {
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", docxFile)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = DOCX_MIME_TYPE
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "Valuation Report - ${project.projectName}")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(Intent.createChooser(intent, "Share Valuation Report (.docx)"))
        }.onFailure {
            onShowMessage("Unable to launch share sheet: ${it.message}", true)
        }
    }

    ResponsiveWorkflowScaffold(
        currentStep = 10,
        title = "Report Ready",
        screens3To10Frozen = uiState.screens3To10Frozen,
        showBottomNav = false,
        showAdBanner = true,
        adsEnabled = uiState.adsEnabled,
        isPaidTier = uiState.usageState.isPaid,
        adProvider = uiState.adProvider,
        onStepSelected = onNavigateToStep,
        onOpenSettings = onOpenSettings,
        onBack = onBackToReview,
        snackbarMessage = uiState.snackbarMessage,
        snackbarIsError = uiState.snackbarIsError,
        onSnackbarDismissed = onSnackbarDismissed,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                modifier = Modifier
                    .size(76.dp)
                    .clip(CircleShape)
                    .background(AppColors.Success.copy(alpha = 0.14f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = "Report Generated",
                    tint = AppColors.Success,
                    modifier = Modifier.size(46.dp),
                )
            }

            Spacer(Modifier.height(14.dp))

            Text(
                text = "Valuation Report Generated!",
                fontFamily = ManropeFontFamily,
                fontWeight = FontWeight.ExtraBold,
                fontSize = 21.sp,
                color = AppColors.PrimaryNavy,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = "Your editable Microsoft Word (.docx) dossier (${project.targetPageCount}-Page Budget) has been compiled and saved securely.",
                fontSize = 13.sp,
                color = AppColors.SecondaryText,
                textAlign = TextAlign.Center,
            )

            Spacer(Modifier.height(18.dp))

            // Report Summary Card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(Color.White)
                    .border(1.dp, AppColors.Borders, RoundedCornerShape(12.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                SummaryLine("Document File", fileName)
                SummaryLine("Client / Bank", project.inspectionData.targetInstitution)
                SummaryLine("Page Target", "${project.targetPageCount} Pages (Standard OpenXML)")
                SummaryLine("Market Value (SAY)", CurrencyFormatter.formatLkr(sayVal), highlight = true)
                SummaryLine("Forced Sale Value", CurrencyFormatter.formatLkr(fsvVal))
            }

            Spacer(Modifier.height(18.dp))

            // Primary Action 1: Open in Word
            Button(
                onClick = ::openDocx,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .testTag("open_docx_button"),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
            ) {
                Icon(Icons.Default.Description, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(10.dp))
                Text("Open Editable DOCX in Word", fontWeight = FontWeight.Bold, fontSize = 14.sp)
            }

            Spacer(Modifier.height(10.dp))

            // Primary Action 2: Share
            Button(
                onClick = ::shareDocx,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .testTag("share_docx_button"),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
            ) {
                Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(10.dp))
                Text("Share Valuation Report", fontWeight = FontWeight.Bold, fontSize = 14.sp)
            }

            Spacer(Modifier.height(10.dp))

            // Primary Action 3: Save & Archive
            OutlinedButton(
                onClick = { onShowMessage("Project archived under Completed Valuations on Dashboard.", false) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .testTag("archive_project_button"),
                shape = RoundedCornerShape(10.dp),
            ) {
                Icon(Icons.Default.Archive, contentDescription = null, modifier = Modifier.size(18.dp), tint = AppColors.PrimaryNavy)
                Spacer(Modifier.width(8.dp))
                Text("Save & Archive Project", fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy)
            }

            Spacer(Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                OutlinedButton(
                    onClick = onBackToReview,
                    modifier = Modifier.weight(1f).height(46.dp).testTag("regenerate_copy_button"),
                    shape = RoundedCornerShape(10.dp),
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Edit / Copy", fontSize = 12.5.sp, fontWeight = FontWeight.Bold)
                }
                Button(
                    onClick = onReturnToDashboard,
                    modifier = Modifier.weight(1f).height(46.dp).testTag("return_dashboard_button"),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.AntiqueGold, contentColor = AppColors.PrimaryNavy),
                ) {
                    Icon(Icons.Default.Dashboard, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Dashboard", fontSize = 12.5.sp, fontWeight = FontWeight.ExtraBold)
                }
            }
        }
    }
}

@Composable
private fun SummaryLine(label: String, value: String, highlight: Boolean = false) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, fontSize = 12.5.sp, color = AppColors.SecondaryText)
        Spacer(Modifier.width(12.dp))
        Text(
            text = value,
            fontFamily = if (highlight) JetBrainsMonoFontFamily else ManropeFontFamily,
            fontWeight = FontWeight.Bold,
            fontSize = 12.5.sp,
            color = if (highlight) AppColors.PrimaryActionTeal else AppColors.PrimaryNavy,
            textAlign = TextAlign.End,
        )
    }
}
