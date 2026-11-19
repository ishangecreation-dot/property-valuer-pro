package com.propertyvaluerpro.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.HelpOutline
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.CurrencyFormatter
import com.propertyvaluerpro.app.data.models.ValuationProject
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily

@Composable
fun SectionCard(
    title: String,
    subtitle: String? = null,
    isMandatory: Boolean = false,
    trailing: (@Composable () -> Unit)? = null,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(bottom = 14.dp),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Cards),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.5.dp),
        border = BorderStroke(1.dp, AppColors.Borders),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(
                    modifier = Modifier.weight(1f),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = title,
                        fontFamily = ManropeFontFamily,
                        fontSize = 15.5.sp,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.PrimaryNavy,
                    )
                    if (isMandatory) {
                        Spacer(Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(AppColors.AntiqueGold.copy(alpha = 0.2f))
                                .padding(horizontal = 6.dp, vertical = 2.dp),
                        ) {
                            Text(
                                text = "REQUIRED",
                                fontSize = 9.5.sp,
                                fontWeight = FontWeight.ExtraBold,
                                color = AppColors.GoldDarkText,
                            )
                        }
                    }
                }
                if (trailing != null) {
                    Spacer(Modifier.width(8.dp))
                    trailing()
                }
            }
            if (!subtitle.isNullOrBlank()) {
                Spacer(Modifier.height(4.dp))
                Text(
                    text = subtitle,
                    fontSize = 12.5.sp,
                    color = AppColors.SecondaryText,
                    lineHeight = 17.sp,
                )
            }
            HorizontalDivider(
                modifier = Modifier.padding(vertical = 12.dp),
                color = AppColors.Borders,
            )
            content()
        }
    }
}

@Composable
fun LabeledTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    hint: String = "",
    isRequired: Boolean = false,
    isUncertain: Boolean = false,
    keyboardType: KeyboardType = KeyboardType.Text,
    minLines: Int = 1,
    maxLines: Int = 1,
    leadingIcon: ImageVector? = null,
    testTag: String? = null,
    modifier: Modifier = Modifier,
) {
    Column(modifier = modifier.fillMaxWidth().padding(bottom = 12.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = label,
                    fontSize = 13.5.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.MainText,
                )
                if (isRequired) {
                    Text(
                        text = " *",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.Error,
                    )
                }
            }
            if (isUncertain) {
                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .background(AppColors.Warning.copy(alpha = 0.15f))
                        .padding(horizontal = 6.dp, vertical = 2.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Default.HelpOutline, contentDescription = null, tint = AppColors.Warning, modifier = Modifier.size(12.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(
                        text = "Verify AI",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.Warning,
                    )
                }
            }
        }
        Spacer(Modifier.height(5.dp))
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier
                .fillMaxWidth()
                .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
            placeholder = {
                if (hint.isNotEmpty()) {
                    Text(hint, fontSize = 13.5.sp, color = AppColors.SecondaryText.copy(alpha = 0.7f))
                }
            },
            leadingIcon = if (leadingIcon != null) {
                { Icon(leadingIcon, contentDescription = null, tint = AppColors.PrimaryNavy, modifier = Modifier.size(19.dp)) }
            } else null,
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
            singleLine = maxLines == 1,
            minLines = minLines,
            maxLines = maxLines,
            shape = RoundedCornerShape(8.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = if (isUncertain) AppColors.UncertainBg else Color.White,
                unfocusedContainerColor = if (isUncertain) AppColors.UncertainBg else Color.White,
                focusedBorderColor = if (isUncertain) AppColors.Warning else AppColors.PrimaryNavy,
                unfocusedBorderColor = AppColors.Borders,
                focusedTextColor = AppColors.MainText,
                unfocusedTextColor = AppColors.MainText,
            ),
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun SelectableChipGroup(
    label: String,
    options: List<String>,
    selected: String,
    selectedColor: Color = AppColors.PrimaryNavy,
    onSelected: (String) -> Unit,
) {
    Column(modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp)) {
        Text(label, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = AppColors.MainText)
        Spacer(Modifier.height(6.dp))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            options.forEach { option ->
                val isSel = option == selected
                FilterChip(
                    selected = isSel,
                    onClick = { onSelected(option) },
                    label = {
                        Text(
                            text = option,
                            fontSize = 12.sp,
                            fontWeight = if (isSel) FontWeight.Bold else FontWeight.Normal,
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = selectedColor,
                        selectedLabelColor = Color.White,
                        containerColor = AppColors.SurfaceContainerLow,
                        labelColor = AppColors.MainText,
                    ),
                )
            }
        }
    }
}

@Composable
fun LiveCalculationCard(project: ValuationProject) {
    val perches = project.surveyPlanData.selectedTotalPerches.takeIf { it > 0 } ?: 15.0
    val valData = project.valuationData
    val landVal = valData.computeLandValue(perches)
    val hasBuilding = project.buildingDetails.hasBuilding && !project.buildingSketch.isBareLand
    val totalArea = project.buildingDetails.totalBuiltUpArea.takeIf { it > 0 } ?: if (hasBuilding) 1500.0 else 0.0
    val grc = valData.computeGrc(totalArea, hasBuilding)
    val dep = valData.computeDepreciation(grc)
    val bldgVal = valData.computeDepreciatedBuildingValue(grc, dep)
    val computedMarketVal = valData.computeTotalMarketValue(perches, totalArea, hasBuilding)
    val sayVal = valData.computeSayValue(computedMarketVal)
    val fsvVal = valData.computeFsv(sayVal)

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.PrimaryNavy),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Calculate, contentDescription = null, tint = AppColors.AntiqueGold, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(
                        text = "Live Valuation Summary",
                        fontFamily = ManropeFontFamily,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                    )
                }
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .background(AppColors.AntiqueGold.copy(alpha = 0.2f))
                        .padding(horizontal = 8.dp, vertical = 2.dp),
                ) {
                    Text("AUTO-CALCULATED", fontSize = 10.sp, fontWeight = FontWeight.ExtraBold, color = AppColors.AntiqueGold)
                }
            }
            HorizontalDivider(color = AppColors.PrimaryNavyBorder)

            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                MathBreakdownRow(
                    label = "Land Value (${"%.2f".format(perches)} P @ ${CurrencyFormatter.formatLkr(valData.adoptedLandRatePerPerch)}/P)",
                    value = CurrencyFormatter.formatLkr(landVal),
                    color = Color.White.copy(alpha = 0.78f),
                )
                if (hasBuilding) {
                    MathBreakdownRow("Building GRC (${totalArea.toInt()} sq.ft.)", CurrencyFormatter.formatLkr(grc), Color.White.copy(alpha = 0.78f))
                    MathBreakdownRow("Less Depreciation (${valData.depreciationPercentage.toInt()}%)", "- ${CurrencyFormatter.formatLkr(dep)}", Color(0xFFFC8181))
                    MathBreakdownRow("Depreciated Building Value", CurrencyFormatter.formatLkr(bldgVal), Color.White.copy(alpha = 0.78f))
                } else {
                    MathBreakdownRow("Building Value (Bare Land)", "Nil (Bare Land Only)", Color.White.copy(alpha = 0.55f))
                }
                HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp), color = AppColors.PrimaryNavyBorder)
                MathBreakdownRow("Total Computed Market Value", CurrencyFormatter.formatLkr(computedMarketVal), Color.White, bold = true)
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.PrimaryNavyDark)
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text("MARKET VALUE (SAY)", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.7f))
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = CurrencyFormatter.formatLkr(sayVal),
                        fontFamily = JetBrainsMonoFontFamily,
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.AntiqueGold,
                    )
                }
                Box(modifier = Modifier.width(1.dp).height(34.dp).background(AppColors.PrimaryNavyBorder))
                Spacer(Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text("FSV (${valData.fsvPercentage.toInt()}%)", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.7f))
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = CurrencyFormatter.formatLkr(fsvVal),
                        fontFamily = JetBrainsMonoFontFamily,
                        fontSize = 13.5.sp,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.PrimaryActionTeal,
                    )
                }
            }
        }
    }
}

@Composable
private fun MathBreakdownRow(label: String, value: String, color: Color, bold: Boolean = false) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            fontSize = 12.5.sp,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            color = color,
            modifier = Modifier.weight(1f).padding(end = 8.dp),
        )
        Text(
            text = value,
            fontFamily = JetBrainsMonoFontFamily,
            fontSize = 12.5.sp,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Medium,
            color = color,
        )
    }
}
