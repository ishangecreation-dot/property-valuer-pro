import 'package:flutter/material.dart';

enum SketchTool {
  line,
  circle,
  polyline,
  rectangle,
  freehand,
  dimension,
  text,
  eraser,
  zoom,
  pan,
}

enum SketchUnit {
  feet,
  inches,
  meters,
}

class SketchPoint {
  final double x;
  final double y;
  final double pressure;

  SketchPoint(this.x, this.y, [this.pressure = 1.0]);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'p': pressure};
  factory SketchPoint.fromJson(Map<String, dynamic> json) => SketchPoint(
    (json['x'] as num).toDouble(),
    (json['y'] as num).toDouble(),
    (json['p'] as num?)?.toDouble() ?? 1.0,
  );

  Offset toOffset() => Offset(x, y);
}

class SketchElement {
  final String id;
  final SketchTool tool;
  final List<SketchPoint> points;
  final String textLabel;
  final double strokeWidth;
  final int colorValue;

  SketchElement({
    required this.id,
    required this.tool,
    required this.points,
    this.textLabel = '',
    this.strokeWidth = 2.0,
    this.colorValue = 0xFF16324F,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tool': tool.name,
    'points': points.map((p) => p.toJson()).toList(),
    'textLabel': textLabel,
    'strokeWidth': strokeWidth,
    'colorValue': colorValue,
  };

  factory SketchElement.fromJson(Map<String, dynamic> json) => SketchElement(
    id: json['id'] ?? '',
    tool: SketchTool.values.firstWhere(
      (e) => e.name == json['tool'],
      orElse: () => SketchTool.line,
    ),
    points: (json['points'] as List?)
        ?.map((p) => SketchPoint.fromJson(p))
        .toList() ?? [],
    textLabel: json['textLabel'] ?? '',
    strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
    colorValue: json['colorValue'] ?? 0xFF16324F,
  );
}

class BuildingSketch {
  bool isBareLand;
  bool isLandscape;
  SketchUnit unit;
  double scaleRatio; // e.g., 20.0 (1 inch = 20 feet)
  List<SketchElement> elements;
  String exportedImagePath;

  BuildingSketch({
    this.isBareLand = false,
    this.isLandscape = true,
    this.unit = SketchUnit.feet,
    this.scaleRatio = 20.0,
    List<SketchElement>? elements,
    this.exportedImagePath = '',
  }) : elements = elements ?? [];

  Map<String, dynamic> toJson() => {
    'isBareLand': isBareLand,
    'isLandscape': isLandscape,
    'unit': unit.name,
    'scaleRatio': scaleRatio,
    'elements': elements.map((e) => e.toJson()).toList(),
    'exportedImagePath': exportedImagePath,
  };

  factory BuildingSketch.fromJson(Map<String, dynamic> json) => BuildingSketch(
    isBareLand: json['isBareLand'] ?? false,
    isLandscape: json['isLandscape'] ?? true,
    unit: SketchUnit.values.firstWhere(
      (u) => u.name == json['unit'],
      orElse: () => SketchUnit.feet,
    ),
    scaleRatio: (json['scaleRatio'] as num?)?.toDouble() ?? 20.0,
    elements: (json['elements'] as List?)
        ?.map((e) => SketchElement.fromJson(e))
        .toList() ?? [],
    exportedImagePath: json['exportedImagePath'] ?? '',
  );
}
