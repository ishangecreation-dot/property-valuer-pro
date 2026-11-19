package com.propertyvaluerpro.app.ui.screens

import android.graphics.Paint
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
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
import androidx.compose.material.icons.automirrored.filled.Redo
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Circle
import androidx.compose.material.icons.filled.CropSquare
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Draw
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.ScreenRotation
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
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
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.data.models.BuildingSketch
import com.propertyvaluerpro.app.data.models.SketchElement
import com.propertyvaluerpro.app.data.models.SketchPoint
import com.propertyvaluerpro.app.data.models.SketchTool
import com.propertyvaluerpro.app.ui.components.ResponsiveWorkflowScaffold
import com.propertyvaluerpro.app.ui.theme.AppColors
import com.propertyvaluerpro.app.ui.theme.JetBrainsMonoFontFamily
import com.propertyvaluerpro.app.ui.theme.ManropeFontFamily
import com.propertyvaluerpro.app.ui.viewmodel.AppUiState
import kotlin.math.hypot
import kotlin.math.min

@Composable
fun A3SketchingScreen(
    uiState: AppUiState,
    onSaveSketch: (BuildingSketch) -> Unit,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onNavigateToStep: (Int) -> Unit,
    onOpenSettings: () -> Unit,
    onSnackbarDismissed: () -> Unit,
) {
    val initial = uiState.activeProject?.buildingSketch ?: BuildingSketch()

    var isBareLand by remember(initial) { mutableStateOf(initial.isBareLand) }
    var isLandscape by remember(initial) { mutableStateOf(initial.isLandscape) }
    var elements by remember(initial) { mutableStateOf(initial.elements) }
    var redoStack by remember { mutableStateOf<List<SketchElement>>(emptyList()) }
    var activeTool by remember { mutableStateOf(SketchTool.RECTANGLE) }
    var inProgressElement by remember { mutableStateOf<SketchElement?>(null) }
    var pendingTextPoint by remember { mutableStateOf<SketchPoint?>(null) }
    var textInput by remember { mutableStateOf("") }

    fun buildSketch() = BuildingSketch(
        isBareLand = isBareLand,
        isLandscape = isLandscape,
        scaleRatio = initial.scaleRatio,
        elements = elements,
    )

    if (pendingTextPoint != null) {
        AlertDialog(
            onDismissRequest = { pendingTextPoint = null },
            title = { Text("Add Room / Dimension Label", fontWeight = FontWeight.Bold, color = AppColors.PrimaryNavy) },
            text = {
                OutlinedTextField(
                    value = textInput,
                    onValueChange = { textInput = it },
                    label = { Text("Label Text") },
                    placeholder = { Text("e.g., Master Bedroom 14' x 12'") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        val pt = pendingTextPoint
                        if (pt != null && textInput.isNotBlank()) {
                            elements = elements + SketchElement(
                                id = System.currentTimeMillis().toString(),
                                tool = SketchTool.TEXT,
                                points = listOf(pt),
                                textLabel = textInput.trim(),
                            )
                            redoStack = emptyList()
                        }
                        textInput = ""
                        pendingTextPoint = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
                ) { Text("Place Label") }
            },
            dismissButton = {
                TextButton(onClick = {
                    textInput = ""
                    pendingTextPoint = null
                }) { Text("Cancel") }
            },
        )
    }

    ResponsiveWorkflowScaffold(
        currentStep = 7,
        title = "A3 Building Sketch (Mini-CAD)",
        screens3To10Frozen = uiState.screens3To10Frozen,
        onStepSelected = { step ->
            onSaveSketch(buildSketch())
            onNavigateToStep(step)
        },
        onOpenSettings = onOpenSettings,
        onBack = {
            onSaveSketch(buildSketch())
            onBack()
        },
        onNext = {
            onSaveSketch(buildSketch())
            onNext()
        },
        nextLabel = "Save & Continue to Building",
        snackbarMessage = uiState.snackbarMessage,
        snackbarIsError = uiState.snackbarIsError,
        onSnackbarDismissed = onSnackbarDismissed,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(14.dp),
        ) {
            // Bare Land vs Building Exists toggle strip
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.White)
                    .border(1.dp, AppColors.Borders, RoundedCornerShape(10.dp))
                    .padding(horizontal = 12.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                FilterChip(
                    selected = !isBareLand,
                    onClick = { isBareLand = false },
                    label = { Text("Building Exists (A3 Sketch)", fontSize = 12.sp, fontWeight = FontWeight.Bold) },
                    modifier = Modifier.weight(1f).testTag("sketch_mode_building"),
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AppColors.PrimaryNavy,
                        selectedLabelColor = Color.White,
                    ),
                )
                FilterChip(
                    selected = isBareLand,
                    onClick = { isBareLand = true },
                    label = { Text("Bare Land (Skip)", fontSize = 12.sp, fontWeight = FontWeight.Bold) },
                    modifier = Modifier.weight(1f).testTag("sketch_mode_bare_land"),
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AppColors.PrimaryActionTeal,
                        selectedLabelColor = Color.White,
                    ),
                )
            }

            Spacer(Modifier.height(12.dp))

            if (isBareLand) {
                Surface(
                    shape = RoundedCornerShape(14.dp),
                    color = Color.White,
                    border = androidx.compose.foundation.BorderStroke(1.dp, AppColors.Borders),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(
                        modifier = Modifier.padding(28.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Icon(
                            imageVector = Icons.Default.Landscape,
                            contentDescription = "Bare Land Mode",
                            tint = AppColors.PrimaryActionTeal,
                            modifier = Modifier.size(56.dp),
                        )
                        Spacer(Modifier.height(14.dp))
                        Text(
                            text = "Bare Land Assessment Mode",
                            fontFamily = ManropeFontFamily,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 18.sp,
                            color = AppColors.PrimaryNavy,
                        )
                        Spacer(Modifier.height(8.dp))
                        Text(
                            text = "No building floorplan sketch is required. The valuation engine will automatically omit GRC and Depreciation and value the property solely on Land Extent x Adopted Rate per Perch.",
                            fontSize = 13.sp,
                            color = AppColors.SecondaryText,
                            textAlign = TextAlign.Center,
                        )
                        Spacer(Modifier.height(18.dp))
                        Button(
                            onClick = {
                                onSaveSketch(buildSketch())
                                onNext()
                            },
                            modifier = Modifier.testTag("bare_land_proceed_button"),
                            colors = ButtonDefaults.buttonColors(containerColor = AppColors.PrimaryActionTeal),
                            shape = RoundedCornerShape(10.dp),
                        ) {
                            Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text("Confirm Bare Land & Proceed", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            } else {
                // CAD Toolbar
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = AppColors.PrimaryNavy,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column(modifier = Modifier.padding(10.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(4.dp))
                                        .background(AppColors.AntiqueGold.copy(alpha = 0.22f))
                                        .padding(horizontal = 8.dp, vertical = 3.dp),
                                ) {
                                    Text(
                                        text = "A3 • Scale 1\" = ${initial.scaleRatio.toInt()} ft",
                                        fontFamily = JetBrainsMonoFontFamily,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = AppColors.AntiqueGold,
                                    )
                                }
                                Spacer(Modifier.width(8.dp))
                                Text(
                                    text = "${elements.size} vectors",
                                    fontSize = 11.5.sp,
                                    color = Color.White.copy(alpha = 0.78f),
                                )
                            }
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                IconButton(
                                    onClick = { isLandscape = !isLandscape },
                                    modifier = Modifier.size(36.dp).testTag("toggle_orientation_button"),
                                ) {
                                    Icon(Icons.Default.ScreenRotation, contentDescription = "Toggle A3 Orientation", tint = Color.White, modifier = Modifier.size(18.dp))
                                }
                                IconButton(
                                    onClick = {
                                        if (elements.isNotEmpty()) {
                                            redoStack = redoStack + elements.last()
                                            elements = elements.dropLast(1)
                                        }
                                    },
                                    enabled = elements.isNotEmpty(),
                                    modifier = Modifier.size(36.dp).testTag("sketch_undo_button"),
                                ) {
                                    Icon(Icons.AutoMirrored.Filled.Undo, contentDescription = "Undo", tint = if (elements.isNotEmpty()) Color.White else Color.White.copy(alpha = 0.35f), modifier = Modifier.size(18.dp))
                                }
                                IconButton(
                                    onClick = {
                                        if (redoStack.isNotEmpty()) {
                                            elements = elements + redoStack.last()
                                            redoStack = redoStack.dropLast(1)
                                        }
                                    },
                                    enabled = redoStack.isNotEmpty(),
                                    modifier = Modifier.size(36.dp).testTag("sketch_redo_button"),
                                ) {
                                    Icon(Icons.AutoMirrored.Filled.Redo, contentDescription = "Redo", tint = if (redoStack.isNotEmpty()) Color.White else Color.White.copy(alpha = 0.35f), modifier = Modifier.size(18.dp))
                                }
                                IconButton(
                                    onClick = {
                                        elements = emptyList()
                                        redoStack = emptyList()
                                    },
                                    enabled = elements.isNotEmpty(),
                                    modifier = Modifier.size(36.dp).testTag("sketch_clear_button"),
                                ) {
                                    Icon(Icons.Default.DeleteSweep, contentDescription = "Clear Canvas", tint = if (elements.isNotEmpty()) Color(0xFFFC8181) else Color.White.copy(alpha = 0.35f), modifier = Modifier.size(18.dp))
                                }
                            }
                        }

                        Spacer(Modifier.height(8.dp))

                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .horizontalScroll(rememberScrollState()),
                            horizontalArrangement = Arrangement.spacedBy(6.dp),
                        ) {
                            ToolPill("Wall", Icons.Default.ShowChart, activeTool == SketchTool.LINE) { activeTool = SketchTool.LINE }
                            ToolPill("Room", Icons.Default.CropSquare, activeTool == SketchTool.RECTANGLE) { activeTool = SketchTool.RECTANGLE }
                            ToolPill("Circle", Icons.Default.Circle, activeTool == SketchTool.CIRCLE) { activeTool = SketchTool.CIRCLE }
                            ToolPill("Freehand", Icons.Default.Draw, activeTool == SketchTool.FREEHAND) { activeTool = SketchTool.FREEHAND }
                            ToolPill("Dim", Icons.Default.Straighten, activeTool == SketchTool.DIMENSION) { activeTool = SketchTool.DIMENSION }
                            ToolPill("Text", Icons.Default.TextFields, activeTool == SketchTool.TEXT) { activeTool = SketchTool.TEXT }
                        }
                    }
                }

                Spacer(Modifier.height(12.dp))

                // Exact A3 Aspect Ratio Architectural Drawing Sheet
                val ratio = if (isLandscape) 1.414f else 1f / 1.414f
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .aspectRatio(ratio)
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color.White)
                        .border(2.dp, AppColors.PrimaryNavy, RoundedCornerShape(8.dp))
                        .testTag("a3_cad_canvas"),
                ) {
                    Canvas(
                        modifier = Modifier
                            .fillMaxSize()
                            .pointerInput(activeTool) {
                                if (activeTool == SketchTool.TEXT) {
                                    detectTapGestures { offset ->
                                        pendingTextPoint = SketchPoint(
                                            x = offset.x / size.width.coerceAtLeast(1),
                                            y = offset.y / size.height.coerceAtLeast(1),
                                        )
                                    }
                                } else {
                                    detectDragGestures(
                                        onDragStart = { start ->
                                            val nx = start.x / size.width.coerceAtLeast(1)
                                            val ny = start.y / size.height.coerceAtLeast(1)
                                            inProgressElement = SketchElement(
                                                id = System.currentTimeMillis().toString(),
                                                tool = activeTool,
                                                points = listOf(SketchPoint(nx, ny)),
                                                strokeWidth = if (activeTool == SketchTool.DIMENSION) 2.2f else 3.5f,
                                                colorArgb = if (activeTool == SketchTool.DIMENSION) 0xFF0E7C7B else 0xFF16324F,
                                            )
                                        },
                                        onDrag = { change, _ ->
                                            change.consume()
                                            val cur = inProgressElement ?: return@detectDragGestures
                                            val nx = (change.position.x / size.width.coerceAtLeast(1)).coerceIn(0f, 1f)
                                            val ny = (change.position.y / size.height.coerceAtLeast(1)).coerceIn(0f, 1f)
                                            if (cur.tool == SketchTool.FREEHAND) {
                                                val last = cur.points.lastOrNull()
                                                if (last == null || hypot((nx - last.x) * size.width, (ny - last.y) * size.height) >= 3f) {
                                                    inProgressElement = cur.copy(points = cur.points + SketchPoint(nx, ny))
                                                }
                                            } else {
                                                inProgressElement = cur.copy(points = listOf(cur.points.first(), SketchPoint(nx, ny)))
                                            }
                                        },
                                        onDragEnd = {
                                            val finished = inProgressElement
                                            if (finished != null && finished.points.size >= 2) {
                                                elements = elements + finished
                                                redoStack = emptyList()
                                            }
                                            inProgressElement = null
                                        },
                                        onDragCancel = {
                                            inProgressElement = null
                                        },
                                    )
                                }
                            },
                    ) {
                        // A3 Engineering Grid (20px sub-grid + 40px major grid)
                        val subStep = 20.dp.toPx()
                        val majorStep = 40.dp.toPx()
                        var x = 0f
                        while (x <= size.width) {
                            drawLine(Color(0xFFF1F5F9), Offset(x, 0f), Offset(x, size.height), strokeWidth = 1f)
                            x += subStep
                        }
                        var y = 0f
                        while (y <= size.height) {
                            drawLine(Color(0xFFF1F5F9), Offset(0f, y), Offset(size.width, y), strokeWidth = 1f)
                            y += subStep
                        }
                        x = 0f
                        while (x <= size.width) {
                            drawLine(Color(0xFFE2E8F0), Offset(x, 0f), Offset(x, size.height), strokeWidth = 1.4f)
                            x += majorStep
                        }
                        y = 0f
                        while (y <= size.height) {
                            drawLine(Color(0xFFE2E8F0), Offset(0f, y), Offset(size.width, y), strokeWidth = 1.4f)
                            y += majorStep
                        }

                        // Render committed + active vector elements
                        elements.forEach { drawSketchElement(it) }
                        inProgressElement?.let { drawSketchElement(it) }
                    }
                }

                Spacer(Modifier.height(8.dp))
                Text(
                    text = if (activeTool == SketchTool.TEXT) {
                        "Tap anywhere on the A3 grid to place a room or dimension label."
                    } else {
                        "Drag on the A3 drafting sheet with your finger or stylus to sketch floorplan walls, rooms, and dimensions."
                    },
                    fontSize = 11.5.sp,
                    color = AppColors.SecondaryText,
                )
            }
        }
    }
}

@Composable
private fun ToolPill(
    label: String,
    icon: ImageVector,
    selected: Boolean,
    onClick: () -> Unit,
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        leadingIcon = { Icon(icon, contentDescription = null, modifier = Modifier.size(16.dp)) },
        label = { Text(label, fontSize = 11.5.sp, fontWeight = FontWeight.Bold) },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = AppColors.PrimaryActionTeal,
            selectedLabelColor = Color.White,
            selectedLeadingIconColor = Color.White,
            containerColor = Color.White.copy(alpha = 0.12f),
            labelColor = Color.White,
            iconColor = Color.White,
        ),
        border = null,
    )
}

private fun DrawScope.drawSketchElement(el: SketchElement) {
    if (el.points.isEmpty()) return
    val color = Color(el.colorArgb)
    val pts = el.points.map { Offset(it.x * size.width, it.y * size.height) }

    when (el.tool) {
        SketchTool.LINE -> {
            if (pts.size >= 2) {
                drawLine(color = color, start = pts.first(), end = pts.last(), strokeWidth = el.strokeWidth, cap = StrokeCap.Round)
            }
        }
        SketchTool.RECTANGLE -> {
            if (pts.size >= 2) {
                val p1 = pts.first()
                val p2 = pts.last()
                val left = min(p1.x, p2.x)
                val top = min(p1.y, p2.y)
                val w = kotlin.math.abs(p2.x - p1.x)
                val h = kotlin.math.abs(p2.y - p1.y)
                drawRect(
                    color = color.copy(alpha = 0.06f),
                    topLeft = Offset(left, top),
                    size = Size(w, h),
                )
                drawRect(
                    color = color,
                    topLeft = Offset(left, top),
                    size = Size(w, h),
                    style = Stroke(width = el.strokeWidth, join = StrokeJoin.Miter),
                )
            }
        }
        SketchTool.CIRCLE -> {
            if (pts.size >= 2) {
                val p1 = pts.first()
                val p2 = pts.last()
                val radius = hypot(p2.x - p1.x, p2.y - p1.y)
                drawCircle(
                    color = color,
                    radius = radius,
                    center = p1,
                    style = Stroke(width = el.strokeWidth),
                )
            }
        }
        SketchTool.FREEHAND -> {
            if (pts.size >= 2) {
                val path = Path().apply {
                    moveTo(pts.first().x, pts.first().y)
                    for (i in 1 until pts.size) {
                        lineTo(pts[i].x, pts[i].y)
                    }
                }
                drawPath(
                    path = path,
                    color = color,
                    style = Stroke(width = el.strokeWidth, cap = StrokeCap.Round, join = StrokeJoin.Round),
                )
            }
        }
        SketchTool.DIMENSION -> {
            if (pts.size >= 2) {
                val p1 = pts.first()
                val p2 = pts.last()
                drawLine(
                    color = color,
                    start = p1,
                    end = p2,
                    strokeWidth = el.strokeWidth,
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(12f, 8f)),
                )
                drawCircle(color = color, radius = 5f, center = p1)
                drawCircle(color = color, radius = 5f, center = p2)
                val distFt = (hypot(p2.x - p1.x, p2.y - p1.y) / 14f).coerceAtLeast(1f)
                val mid = Offset((p1.x + p2.x) / 2f, (p1.y + p2.y) / 2f - 8f)
                val paint = Paint().apply {
                    isAntiAlias = true
                    textSize = 28f
                    this.color = android.graphics.Color.rgb(14, 124, 123)
                    isFakeBoldText = true
                }
                drawContext.canvas.nativeCanvas.drawText("${"%.1f".format(distFt)}'", mid.x, mid.y, paint)
            }
        }
        SketchTool.TEXT -> {
            val pt = pts.first()
            val paint = Paint().apply {
                isAntiAlias = true
                textSize = 32f
                this.color = android.graphics.Color.rgb(22, 50, 79)
                isFakeBoldText = true
            }
            drawContext.canvas.nativeCanvas.drawText(el.textLabel, pt.x, pt.y, paint)
        }
    }
}
