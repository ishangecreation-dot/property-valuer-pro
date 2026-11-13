import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/valuation_project.dart';
import '../../../models/building_sketch.dart';
import '../../../core/storage/storage_service.dart';
import '../../../widgets/responsive_scaffold.dart';

class A3SketchingScreen extends StatefulWidget {
  const A3SketchingScreen({Key? key}) : super(key: key);

  @override
  State<A3SketchingScreen> createState() => _A3SketchingScreenState();
}

class _A3SketchingScreenState extends State<A3SketchingScreen> {
  ValuationProject? _project;
  BuildingSketch _sketch = BuildingSketch();
  bool _isLoading = true;

  SketchTool _activeTool = SketchTool.line;
  final List<SketchElement> _undoStack = [];
  final List<SketchElement> _redoStack = [];

  List<SketchPoint> _currentPoints = [];
  final TransformationController _transController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await StorageService.loadActiveProject();
    if (proj != null) {
      _project = proj;
      _sketch = proj.buildingSketch;
      _undoStack.addAll(_sketch.elements);
    }
    setState(() => _isLoading = false);
  }

  void _syncData() {
    if (_project != null) {
      _sketch.elements = List.from(_undoStack);
      _project!.buildingSketch = _sketch;
      StorageService.saveActiveProject(_project!);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_sketch.isBareLand) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);

    setState(() {
      _currentPoints = [SketchPoint(local.dx, local.dy)];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_sketch.isBareLand) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);

    setState(() {
      if (_activeTool == SketchTool.freehand) {
        _currentPoints.add(SketchPoint(local.dx, local.dy));
      } else {
        if (_currentPoints.length > 1) {
          _currentPoints[1] = SketchPoint(local.dx, local.dy);
        } else {
          _currentPoints.add(SketchPoint(local.dx, local.dy));
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_sketch.isBareLand || _currentPoints.isEmpty) return;

    final element = SketchElement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tool: _activeTool,
      points: List.from(_currentPoints),
      textLabel: _activeTool == SketchTool.text ? 'Living Room (16\' x 14\')' : '',
    );

    setState(() {
      _undoStack.add(element);
      _redoStack.clear();
      _currentPoints = [];
    });
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _redoStack.add(_undoStack.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _undoStack.add(_redoStack.removeLast());
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _undoStack.clear();
      _redoStack.clear();
      _currentPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWorkflowScaffold(
      currentStep: 7,
      title: 'A3 Building Sketch (Mini-CAD)',
      onBack: () {
        _syncData();
        Navigator.pop(context);
      },
      onNext: () {
        _syncData();
        Navigator.pushNamed(context, '/step8');
      },
      nextLabel: _sketch.isBareLand ? 'Skip (Bare Land) → Building' : 'Save Sketch & Continue',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bare Land Prompt Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.surfaceContainerLow,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Is there a constructed building on this property?',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Building Exists', style: TextStyle(fontSize: 11)),
                            selected: !_sketch.isBareLand,
                            selectedColor: AppColors.primaryNavy,
                            labelStyle: TextStyle(color: !_sketch.isBareLand ? Colors.white : AppColors.mainText),
                            onSelected: (val) {
                              if (val) setState(() => _sketch.isBareLand = false);
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Bare Land Only', style: TextStyle(fontSize: 11)),
                            selected: _sketch.isBareLand,
                            selectedColor: AppColors.warning,
                            labelStyle: TextStyle(color: _sketch.isBareLand ? Colors.white : AppColors.mainText),
                            onSelected: (val) {
                              if (val) setState(() => _sketch.isBareLand = true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_sketch.isBareLand)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.landscape_outlined, size: 64, color: AppColors.warning.withOpacity(0.8)),
                          const SizedBox(height: 16),
                          const Text(
                            'Bare Land Assessment Mode Active',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryNavy),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No building improvements on site. Building sketch and structural cost steps can be skipped.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _syncData();
                              Navigator.pushNamed(context, '/step8');
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Proceed Directly to Specifications'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryActionTeal),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Lightweight Toolbar: Units, Scale, Tools
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Scale & Unit Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Scale: 1" = ${_sketch.scaleRatio.toInt()} ft (${_sketch.isLandscape ? "A3 Landscape" : "A3 Portrait"})',
                              style: const TextStyle(color: AppColors.antiqueGold, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Orientation toggle
                          IconButton(
                            icon: Icon(_sketch.isLandscape ? Icons.crop_landscape : Icons.crop_portrait, size: 20),
                            tooltip: 'Toggle Portrait / Landscape',
                            onPressed: () => setState(() => _sketch.isLandscape = !_sketch.isLandscape),
                          ),
                          const VerticalDivider(width: 16),
                          // Tools
                          _buildToolButton(SketchTool.line, Icons.horizontal_rule, 'Wall Line'),
                          _buildToolButton(SketchTool.rectangle, Icons.crop_square, 'Room Rect'),
                          _buildToolButton(SketchTool.circle, Icons.radio_button_unchecked, 'Circle / Pillar'),
                          _buildToolButton(SketchTool.freehand, Icons.gesture, 'Freehand / S-Pen'),
                          _buildToolButton(SketchTool.dimension, Icons.straighten, 'Dimension'),
                          _buildToolButton(SketchTool.text, Icons.title, 'Room Label'),
                          const VerticalDivider(width: 16),
                          IconButton(
                            icon: const Icon(Icons.undo, size: 20),
                            tooltip: 'Undo',
                            onPressed: _undoStack.isNotEmpty ? _undo : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.redo, size: 20),
                            tooltip: 'Redo',
                            onPressed: _redoStack.isNotEmpty ? _redo : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                            tooltip: 'Clear Canvas',
                            onPressed: _clearCanvas,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // A3 CustomPainter Canvas with Smooth Pan & Zoom
                  Expanded(
                    child: Container(
                      color: const Color(0xFFD9DADB),
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _sketch.isLandscape ? 1.414 : (1 / 1.414), // Exact A3 ratio
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: CustomPaint(
                                painter: _A3CadPainter(
                                  elements: _undoStack,
                                  currentPoints: _currentPoints,
                                  activeTool: _activeTool,
                                ),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildToolButton(SketchTool tool, IconData icon, String tooltip) {
    final isSel = _activeTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSel ? AppColors.primaryActionTeal : AppColors.primaryNavy, size: 20),
      tooltip: tooltip,
      onPressed: () => setState(() => _activeTool = tool),
    );
  }
}

// Lightweight Vector CustomPainter for A3 Mini-CAD
class _A3CadPainter extends CustomPainter {
  final List<SketchElement> elements;
  final List<SketchPoint> currentPoints;
  final SketchTool activeTool;

  _A3CadPainter({
    required this.elements,
    required this.currentPoints,
    required this.activeTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Architectural Grid: 1" main squares + 10x10 subgrids
    const double mainGridPx = 40.0;
    const double subGridPx = 4.0;

    final subPaint = Paint()
      ..color = const Color(0xFFF0F4F8)
      ..strokeWidth = 0.5;

    final mainPaint = Paint()
      ..color = const Color(0xFFD2DCE6)
      ..strokeWidth = 1.0;

    // Viewport-based incremental lines
    for (double x = 0; x < size.width; x += subGridPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), subPaint);
    }
    for (double y = 0; y < size.height; y += subGridPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), subPaint);
    }
    for (double x = 0; x < size.width; x += mainGridPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), mainPaint);
    }
    for (double y = 0; y < size.height; y += mainGridPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), mainPaint);
    }

    // 2. Render Existing Vector Elements
    for (final el in elements) {
      _drawElement(canvas, el);
    }

    // 3. Render In-progress Active Element
    if (currentPoints.length >= 2) {
      final activeElement = SketchElement(
        id: 'active',
        tool: activeTool,
        points: currentPoints,
        strokeWidth: 2.0,
      );
      _drawElement(canvas, activeElement, isActive: true);
    }
  }

  void _drawElement(Canvas canvas, SketchElement el, {bool isActive = false}) {
    final paint = Paint()
      ..color = isActive ? AppColors.primaryActionTeal : Color(el.colorValue)
      ..strokeWidth = el.strokeWidth
      ..style = PaintingStyle.stroke;

    if (el.points.isEmpty) return;

    switch (el.tool) {
      case SketchTool.line:
      case SketchTool.dimension:
        if (el.points.length >= 2) {
          canvas.drawLine(el.points[0].toOffset(), el.points[1].toOffset(), paint);
          if (el.tool == SketchTool.dimension) {
            // Draw dimension ticks
            canvas.drawCircle(el.points[0].toOffset(), 3, paint..style = PaintingStyle.fill);
            canvas.drawCircle(el.points[1].toOffset(), 3, paint);
          }
        }
        break;
      case SketchTool.rectangle:
        if (el.points.length >= 2) {
          final rect = Rect.fromPoints(el.points[0].toOffset(), el.points[1].toOffset());
          canvas.drawRect(rect, paint);
        }
        break;
      case SketchTool.circle:
        if (el.points.length >= 2) {
          final center = el.points[0].toOffset();
          final radius = (el.points[1].toOffset() - center).distance;
          canvas.drawCircle(center, radius, paint);
        }
        break;
      case SketchTool.freehand:
      case SketchTool.polyline:
        for (int i = 0; i < el.points.length - 1; i++) {
          canvas.drawLine(el.points[i].toOffset(), el.points[i + 1].toOffset(), paint);
        }
        break;
      case SketchTool.text:
        final tp = TextPainter(
          text: TextSpan(
            text: el.textLabel.isNotEmpty ? el.textLabel : 'Room',
            style: const TextStyle(color: AppColors.primaryNavy, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, el.points[0].toOffset());
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _A3CadPainter oldDelegate) => true;
}
