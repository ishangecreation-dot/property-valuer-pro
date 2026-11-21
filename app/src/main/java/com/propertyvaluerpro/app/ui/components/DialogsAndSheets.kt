package com.propertyvaluerpro.app.ui.components

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AllInclusive
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.LockClock
import androidx.compose.material.icons.filled.MenuBook
import androidx.compose.material.icons.filled.VpnKey
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily
import kotlinx.coroutines.delay

@Composable
fun MonthlyLimitReachedDialog(
    onVerifyLicense: (String) -> Boolean,
    onDismiss: () -> Unit,
) {
    var showLicenseInput by remember { mutableStateOf(false) }
    var licenseText by remember { mutableStateOf("") }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .clip(CircleShape)
                        .background(AppColors.Warning.copy(alpha = 0.16f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Default.LockClock, contentDescription = null, tint = AppColors.Warning, modifier = Modifier.size(20.dp))
                }
                Spacer(Modifier.width(10.dp))
                Text(
                    text = "Monthly Report Limit Reached",
                    fontFamily = ManropeFontFamily,
                    fontSize = 16.5.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = AppColors.PrimaryNavy,
                )
            }
        },
        text = {
            Column {
                Text(
                    text = "You have reached your 10-report free monthly allowance. Upgrade to the Paid Version to generate unlimited reports.",
                    fontSize = 13.5.sp,
                    color = AppColors.MainText,
                )
                Spacer(Modifier.height(14.dp))
                if (!showLicenseInput) {
                    Row(
                        modifier = Modifier.clickable { showLicenseInput = true },
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Default.VpnKey, contentDescription = null, tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(
                            text = "Have a Paid Commercial License Key?",
                            fontSize = 12.5.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.PrimaryActionTeal,
                            textDecoration = TextDecoration.Underline,
                        )
                    }
                } else {
                    HorizontalDivider(color = AppColors.Borders)
                    Spacer(Modifier.height(10.dp))
                    OutlinedTextField(
                        value = licenseText,
                        onValueChange = {
                            licenseText = it
                            errorMsg = null
                        },
                        label = { Text("License Key") },
                        placeholder = { Text("VLR-PRO-XXXX-XXXX") },
                        isError = errorMsg != null,
                        supportingText = errorMsg?.let { { Text(it, color = AppColors.Error) } },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        TextButton(onClick = { showLicenseInput = false }) { Text("Cancel") }
                        Button(
                            onClick = {
                                if (onVerifyLicense(licenseText)) {
                                    onDismiss()
                                } else {
                                    errorMsg = "Invalid commercial license key (starts with VLR-PRO-)."
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
                        ) { Text("Activate") }
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
            ) { Text("OK", fontWeight = FontWeight.Bold) }
        },
    )
}

@Composable
fun InterstitialAdDialog(
    adProvider: String,
    onAdClosed: () -> Unit,
) {
    var secondsLeft by remember { mutableIntStateOf(3) }
    LaunchedEffect(Unit) {
        while (secondsLeft > 0) {
            delay(1000)
            secondsLeft--
        }
    }

    AlertDialog(
        onDismissRequest = { if (secondsLeft == 0) onAdClosed() },
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.AllInclusive, contentDescription = null, tint = AppColors.MetaBlue)
                Spacer(Modifier.width(8.dp))
                Text("Sponsored Message", fontFamily = ManropeFontFamily, fontWeight = FontWeight.Bold, fontSize = 16.sp)
            }
        },
        text = {
            Column {
                Text("$adProvider Interstitial Placement", fontSize = 12.sp, color = AppColors.SecondaryText)
                Spacer(Modifier.height(10.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(AppColors.MetaBannerBg)
                        .padding(16.dp),
                ) {
                    Text(
                        text = "Your Microsoft Word (.docx) valuation dossier will compile automatically right after this brief partner notice.",
                        fontSize = 13.sp,
                        color = AppColors.PrimaryNavy,
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = onAdClosed,
                enabled = secondsLeft == 0,
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
            ) {
                Text(if (secondsLeft > 0) "Continue in ${secondsLeft}s" else "Continue & Generate DOCX")
            }
        },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WorkflowGuideSheet(onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val steps = listOf(
        1 to ("Dashboard & Project Initialization" to "Case file creation, banking client selection, and monthly quota tracking."),
        2 to ("Valuer Profile Setup & AI Style Learning" to "Chartered credentials, chambers address, multi-document upload & Gemini style learning."),
        3 to ("Title Deed Extraction & Devolution" to "Deed OCR ingestion, notary, folio/day book, vendee/vendor, and consideration."),
        4 to ("Cadastral Survey Plan & Exact Lots" to "Plan number, surveyor details, Acres-Roods-Perches allotments, and boundaries."),
        5 to ("Inspection Particulars & Statutory Compliance" to "Bank/branch, loan purpose, administrative divisions, NBRO & street line status."),
        6 to ("Situation, Accessibility & GIS Geolocation" to "GPS pin coordinates, road width/surface, utilities, and AI phrasing polish."),
        7 to ("A3 Building Sketching (Mini-CAD)" to "Bare land skip option, architectural grid canvas, and vector floorplan tools."),
        8 to ("Building Specifications & Photo Register" to "Roof/wall/floor specs, room steppers, land characteristics, and 4 photo slots."),
        9 to ("Valuation Engine (Land, GRC, SAY & FSV)" to "Real-time computation of Land Value, GRC, Depreciation, SAY, FSV & SWOC rating."),
        10 to ("Final Review, Page Budget & DOCX Export" to "8-step audit checklist, 3/4/5 page budget, and editable Word (.docx) generation."),
    )

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState, containerColor = Color.White) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.PrimaryNavy)
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Default.MenuBook, contentDescription = null, tint = Color.White)
                Spacer(Modifier.width(10.dp))
                Text("10-Step Valuation Report Guide", fontFamily = ManropeFontFamily, fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.5.sp, modifier = Modifier.weight(1f))
                IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White) }
            }
            Column(
                modifier = Modifier
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                steps.forEach { (num, pair) ->
                    Row(verticalAlignment = Alignment.Top) {
                        Box(
                            modifier = Modifier
                                .size(26.dp)
                                .clip(CircleShape)
                                .background(AppColors.PrimaryNavy),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text("$num", color = AppColors.AntiqueGold, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                        Spacer(Modifier.width(10.dp))
                        Column {
                            Text(pair.first, fontWeight = FontWeight.Bold, fontSize = 13.5.sp, color = AppColors.PrimaryNavy)
                            Text(pair.second, fontSize = 12.sp, color = AppColors.SecondaryText)
                        }
                    }
                }
                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DossierPreviewSheet(
    markdown: String,
    onDismiss: () -> Unit,
    title: String = "Dossier Preview",
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheetState, containerColor = Color.White) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.PrimaryNavy)
                    .padding(horizontal = 20.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(Icons.Default.Description, contentDescription = null, tint = Color.White)
                Spacer(Modifier.width(10.dp))
                Text(title, fontFamily = ManropeFontFamily, fontWeight = FontWeight.Bold, color = Color.White, fontSize = 15.5.sp, modifier = Modifier.weight(1f))
                IconButton(onClick = onDismiss) { Icon(Icons.Default.Close, contentDescription = "Close", tint = Color.White) }
            }
            SelectionContainer {
                Text(
                    text = markdown,
                    fontFamily = JetBrainsMonoFontFamily,
                    fontSize = 11.5.sp,
                    color = AppColors.MainText,
                    lineHeight = 17.sp,
                    modifier = Modifier
                        .verticalScroll(rememberScrollState())
                        .padding(16.dp),
                )
            }
        }
    }
}
