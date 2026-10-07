import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/template_model.dart';
import '../models/layout_model.dart';
import '../models/transform_model.dart';
import '../models/filter_model.dart';
import '../widgets/frame_painter.dart';

class ExportService {
  static Future<String> renderAndSaveArtwork({
    required List<ui.Image?> images,
    required FrameTemplate template,
    required CollageLayout layout,
    required Map<int, SlotTransform> slotTransforms,
    required FilterPreset filterPreset,
    required double borderRatio,
    required double matRatio,
    required Color frameColor,
    required Color matColor,
    required bool hasShadow,
    String? captionText,
    double gapSize = 8.0,
    double cellCornerRadius = 0.0,
    Color? gridBgColor,
    int exportResolution = 2400,
  }) async {
    // 1. Hardware accelerated offscreen rendering using Skia PictureRecorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(exportResolution.toDouble(), exportResolution.toDouble());

    final painter = FramePainter(
      images: images,
      template: template,
      layout: layout,
      slotTransforms: slotTransforms,
      filterPreset: filterPreset,
      borderRatio: borderRatio,
      matRatio: matRatio,
      frameColor: frameColor,
      matColor: matColor,
      hasShadow: hasShadow,
      captionText: captionText,
      activeEditingSlot: null, // Pristine export, no edit overlays
      gapSize: gapSize,
      cellCornerRadius: cellCornerRadius,
      gridBgColor: gridBgColor,
    );

    painter.paint(canvas, size);

    // 2. Convert recorded draw commands into high-res bitmap
    final picture = recorder.endRecording();
    final ui.Image renderedImage = await picture.toImage(exportResolution, exportResolution);
    final ByteData? byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Không thể tạo dữ liệu hình ảnh PNG.');
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    // 3. Write to temporary storage
    final tempDir = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String filePath = '${tempDir.path}/fancy_frame_$timestamp.png';
    final file = File(filePath);
    await file.writeAsBytes(pngBytes);

    // 4. Save to device Gallery / Camera Roll
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(filePath, album: 'PhotoFrameFancy');
    } catch (e) {
      debugPrint('Gal save warning: $e');
    }

    return filePath;
  }

  static Future<void> shareArtwork(String filePath) async {
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Khung ảnh nghệ thuật thiết kế bởi PhotoFrameFancy!',
    );
  }
}
