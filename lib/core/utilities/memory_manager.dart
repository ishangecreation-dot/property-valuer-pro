import 'dart:io';
import 'package:flutter/material.dart';

class MemoryManager {
  // Clear image cache when switching heavy screens
  static void optimizeMemory() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  // Check file size to avoid loading large bitmaps into memory
  static Future<int> getFileSizeBytes(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  // Recommended preview downsampling constraints
  static const int thumbnailMaxDimension = 600;
  static const int previewMaxDimension = 1280;

  // Viewport Culling Helper for A3 Mini-CAD canvas
  static bool isElementVisible({
    required Rect viewportRect,
    required Rect elementBounds,
  }) {
    return viewportRect.overlaps(elementBounds);
  }
}

