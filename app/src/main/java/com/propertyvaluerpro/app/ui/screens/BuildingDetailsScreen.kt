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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.propertyvaluerpro.app.data.models.BuildingDetails
import com.propertyvaluerpro.app.data.models.BuildingSpecification
import com.propertyvaluerpro.app.data.models.PropertyPhoto
import com.propertyvaluerpro.app.ui.components.LabeledTextField
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.components.SectionCard
import com.propertyvaluerpro.app.ui.components.SelectableChipGroup
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import java.io.File

@Composable
fun BuildingDetailsScreen(
    uiState: AppUiState,
    onSaveBuildingDetails: (BuildingDetails) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val context = LocalContext.current
    val initial = uiState.activeProject?.buildingDetails ?: BuildingDetails()
    val firstBuilding = initial.buildings.firstOrNull() ?: BuildingSpecification()

    var hasBuilding by remember(initial) {
        mutableStateOf(initial.hasBuilding && !(uiState.activeProject?.buildingSketch?.isBareLand ?: false))
    }
    var buildingName by remember(initial) { mutableStateOf(firstBuilding.buildingName) }
    var roofType by remember(initial) { mutableStateOf(firstBuilding.roofType) }
    var wallType by remember(initial) { mutableStateOf(firstBuilding.wallType) }
    var floorType by remember(initial) { mutableStateOf(firstBuilding.floorType) }
    var doorsWindows by remember(initial) { mutableStateOf(firstBuilding.doorsWindows) }
    var bathFittings by remember(initial) { mutableStateOf(firstBuilding.bathFittings) }
    var ageYears by remember(initial) { mutableStateOf(firstBuilding.ageYears.toString()) }
    var condition by remember(initial) { mutableStateOf(firstBuilding.structuralCondition) }
    var occupancy by remember(initial) { mutableStateOf(firstBuilding.occupancy) }
    var groundArea by remember(initial) { mutableStateOf(firstBuilding.groundFloorAreaSqFt.toString()) }
    var upperArea by remember(initial) { mutableStateOf(firstBuilding.upperFloorAreaSqFt.toString()) }
    var rooms by remember(initial) { mutableStateOf(firstBuilding.roomCounters.ifEmpty { BuildingSpecification.defaultRooms() }) }

    var landShape by remember(initial) { mutableStateOf(initial.landShape) }
    var landTopography by remember(initial) { mutableStateOf(initial.landTopography) }
    var subsoil by remember(initial) { mutableStateOf(initial.subsoilCondition) }
    var boundaries by remember(initial) { mutableStateOf(initial.boundaryDemarcations) }
    var additionalRemarks by remember(initial) { mutableStateOf(initial.additionalRemarks) }
    var photos by remember(initial) { mutableStateOf(initial.photographs.ifEmpty { BuildingDetails.defaultPhotos() }) }

    var activePhotoSlotIndex by remember { mutableIntStateOf(0) }
    var pendingCameraFile by remember { mutableStateOf<File?>(null) }

    val roofOptions = listOf(
        "Asbestos on Timber Rafters",
        "Calicut Clay Tiles on Timber",
        "Zn/Al Color-Bonded Sheets",
        "Reinforced Concrete Flat Roof",
    )
    val wallOptions = listOf(
        "Brick Masonry, Plastered & Painted",
        "Cement Block Masonry, Plastered",
        "RCC Frame with Brick Infill",
    )
    val floorOptions = listOf(
        "Ceramic Tiled",
        "Porcelain / Titanium Cut-Cement",
        "Cement Rendered",
        "Terrazzo / Granite",
    )
    val conditionOptions = listOf("Excellent / New", "Good", "Fair / Average", "Needs Renovation")
    val occupancyOptions = listOf("Owner Occupied", "Tenanted / Leased", "Vacant", "Under Construction")

    fun buildDetails(): BuildingDetails {
        val spec = BuildingSpecification(
            buildingName = buildingName.trim().ifBlank { "Main Residential Building" },
            roofType = roofType,
            wallType = wallType,
            floorType = floorType,
            doorsWindows = doorsWindows.trim(),
            bathFittings = bathFittings.trim(),
            ageYears = ageYears.toIntOrNull() ?: 5,
            structuralCondition = condition,
            occupancy = occupancy,
            groundFloorAreaSqFt = groundArea.toDoubleOrNull() ?: 0.0,
            upperFloorAreaSqFt = upperArea.toDoubleOrNull() ?: 0.0,
            roomCounters = rooms,
        )
        return BuildingDetails(
            hasBuilding = hasBuilding,
            buildings = listOf(spec),
            landShape = landShape.trim(),
            landTopography = landTopography.trim(),
            subsoilCondition = subsoil.trim(),
            boundaryDemarcations = boundaries.trim(),
            additionalRemarks = additionalRemarks.trim(),
            photographs = photos,
        )
    }

    fun updatePhotoAt(idx: Int, path: String) {
        if (idx !in photos.indices) return
        photos = photos.toMutableList().also { list ->
            list[idx] = list[idx].copy(filePath = path)
        }
    }

    val photoPicker = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri: Uri? ->
        uri?.let { updatePhotoAt(activePhotoSlotIndex, it.toString()) }
    }

    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { success ->
        if (success) {
            pendingCameraFile?.absolutePath?.let { updatePhotoAt(activePhotoSlotIndex, it) }
        }
    }

    val cameraPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) {
            val (file, uri) = createCaptureFile(context, "photo_slot_$activePhotoSlotIndex")
            pendingCameraFile = file
            cameraLauncher.launch(uri)
        }
    }

    ResponsiveWorkflowScaffold(
        currentStep = 8,
        title = "Building Details & Photos",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = { step ->
            onSaveBuildingDetails(buildDetails())
            onNavigateToStep(step)
        },
        onOpenSettings = onOpenSettings,
        onBack = {
            onSaveBuildingDetails(buildDetails())
            onBack()
        },
        onNext = {
            onSaveBuildingDetails(buildDetails())
            onNext()
        },
        nextLabel = "Save & Continue to Valuation",
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
                title = "Building Improvements Toggle",
                subtitle = "Disable if valuing bare land only.",
                trailing = {
                    Switch(
                        checked = hasBuilding,
                        onCheckedChange = { hasBuilding = it },
                        modifier = Modifier.testTag("has_building_switch"),
                        colors = SwitchDefaults.colors(checkedThumbColor = Color.White, checkedTrackColor = AppColors.PrimaryActionTeal),
                    )
                },
            ) {
                Text(
                    text = if (hasBuilding) {
                        "Building specification & accommodation metrics are active and linked to Step 9 GRC valuation."
                    } else {
                        "Bare Land Mode enabled — building construction specs are omitted from valuation."
                    },
                    fontSize = 12.5.sp,
                    color = AppColors.SecondaryText,
                )
            }

            if (hasBuilding) {
                SectionCard(
                    title = "Construction Specifications",
                    subtitle = "Standard Chartered Valuer inspection criteria.",
                ) {
                    LabeledTextField("Building Designation", buildingName, { buildingName = it }, "Main Residential Building")
                    SelectableChipGroup("Roofing Specification", roofOptions, roofType) { roofType = it }
                    SelectableChipGroup("Wall Construction", wallOptions, wallType) { wallType = it }
                    SelectableChipGroup("Floor Finish", floorOptions, floorType) { floorType = it }
                    LabeledTextField("Doors & Windows", doorsWindows, { doorsWindows = it }, "Timber Panel & Window Grills")
                    LabeledTextField("Sanitary & Bath Fittings", bathFittings, { bathFittings = it }, "Commode, Wash Basin, Complete")

                    val totalArea = (groundArea.toDoubleOrNull() ?: 0.0) + (upperArea.toDoubleOrNull() ?: 0.0)
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        LabeledTextField(
                            label = "Ground Floor (sq.ft.)",
                            value = groundArea,
                            onValueChange = { groundArea = it },
                            keyboardType = KeyboardType.Decimal,
                            testTag = "ground_floor_area_input",
                            modifier = Modifier.weight(1f),
                        )
                        LabeledTextField(
                            label = "Upper Floor (sq.ft.)",
                            value = upperArea,
                            onValueChange = { upperArea = it },
                            keyboardType = KeyboardType.Decimal,
                            modifier = Modifier.weight(1f),
                        )
                    }
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .background(AppColors.SurfaceContainerLow)
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text("Total Built-Up Floor Area", fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = AppColors.PrimaryNavy)
                        Text(
                            text = "${"%.0f".format(totalArea)} sq.ft.",
                            fontFamily = JetBrainsMonoFontFamily,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.PrimaryActionTeal,
                        )
                    }
                    Spacer(Modifier.height(12.dp))
                    LabeledTextField("Estimated Age (Years)", ageYears, { ageYears = it }, "5", keyboardType = KeyboardType.Number)
                    SelectableChipGroup("Structural Condition", conditionOptions, condition, AppColors.PrimaryActionTeal) { condition = it }
                    SelectableChipGroup("Occupancy Status", occupancyOptions, occupancy) { occupancy = it }
                }

                SectionCard(
                    title = "Accommodation Schedule",
                    subtitle = "Adjust room counts using +/- steppers.",
                ) {
                    rooms.forEachIndexed { idx, room ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(room.name, fontSize = 13.5.sp, fontWeight = FontWeight.Medium, color = AppColors.MainText)
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                IconButton(
                                    onClick = {
                                        if (room.count > 0) {
                                            rooms = rooms.toMutableList().also { it[idx] = room.copy(count = room.count - 1) }
                                        }
                                    },
                                    modifier = Modifier.size(36.dp),
                                ) {
                                    Icon(Icons.Default.Remove, contentDescription = "Decrease ${room.name}", tint = AppColors.PrimaryNavy)
                                }
                                Text(
                                    text = "${room.count}",
                                    fontFamily = JetBrainsMonoFontFamily,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = AppColors.PrimaryNavy,
                                    modifier = Modifier.width(28.dp),
                                )
                                IconButton(
                                    onClick = {
                                        rooms = rooms.toMutableList().also { it[idx] = room.copy(count = room.count + 1) }
                                    },
                                    modifier = Modifier.size(36.dp),
                                ) {
                                    Icon(Icons.Default.Add, contentDescription = "Increase ${room.name}", tint = AppColors.PrimaryActionTeal)
                                }
                            }
                        }
                        if (idx < rooms.lastIndex) HorizontalDivider(color = AppColors.Borders)
                    }
                }
            }

            SectionCard(
                title = "Land Characteristics & Boundaries",
                subtitle = "Site topography, soil bearing capacity, and physical demarcations.",
            ) {
                LabeledTextField("Shape of Land", landShape, { landShape = it }, "Regular / Rectangular")
                LabeledTextField("Topography & Elevation", landTopography, { landTopography = it }, "Flat at road grade")
                LabeledTextField("Subsoil Condition", subsoil, { subsoil = it }, "Firm, gravelly clay loam")
                LabeledTextField("Boundary Demarcations", boundaries, { boundaries = it }, "Parapet wall and barbed wire fence")
                LabeledTextField("Additional Inspection Remarks", additionalRemarks, { additionalRemarks = it }, "Any defects, encroachments, or drainage notes", minLines = 2, maxLines = 4)
            }

            SectionCard(
                title = "Property Photograph Register (4 Slots)",
                subtitle = "Attach inspection photographs via camera or Android Photo Picker.",
            ) {
                val rows = photos.chunked(2)
                rows.forEachIndexed { rowIdx, rowPhotos ->
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(bottom = 10.dp),
                        horizontalArrangement = Arrangement.spacedBy(10.dp),
                    ) {
                        rowPhotos.forEachIndexed { colIdx, photo ->
                            val slotIdx = rowIdx * 2 + colIdx
                            PhotoSlotCard(
                                photo = photo,
                                modifier = Modifier.weight(1f),
                                onCamera = {
                                    activePhotoSlotIndex = slotIdx
                                    val granted = ContextCompat.checkSelfPermission(
                                        context,
                                        Manifest.permission.CAMERA,
                                    ) == PackageManager.PERMISSION_GRANTED
                                    if (granted) {
                                        val (file, uri) = createCaptureFile(context, "photo_slot_$slotIdx")
                                        pendingCameraFile = file
                                        cameraLauncher.launch(uri)
                                    } else {
                                        cameraPermissionLauncher.launch(Manifest.permission.CAMERA)
                                    }
                                },
                                onGallery = {
                                    activePhotoSlotIndex = slotIdx
                                    photoPicker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                                },
                            )
                        }
                        if (rowPhotos.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }

            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun PhotoSlotCard(
    photo: PropertyPhoto,
    modifier: Modifier = Modifier,
    onCamera: () -> Unit,
    onGallery: () -> Unit,
) {
    val hasFile = photo.filePath.isNotBlank()
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(if (hasFile) AppColors.Success.copy(alpha = 0.08f) else AppColors.SurfaceContainerLow)
            .border(1.dp, if (hasFile) AppColors.Success else AppColors.Borders, RoundedCornerShape(10.dp))
            .padding(10.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (hasFile) {
                Icon(Icons.Default.CheckCircle, contentDescription = null, tint = AppColors.Success, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(5.dp))
            }
            Text(
                text = photo.slotName,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = AppColors.PrimaryNavy,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.height(4.dp))
        Text(
            text = if (hasFile) "Photo attached" else "No image attached",
            fontSize = 11.sp,
            color = if (hasFile) AppColors.Success else AppColors.SecondaryText,
        )
        Spacer(Modifier.height(8.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            OutlinedButton(
                onClick = onCamera,
                modifier = Modifier.weight(1f).height(34.dp),
                shape = RoundedCornerShape(6.dp),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 4.dp),
            ) {
                Icon(Icons.Default.CameraAlt, contentDescription = "Capture ${photo.slotName}", modifier = Modifier.size(15.dp))
            }
            OutlinedButton(
                onClick = onGallery,
                modifier = Modifier.weight(1f).height(34.dp),
                shape = RoundedCornerShape(6.dp),
                contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 4.dp),
            ) {
                Icon(Icons.Default.PhotoLibrary, contentDescription = "Pick ${photo.slotName}", modifier = Modifier.size(15.dp))
            }
        }
    }
}
