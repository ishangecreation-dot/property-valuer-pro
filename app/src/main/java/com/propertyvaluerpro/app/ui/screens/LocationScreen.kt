package com.propertyvaluerpro.app.ui.screens

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager
import androidx.activity.compose.rememberLauncherForActivityResult
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.propertyvaluerpro.app.data.models.LocationData
import com.propertyvaluerpro.app.ui.components.LabeledTextField
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.components.SelectableChipGroup
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState

@Composable
fun LocationScreen(
    uiState: AppUiState,
    onSaveLocation: (LocationData) -> Unit,
    onPolishDirections: (String, (String) -> Unit) -> Unit,
    onShowMessage: (String, Boolean) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val context = LocalContext.current
    val initial = uiState.activeProject?.locationData ?: LocationData()

    var latText by remember(initial) { mutableStateOf("%.6f".format(initial.latitude)) }
    var lngText by remember(initial) { mutableStateOf("%.6f".format(initial.longitude)) }
    var nearestTown by remember(initial) { mutableStateOf(initial.nearestTown) }
    var startingJunction by remember(initial) { mutableStateOf(initial.startingJunction) }
    var accessDirections by remember(initial) { mutableStateOf(initial.accessDirections) }
    var distanceKm by remember(initial) { mutableStateOf(initial.distanceFromTownKm.toString()) }
    var roadWidthFt by remember(initial) { mutableStateOf(initial.accessRoadWidthFt.toString()) }
    var roadSurface by remember(initial) { mutableStateOf(initial.roadSurface) }
    var roadCondition by remember(initial) { mutableStateOf(initial.roadCondition) }
    var vehicleAccess by remember(initial) { mutableStateOf(initial.vehicleAccessibility) }
    var selectedUtilities by remember(initial) { mutableStateOf(initial.utilities) }

    val roadSurfaceOptions = listOf("Carpet", "Tarred", "Concrete", "Interlock Paved", "Gravel", "Earth / Unpaved")
    val roadConditionOptions = listOf("Excellent", "Good", "Fair", "Dilapidated")
    val vehicleOptions = listOf("All Vehicles", "Heavy Vehicles", "Light Vehicles / Cars", "Three-Wheelers Only", "Footpath Only")
    val allUtilityOptions = listOf(
        "CEB Electricity (Single Phase)",
        "CEB Electricity (Three Phase)",
        "NWSDB Piped Water",
        "Deep Well / Tube Well Water",
        "Telecommunications & Optical Fiber",
        "Public Bus Route Frontage",
        "Municipal Garbage Collection",
        "Storm Water Drainage",
    )

    fun buildLocationData() = LocationData(
        latitude = latText.toDoubleOrNull() ?: initial.latitude,
        longitude = lngText.toDoubleOrNull() ?: initial.longitude,
        nearestTown = nearestTown.trim(),
        startingJunction = startingJunction.trim(),
        accessDirections = accessDirections.trim(),
        distanceFromTownKm = distanceKm.toDoubleOrNull() ?: initial.distanceFromTownKm,
        accessRoadWidthFt = roadWidthFt.toDoubleOrNull() ?: initial.accessRoadWidthFt,
        roadSurface = roadSurface,
        roadCondition = roadCondition,
        vehicleAccessibility = vehicleAccess,
        utilities = selectedUtilities,
    )

    @SuppressLint("MissingPermission")
    fun detectLastKnownGps() {
        val locManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (locManager == null) {
            onShowMessage("Location service unavailable. Enter GIS coordinates manually.", true)
            return
        }
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)
        val bestLoc = providers
            .mapNotNull { runCatching { locManager.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }

        if (bestLoc != null) {
            latText = "%.6f".format(bestLoc.latitude)
            lngText = "%.6f".format(bestLoc.longitude)
            onShowMessage("GPS coordinates detected: $latText, $lngText", false)
        } else {
            onShowMessage("No cached GPS fix on this device yet. Please enter coordinates manually or set emulator location.", true)
        }
    }

    val locationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { grants ->
        val granted = grants[Manifest.permission.ACCESS_FINE_LOCATION] == true ||
            grants[Manifest.permission.ACCESS_COARSE_LOCATION] == true
        if (granted) {
            detectLastKnownGps()
        } else {
            onShowMessage("Location permission denied. You can still enter GIS coordinates manually.", true)
        }
    }

    ResponsiveWorkflowScaffold(
        currentStep = 6,
        title = "Situation & Accessibility",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = { step ->
            onSaveLocation(buildLocationData())
            onNavigateToStep(step)
        },
        onOpenSettings = onOpenSettings,
        onBack = {
            onSaveLocation(buildLocationData())
            onBack()
        },
        onNext = {
            onSaveLocation(buildLocationData())
            onNext()
        },
        nextLabel = "Save & Continue to Sketch",
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
                title = "GIS Geolocation & Pin Coordinates",
                subtitle = "WGS-84 coordinates embedded into the Location & Situation section of the final report.",
                trailing = {
                    OutlinedButton(
                        onClick = {
                            val fineGranted = ContextCompat.checkSelfPermission(
                                context,
                                Manifest.permission.ACCESS_FINE_LOCATION,
                            ) == PackageManager.PERMISSION_GRANTED
                            val coarseGranted = ContextCompat.checkSelfPermission(
                                context,
                                Manifest.permission.ACCESS_COARSE_LOCATION,
                            ) == PackageManager.PERMISSION_GRANTED
                            if (fineGranted || coarseGranted) {
                                detectLastKnownGps()
                            } else {
                                locationPermissionLauncher.launch(
                                    arrayOf(
                                        Manifest.permission.ACCESS_FINE_LOCATION,
                                        Manifest.permission.ACCESS_COARSE_LOCATION,
                                    ),
                                )
                            }
                        },
                        modifier = Modifier.testTag("detect_gps_button"),
                        shape = RoundedCornerShape(8.dp),
                    ) {
                        Icon(Icons.Default.MyLocation, contentDescription = null, modifier = Modifier.size(16.dp), tint = AppColors.PrimaryActionTeal)
                        Spacer(Modifier.width(6.dp))
                        Text("Detect GPS", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = AppColors.PrimaryActionTeal)
                    }
                },
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(AppColors.SurfaceContainerLow)
                        .border(1.dp, AppColors.Borders, RoundedCornerShape(8.dp))
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(Icons.Default.LocationOn, contentDescription = null, tint = AppColors.PrimaryActionTeal, modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(10.dp))
                    Column {
                        Text("Active GIS Pin (WGS-84)", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = AppColors.SecondaryText)
                        Text(
                            text = "${latText.ifBlank { "0.000000" }}° N, ${lngText.ifBlank { "0.000000" }}° E",
                            fontFamily = JetBrainsMonoFontFamily,
                            fontSize = 13.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.PrimaryNavy,
                        )
                    }
                }
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField(
                        label = "Latitude (°N)",
                        value = latText,
                        onValueChange = { latText = it },
                        hint = "e.g., 7.240500",
                        keyboardType = KeyboardType.Decimal,
                        testTag = "latitude_input",
                        modifier = Modifier.weight(1f),
                    )
                    LabeledTextField(
                        label = "Longitude (°E)",
                        value = lngText,
                        onValueChange = { lngText = it },
                        hint = "e.g., 80.592500",
                        keyboardType = KeyboardType.Decimal,
                        testTag = "longitude_input",
                        modifier = Modifier.weight(1f),
                    )
                }
            }

            SectionCard(
                title = "Access Route & Formal Driving Directions",
                subtitle = "Describe the route from the nearest town or landmark junction.",
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    LabeledTextField(
                        label = "Nearest Main Town",
                        value = nearestTown,
                        onValueChange = { nearestTown = it },
                        hint = "e.g., Peradeniya / Maharagama",
                        isRequired = true,
                        testTag = "nearest_town_input",
                        modifier = Modifier.weight(1f),
                    )
                    LabeledTextField(
                        label = "Distance (km)",
                        value = distanceKm,
                        onValueChange = { distanceKm = it },
                        hint = "2.5",
                        keyboardType = KeyboardType.Decimal,
                        modifier = Modifier.weight(0.65f),
                    )
                }
                LabeledTextField(
                    label = "Starting Junction / Landmark",
                    value = startingJunction,
                    onValueChange = { startingJunction = it },
                    hint = "e.g., Peradeniya Clock Tower Junction",
                )
                LabeledTextField(
                    label = "Access Directions Narrative",
                    value = accessDirections,
                    onValueChange = { accessDirections = it },
                    hint = "e.g., Proceed from Peradeniya Town along Kandy-Colombo Road for 2 km, turn left onto Temple Road and proceed 500m...",
                    minLines = 3,
                    maxLines = 6,
                    testTag = "access_directions_input",
                )
                Button(
                    onClick = {
                        if (accessDirections.isBlank()) {
                            onShowMessage("Enter draft access directions first.", true)
                        } else {
                            onPolishDirections(accessDirections) { polished ->
                                accessDirections = polished
                            }
                        }
                    },
                    enabled = !uiState.isPolishingText,
                    modifier = Modifier.fillMaxWidth().height(46.dp).testTag("polish_directions_button"),
                    shape = RoundedCornerShape(8.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryNavy),
                ) {
                    if (uiState.isPolishingText) {
                        CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White)
                        Spacer(Modifier.width(8.dp))
                        Text("Polishing Valuation Phrasing...", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    } else {
                        Icon(Icons.Default.AutoAwesome, contentDescription = null, tint = AppColors.AntiqueGold, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Convert to Formal Valuation Phrasing (AI)", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                }
            }

            SectionCard(
                title = "Roadway Width, Surface & Vehicle Accessibility",
                subtitle = "Critical bank collateral parameters for right-of-way compliance.",
            ) {
                LabeledTextField(
                    label = "Access Road Width (ft)",
                    value = roadWidthFt,
                    onValueChange = { roadWidthFt = it },
                    hint = "e.g., 15",
                    keyboardType = KeyboardType.Decimal,
                )
                SelectableChipGroup(
                    label = "Road Surface Type",
                    options = roadSurfaceOptions,
                    selected = roadSurface,
                    onSelected = { roadSurface = it },
                )
                SelectableChipGroup(
                    label = "Road Condition",
                    options = roadConditionOptions,
                    selected = roadCondition,
                    selectedColor = AppColors.PrimaryActionTeal,
                    onSelected = { roadCondition = it },
                )
                SelectableChipGroup(
                    label = "Vehicle Accessibility",
                    options = vehicleOptions,
                    selected = vehicleAccess,
                    onSelected = { vehicleAccess = it },
                )
            }

            SectionCard(
                title = "Public Utilities & Services Available",
                subtitle = "Select all services connected or immediately available at the property frontage.",
            ) {
                allUtilityOptions.forEach { util ->
                    val checked = selectedUtilities.contains(util)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Checkbox(
                            checked = checked,
                            onCheckedChange = { isChecked ->
                                selectedUtilities = if (isChecked) {
                                    (selectedUtilities + util).distinct()
                                } else {
                                    selectedUtilities - util
                                }
                            },
                            colors = CheckboxDefaults.colors(checkedColor = AppColors.PrimaryActionTeal),
                        )
                        Text(util, fontSize = 13.sp, color = AppColors.MainText)
                    }
                }
            }

            Spacer(Modifier.height(16.dp))
        }
    }
}
