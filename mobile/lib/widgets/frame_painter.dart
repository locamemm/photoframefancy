import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../models/layout_model.dart';
import '../models/transform_model.dart';
import '../models/filter_model.dart';

class FramePainter extends CustomPainter {
  final List<ui.Image?> images;
  final FrameTemplate template;
  final CollageLayout layout;
  final Map<int, SlotTransform> slotTransforms;
  final FilterPreset filterPreset;
  final double borderRatio;
  final double matRatio;
  final Color frameColor;
  final Color matColor;
  final bool hasShadow;
  final String? captionText;
  final int? activeEditingSlot;
  final double gapSize;
  final double cellCornerRadius;
  final Color? gridBgColor;

  FramePainter({
    required this.images,
    required this.template,
    required this.layout,
    required this.slotTransforms,
    required this.filterPreset,
    required this.borderRatio,
    required this.matRatio,
    required this.frameColor,
    required this.matColor,
    required this.hasShadow,
    this.captionText,
    this.activeEditingSlot,
    this.gapSize = 8.0,
    this.cellCornerRadius = 0.0,
    this.gridBgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double minDim = math.min(size.width, size.height);
    final double scale = minDim / 400.0; // Universal scale factor for resolution independence

    final double pad = (hasShadow && template.id != 'film_35mm') ? minDim * 0.05 : 0.0;
    final Rect totalRect = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );

    // 1. Drop Shadow for overall frame
    if (hasShadow && template.id != 'film_35mm') {
      final shadowPath = Path()..addRect(totalRect);
      canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: 0.55), 18.0 * scale, true);
      canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: 0.35), 8.0 * scale, true);
    }

    // 2. Proportions & Margins (proportional to minDim, no resolution-distorting clamps)
    final double borderW = (minDim * borderRatio).clamp(2.0, minDim * 0.45);
    final double matW = (minDim * matRatio).clamp(0.0, minDim * 0.45);

    // Template specific bottom adjustments
    final double polaroidExtra = (template.id == 'polaroid_classic') ? minDim * 0.16 : 0.0;
    final double museumExtra = (template.id == 'museum_gallery' && (captionText?.isNotEmpty ?? false))
        ? minDim * 0.08
        : 0.0;
    final double newspaperExtra = (template.id == 'vintage_newspaper') ? minDim * 0.08 : 0.0;
    final double ticketExtra = (template.id == 'vintage_boarding_ticket') ? minDim * 0.10 : 0.0;
    final double clotheslineExtra = (template.id == 'darkroom_clothesline') ? minDim * 0.08 : 0.0;
    final double cassetteExtra = (template.id == 'cassette_tape_80s') ? minDim * 0.09 : 0.0;

    // 3. Draw Outer Frame Body & Textures
    _drawOuterFrame(canvas, totalRect, borderW, scale);

    // 4. Calculate Matting Rect
    // For film 35mm, top and bottom borders are wider for sprocket holes
    final double topB = (template.id == 'film_35mm')
        ? borderW * 1.5
        : (template.id == 'darkroom_clothesline' ? borderW + clotheslineExtra : borderW);
    final double botB = (template.id == 'film_35mm')
        ? borderW * 1.5
        : (template.id == 'polaroid_classic'
            ? borderW + polaroidExtra
            : (template.id == 'vintage_boarding_ticket'
                ? borderW + ticketExtra
                : (template.id == 'cassette_tape_80s'
                    ? borderW + cassetteExtra
                    : borderW)));

    final Rect matRect = Rect.fromLTRB(
      totalRect.left + borderW,
      totalRect.top + topB,
      totalRect.right - borderW,
      totalRect.bottom - botB,
    );

    // Draw Mat Board (Passe-partout)
    if (matW > 0 && template.id != 'film_35mm' && template.id != 'polaroid_classic') {
      final matPaint = Paint()..color = matColor;
      canvas.drawRect(matRect, matPaint);

      // Inset gold / dark / bronze pinstripe on mat
      if (template.id == 'dark_walnut' || template.id == 'gold_baroque' || template.id == 'antique_bronze') {
        final filletPaint = Paint()
          ..color = (template.id == 'antique_bronze'
                  ? const Color(0xFFBCAAA4)
                  : const Color(0xFFD4AF37))
              .withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * scale;
        canvas.drawRect(matRect.deflate(borderW * 0.25), filletPaint);
      } else if (template.id == 'museum_gallery') {
        // Fine beveled white paper core around mat
        final corePaint = Paint()
          ..color = const Color(0xFFE5E0D8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale;
        canvas.drawRect(matRect.deflate(2.0 * scale), corePaint);
      }
    }

    // 5. Inner Photo Artwork Area (With bottom extra space reserved inside mat for Museum Gallery)
    final Rect innerRect = (template.id == 'modern_floating')
        ? matRect
        : Rect.fromLTRB(
            matRect.left + matW,
            matRect.top + matW + newspaperExtra,
            matRect.right - matW,
            matRect.bottom - matW - museumExtra,
          );

    // For modern_floating, photo floats above background with its own soft 3D shadow
    if (template.id == 'modern_floating') {
      final floatPath = Path()..addRRect(RRect.fromRectAndRadius(innerRect, Radius.circular(8 * scale)));
      canvas.drawShadow(floatPath, Colors.black.withValues(alpha: 0.4), 16.0 * scale, true);
    } else if (template.id == 'scrapbook_kraft') {
      final scrapPath = Path()..addRect(innerRect);
      canvas.drawShadow(scrapPath, Colors.black.withValues(alpha: 0.35), 8.0 * scale, true);
    }

    // Fill slot board gap background
    final Color effectiveBg = gridBgColor ??
        ((template.id == 'polaroid_classic') ? const Color(0xFF18181B) : matColor);
    final bgPaint = Paint()..color = effectiveBg;
    canvas.drawRect(innerRect, bgPaint);

    // 6. Draw Photo Slots with dynamic gap & corner radius
    final double gapPx = gapSize * scale * 0.8;
    final double radiusPx = cellCornerRadius * scale * 0.8;
    final double effectiveRadius = math.max(radiusPx, (template.id == 'modern_floating' ? 6.0 * scale : 0.0));

    for (int i = 0; i < layout.slots.length; i++) {
      final slot = layout.slots[i];
      final slotL = innerRect.left + slot.x * innerRect.width + (slot.x > 0.001 ? gapPx / 2 : 0.0);
      final slotT = innerRect.top + slot.y * innerRect.height + (slot.y > 0.001 ? gapPx / 2 : 0.0);
      final slotR = innerRect.left + (slot.x + slot.w) * innerRect.width - ((slot.x + slot.w) < 0.999 ? gapPx / 2 : 0.0);
      final slotB = innerRect.top + (slot.y + slot.h) * innerRect.height - ((slot.y + slot.h) < 0.999 ? gapPx / 2 : 0.0);
      
      if (slotR <= slotL || slotB <= slotT) continue;
      final slotRect = Rect.fromLTRB(slotL, slotT, slotR, slotB);

      canvas.save();
      if (effectiveRadius > 0) {
        canvas.clipRRect(RRect.fromRectAndRadius(slotRect, Radius.circular(effectiveRadius)));
      } else {
        canvas.clipRect(slotRect);
      }

      final ui.Image? img = (i < images.length) ? images[i] : (images.isNotEmpty ? images[0] : null);
      if (img != null) {
        final transform = slotTransforms[i] ?? SlotTransform();
        _drawTransformedPhoto(canvas, slotRect, img, transform);
      } else {
        _drawEmptySlot(canvas, slotRect, i, scale);
      }

      canvas.restore();

      // Subtle border or bevel around each cell
      if (effectiveRadius > 0) {
        final cellBorder = Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * scale;
        canvas.drawRRect(RRect.fromRectAndRadius(slotRect, Radius.circular(effectiveRadius)), cellBorder);
      } else if (template.id == 'museum_gallery' ||
          template.id == 'dark_walnut' ||
          template.id == 'antique_bronze' ||
          template.id == 'gold_baroque') {
        final shadowLine = Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 1.5 * scale;
        canvas.drawLine(slotRect.bottomLeft, slotRect.bottomRight, shadowLine);
        canvas.drawLine(slotRect.topRight, slotRect.bottomRight, shadowLine);
      }
    }

    // 7. Post-Photo Decorative Overlays (Washi tapes, Postage stamp mark, Magazine masthead, Botanical vines, Plaque)
    _drawForegroundDecorations(
      canvas,
      totalRect,
      innerRect,
      matRect,
      borderW,
      scale,
      polaroidExtra,
      ticketExtra: ticketExtra,
      cassetteExtra: cassetteExtra,
    );

    // 8. Active Slot Selection Overlay
    if (activeEditingSlot != null && activeEditingSlot! < layout.slots.length) {
      final slot = layout.slots[activeEditingSlot!];
      final slotL = innerRect.left + slot.x * innerRect.width + (slot.x > 0.001 ? gapPx / 2 : 0.0);
      final slotT = innerRect.top + slot.y * innerRect.height + (slot.y > 0.001 ? gapPx / 2 : 0.0);
      final slotR = innerRect.left + (slot.x + slot.w) * innerRect.width - ((slot.x + slot.w) < 0.999 ? gapPx / 2 : 0.0);
      final slotB = innerRect.top + (slot.y + slot.h) * innerRect.height - ((slot.y + slot.h) < 0.999 ? gapPx / 2 : 0.0);
      if (slotR > slotL && slotB > slotT) {
        final slotRect = Rect.fromLTRB(slotL, slotT, slotR, slotB);
        _drawSelectionOverlay(canvas, slotRect, activeEditingSlot!, scale);
      }
    }
  }

  // -------------------------------------------------------------
  // Outer Frame Renderers
  // -------------------------------------------------------------
  void _drawOuterFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    switch (template.id) {
      case 'gold_baroque':
        _drawGoldBaroqueFrame(canvas, rect, borderW, scale);
        break;
      case 'dark_walnut':
        _drawWalnutWoodFrame(canvas, rect, borderW, scale);
        break;
      case 'antique_bronze':
        _drawAntiqueBronzeFrame(canvas, rect, borderW, scale);
        break;
      case 'museum_gallery':
        _drawMuseumGalleryFrame(canvas, rect, borderW, scale);
        break;
      case 'film_35mm':
        _drawFilm35mmFrame(canvas, rect, borderW, scale);
        break;
      case 'vintage_stamp':
        _drawVintageStampFrame(canvas, rect, borderW, scale);
        break;
      case 'scrapbook_kraft':
        _drawScrapbookKraftFrame(canvas, rect, borderW, scale);
        break;
      case 'vintage_postcard':
        _drawVintagePostcardFrame(canvas, rect, borderW, scale);
        break;
      case 'retro_album_corners':
        _drawRetroAlbumFrame(canvas, rect, borderW, scale);
        break;
      case 'film_120_hasselblad':
        _drawFilm120Frame(canvas, rect, borderW, scale);
        break;
      case 'vintage_newspaper':
        _drawVintageNewspaperFrame(canvas, rect, borderW, scale);
        break;
      case 'vintage_boarding_ticket':
        _drawVintageTicketFrame(canvas, rect, borderW, scale);
        break;
      case 'darkroom_clothesline':
        _drawDarkroomClotheslineFrame(canvas, rect, borderW, scale);
        break;
      case 'antique_cartography':
        _drawAntiqueCartographyFrame(canvas, rect, borderW, scale);
        break;
      case 'cassette_tape_80s':
        _drawCassetteTapeFrame(canvas, rect, borderW, scale);
        break;
      case 'retro_viewmaster':
        _drawRetroViewmasterFrame(canvas, rect, borderW, scale);
        break;
      case 'gallery_canvas_float':
        _drawGalleryCanvasFloatFrame(canvas, rect, borderW, scale);
        break;
      case 'oil_painting_canvas':
        _drawOilPaintingFrame(canvas, rect, borderW, scale);
        break;
      case 'fineart_deckle_edge':
        _drawFineArtDeckleFrame(canvas, rect, borderW, scale);
        break;
      case 'studio_minimal_curator':
        _drawStudioCuratorFrame(canvas, rect, borderW, scale);
        break;
      case 'double_pinstripe':
        _drawDoublePinstripeFrame(canvas, rect, borderW, scale);
        break;
      case 'neon_cyberpunk':
        _drawNeonCyberpunkFrame(canvas, rect, borderW, scale);
        break;
      case 'wedding_botanical':
        _drawWeddingBotanicalFrame(canvas, rect, borderW, scale);
        break;
      case 'magazine_vogue':
      case 'polaroid_classic':
      case 'modern_floating':
      case 'nordic_clean':
      case 'minimal_clean':
      default:
        _drawStandardCleanFrame(canvas, rect, borderW, scale);
        break;
    }
  }

  void _drawGoldBaroqueFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Base Rich Gold Body
    final basePaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawRect(rect, basePaint);

    // 2. Metallic Sheen Linear Gradient across frame
    final sheenPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xFFFFF3C4),
          const Color(0xFFD4AF37),
          const Color(0xFF996515),
          const Color(0xFFFFDF79),
          const Color(0xFFB8860B),
        ],
        [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    canvas.drawRect(rect, sheenPaint);

    // 3. Multi-tier Carved Bevel Lines (Stepped ridges)
    const int steps = 4;
    for (int i = 0; i < steps; i++) {
      final double inset = borderW * (i / steps);
      final rInset = rect.deflate(inset);

      // Highlight bevel edge
      final hlPaint = Paint()
        ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale;
      canvas.drawRect(rInset, hlPaint);

      // Shadow bevel groove
      final shPaint = Paint()
        ..color = const Color(0xFF5A4614).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale;
      canvas.drawRect(rInset.deflate(1.2 * scale), shPaint);
    }

    // 4. Ornate Filigree Corner Accents & Pearls
    final double cornerR = borderW * 0.9;
    final List<Offset> corners = [
      rect.topLeft.translate(borderW * 0.8, borderW * 0.8),
      rect.topRight.translate(-borderW * 0.8, borderW * 0.8),
      rect.bottomLeft.translate(borderW * 0.8, -borderW * 0.8),
      rect.bottomRight.translate(-borderW * 0.8, -borderW * 0.8),
    ];

    for (final c in corners) {
      // Concentric filigree arcs
      final arcPaint = Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale;
      canvas.drawCircle(c, cornerR * 0.7, arcPaint);
      canvas.drawCircle(c, cornerR * 0.45, arcPaint);

      // Center gold jewel stud
      final studPaint = Paint()..color = const Color(0xFFFFF9C4);
      canvas.drawCircle(c, 4.0 * scale, studPaint);
    }
  }

  void _drawAntiqueBronzeFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Aged Bronze Metallic Base with rich patina gradient
    final bronzePaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xFF3E2723), // Deep bronze umber
          const Color(0xFF6D4C41),
          const Color(0xFF8D6E63), // Warm bronze highlight
          const Color(0xFF5D4037),
          const Color(0xFF4E342E),
        ],
        [0.0, 0.25, 0.5, 0.75, 1.0],
      );
    canvas.drawRect(rect, bronzePaint);

    // 2. Stepped Multi-Tier Carved Bevel Lines
    const int steps = 4;
    for (int i = 0; i < steps; i++) {
      final double inset = borderW * (i / steps);
      final rInset = rect.deflate(inset);

      // Warm bronze highlight bevel edge
      final hlPaint = Paint()
        ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale;
      canvas.drawRect(rInset, hlPaint);

      // Dark crevice shadow groove
      final shPaint = Paint()
        ..color = const Color(0xFF1E130E).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale;
      canvas.drawRect(rInset.deflate(1.2 * scale), shPaint);
    }

    // 3. 45° Corner Miter Relief Lines
    final miterPaint = Paint()
      ..color = const Color(0xFF1E130E).withValues(alpha: 0.7)
      ..strokeWidth = 1.8 * scale;
    final miterHl = Paint()
      ..color = const Color(0xFFBCAAA4).withValues(alpha: 0.4)
      ..strokeWidth = 1.0 * scale;

    canvas.drawLine(rect.topLeft, rect.topLeft.translate(borderW, borderW), miterPaint);
    canvas.drawLine(rect.topLeft.translate(1 * scale, 0), rect.topLeft.translate(borderW + 1 * scale, borderW), miterHl);

    canvas.drawLine(rect.topRight, rect.topRight.translate(-borderW, borderW), miterPaint);
    canvas.drawLine(rect.topRight.translate(-1 * scale, 0), rect.topRight.translate(-borderW - 1 * scale, borderW), miterHl);

    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(borderW, -borderW), miterPaint);
    canvas.drawLine(rect.bottomLeft.translate(1 * scale, 0), rect.bottomLeft.translate(borderW + 1 * scale, -borderW), miterHl);

    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-borderW, -borderW), miterPaint);
    canvas.drawLine(rect.bottomRight.translate(-1 * scale, 0), rect.bottomRight.translate(-borderW - 1 * scale, -borderW), miterHl);

    // 4. Ornate Baroque Filigree Corner Medallions & Studs
    final double cornerR = borderW * 0.85;
    final List<Offset> corners = [
      rect.topLeft.translate(borderW * 0.75, borderW * 0.75),
      rect.topRight.translate(-borderW * 0.75, borderW * 0.75),
      rect.bottomLeft.translate(borderW * 0.75, -borderW * 0.75),
      rect.bottomRight.translate(-borderW * 0.75, -borderW * 0.75),
    ];

    for (final c in corners) {
      final arcPaint = Paint()
        ..color = const Color(0xFFBCAAA4).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale;
      canvas.drawCircle(c, cornerR * 0.65, arcPaint);
      canvas.drawCircle(c, cornerR * 0.4, arcPaint);

      final studPaint = Paint()..color = const Color(0xFF4E342E);
      canvas.drawCircle(c, 3.5 * scale, studPaint);
      canvas.drawCircle(c, 1.5 * scale, Paint()..color = const Color(0xFFD7CCC8));
    }
  }

  void _drawMuseumGalleryFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Sleek Gallery Ebony Black Wood Base
    final basePaint = Paint()..color = const Color(0xFF141416);
    canvas.drawRect(rect, basePaint);

    // 2. Subtle Satin Wood Sheen Linear Gradient
    final sheenPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xFF27272A),
          const Color(0xFF141416),
          const Color(0xFF1F1F23),
          const Color(0xFF09090B),
        ],
        [0.0, 0.33, 0.66, 1.0],
      );
    canvas.drawRect(rect, sheenPaint);

    // 3. Stepped Bevel Ridge
    final ridgePaint = Paint()
      ..color = const Color(0xFF3F3F46).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.35), ridgePaint);

    // 4. Inner Shadow on inner frame edge
    final innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRect(rect.deflate(borderW - 1.0 * scale), innerShadow);
  }

  void _drawWalnutWoodFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Deep Walnut Wood Base
    final woodPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawRect(rect, woodPaint);

    // 2. Realistic Woodgrain Lines (Sine curves across frame)
    final grainPaint = Paint()
      ..color = const Color(0xFF271510).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;

    final double stepY = 7.0 * scale;
    for (double y = rect.top + 3 * scale; y < rect.bottom; y += stepY) {
      final path = Path();
      path.moveTo(rect.left, y);
      for (double x = rect.left; x < rect.right; x += 30 * scale) {
        path.quadraticBezierTo(
          x + 15 * scale,
          y + math.sin(x * 0.05 / scale) * 2.5 * scale,
          x + 30 * scale,
          y,
        );
      }
      canvas.drawPath(path, grainPaint);
    }

    // 3. 45° Miter Corner Joint Lines (Vát góc ghép mộng gỗ)
    final miterShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..strokeWidth = 2.0 * scale;
    final miterHl = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.4)
      ..strokeWidth = 1.0 * scale;

    canvas.drawLine(rect.topLeft, rect.topLeft.translate(borderW, borderW), miterShadow);
    canvas.drawLine(rect.topLeft.translate(1 * scale, 0), rect.topLeft.translate(borderW + 1 * scale, borderW), miterHl);

    canvas.drawLine(rect.topRight, rect.topRight.translate(-borderW, borderW), miterShadow);
    canvas.drawLine(rect.topRight.translate(-1 * scale, 0), rect.topRight.translate(-borderW - 1 * scale, borderW), miterHl);

    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(borderW, -borderW), miterShadow);
    canvas.drawLine(rect.bottomLeft.translate(1 * scale, 0), rect.bottomLeft.translate(borderW + 1 * scale, -borderW), miterHl);

    canvas.drawLine(rect.bottomRight, rect.bottomRight.translate(-borderW, -borderW), miterShadow);
    canvas.drawLine(rect.bottomRight.translate(-1 * scale, 0), rect.bottomRight.translate(-borderW - 1 * scale, -borderW), miterHl);

    // Inner bevel shadow
    final innerBevel = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRect(rect.deflate(borderW), innerBevel);
  }

  void _drawFilm35mmFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Film Roll Black Base
    final filmBase = Paint()..color = const Color(0xFF141416);
    canvas.drawRect(rect, filmBase);

    // 2. Authentic Sprocket Holes (Lỗ răng cưa dọc trên & dưới)
    final double holeW = borderW * 0.38;
    final double holeH = borderW * 0.52;
    final double spacing = holeW * 1.8;

    final holeBg = Paint()..color = const Color(0xFF09090B);
    final holeBorder = Paint()
      ..color = const Color(0xFF3F3F46).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;

    // Top Sprockets
    for (double x = rect.left + borderW * 0.5; x < rect.right - holeW; x += spacing) {
      final hRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, rect.top + borderW * 0.3, holeW, holeH),
        Radius.circular(3 * scale),
      );
      canvas.drawRRect(hRect, holeBg);
      canvas.drawRRect(hRect, holeBorder);
    }

    // Bottom Sprockets
    for (double x = rect.left + borderW * 0.5; x < rect.right - holeW; x += spacing) {
      final hRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, rect.bottom - borderW * 0.85, holeW, holeH),
        Radius.circular(3 * scale),
      );
      canvas.drawRRect(hRect, holeBg);
      canvas.drawRRect(hRect, holeBorder);
    }

    // 3. Vintage Film Manufacturer Text (Orange/Gold retro typography)
    final textStyle = TextStyle(
      color: const Color(0xFFF59E0B),
      fontSize: 9.5 * scale,
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0 * scale,
      fontFamily: 'monospace',
    );

    final tpLeft = TextPainter(
      text: TextSpan(text: captionText ?? 'KODAK GOLD 200  ▶  24A', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLeft.paint(canvas, Offset(rect.left + borderW, rect.top + borderW * 0.95));

    final tpRight = TextPainter(
      text: TextSpan(text: 'SAFETY FILM 35  •  ISO 200', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpRight.paint(canvas, Offset(rect.right - borderW - tpRight.width, rect.bottom - borderW * 1.3));
  }

  void _drawVintageStampFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Stamp Warm White Paper
    final stampPaint = Paint()..color = const Color(0xFFFAF6EE);
    canvas.drawRect(rect, stampPaint);

    // 2. Perforated Scalloped Edge Bites (Răng cưa tem thư)
    final double holeR = borderW * 0.22;
    final double spacing = holeR * 2.8;
    final clearPaint = Paint()
      ..color = const Color(0xFF09090B)
      ..style = PaintingStyle.fill;

    // Top & Bottom Bites
    for (double x = rect.left + holeR; x <= rect.right; x += spacing) {
      canvas.drawCircle(Offset(x, rect.top), holeR, clearPaint);
      canvas.drawCircle(Offset(x, rect.bottom), holeR, clearPaint);
    }
    // Left & Right Bites
    for (double y = rect.top + holeR; y <= rect.bottom; y += spacing) {
      canvas.drawCircle(Offset(rect.left, y), holeR, clearPaint);
      canvas.drawCircle(Offset(rect.right, y), holeR, clearPaint);
    }

    // Decorative inner pinstripe
    final innerStripe = Paint()
      ..color = const Color(0xFFD4C7B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.6), innerStripe);
  }

  void _drawScrapbookKraftFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    final kraftPaint = Paint()..color = const Color(0xFFD7C4A5);
    canvas.drawRect(rect, kraftPaint);

    final fiberPaint = Paint()
      ..color = const Color(0xFFC4AE8D).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    for (double y = rect.top + 5 * scale; y < rect.bottom; y += 12 * scale) {
      canvas.drawLine(
        Offset(rect.left + 5 * scale, y),
        Offset(rect.right - 5 * scale, y + math.sin(y / scale) * 2 * scale),
        fiberPaint,
      );
    }
  }

  void _drawVintagePostcardFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Aged Vintage Postcard Base
    final basePaint = Paint()..color = const Color(0xFFF4EAD4);
    canvas.drawRect(rect, basePaint);

    // 2. Airmail Chevrons around outer border (Alternating Red & Navy Blue)
    final double chevronW = borderW * 0.72;
    final double segW = 16.0 * scale;
    final redPaint = Paint()..color = const Color(0xFFC62828);
    final bluePaint = Paint()..color = const Color(0xFF1565C0);

    // Top Airmail edge
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(rect.left, rect.top, rect.width, chevronW));
    bool isRed = true;
    for (double x = rect.left - segW; x < rect.right + segW; x += segW) {
      final p = Path()
        ..moveTo(x, rect.top)
        ..lineTo(x + segW * 0.65, rect.top)
        ..lineTo(x + segW * 0.65 - chevronW * 0.5, rect.top + chevronW)
        ..lineTo(x - chevronW * 0.5, rect.top + chevronW)
        ..close();
      canvas.drawPath(p, isRed ? redPaint : bluePaint);
      isRed = !isRed;
    }
    canvas.restore();

    // Bottom Airmail edge
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(rect.left, rect.bottom - chevronW, rect.width, chevronW));
    isRed = false;
    for (double x = rect.left - segW; x < rect.right + segW; x += segW) {
      final p = Path()
        ..moveTo(x, rect.bottom - chevronW)
        ..lineTo(x + segW * 0.65, rect.bottom - chevronW)
        ..lineTo(x + segW * 0.65 - chevronW * 0.5, rect.bottom)
        ..lineTo(x - chevronW * 0.5, rect.bottom)
        ..close();
      canvas.drawPath(p, isRed ? redPaint : bluePaint);
      isRed = !isRed;
    }
    canvas.restore();

    // Left Airmail edge
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(rect.left, rect.top + chevronW, chevronW, rect.height - chevronW * 2));
    isRed = true;
    for (double y = rect.top; y < rect.bottom; y += segW) {
      final p = Path()
        ..moveTo(rect.left, y)
        ..lineTo(rect.left + chevronW, y + chevronW * 0.5)
        ..lineTo(rect.left + chevronW, y + segW * 0.65 + chevronW * 0.5)
        ..lineTo(rect.left, y + segW * 0.65)
        ..close();
      canvas.drawPath(p, isRed ? redPaint : bluePaint);
      isRed = !isRed;
    }
    canvas.restore();

    // Right Airmail edge
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(rect.right - chevronW, rect.top + chevronW, chevronW, rect.height - chevronW * 2));
    isRed = false;
    for (double y = rect.top; y < rect.bottom; y += segW) {
      final p = Path()
        ..moveTo(rect.right - chevronW, y + chevronW * 0.5)
        ..lineTo(rect.right, y)
        ..lineTo(rect.right, y + segW * 0.65)
        ..lineTo(rect.right - chevronW, y + segW * 0.65 + chevronW * 0.5)
        ..close();
      canvas.drawPath(p, isRed ? redPaint : bluePaint);
      isRed = !isRed;
    }
    canvas.restore();

    // Inner card separation border
    final innerBorder = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRect(rect.deflate(borderW), innerBorder);
  }

  void _drawRetroAlbumFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Dark Vintage Leatherette Base
    final leatherPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xFF4E342E),
          const Color(0xFF3E2723),
          const Color(0xFF2E1C14),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(rect, leatherPaint);

    // 2. Double Embossed Gold Leaf Border
    final gold1 = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.35), gold1);

    final gold2 = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.65), gold2);

    // 3. Ornate Gold Corner Pins
    for (final c in [
      rect.topLeft.translate(borderW * 0.5, borderW * 0.5),
      rect.topRight.translate(-borderW * 0.5, borderW * 0.5),
      rect.bottomLeft.translate(borderW * 0.5, -borderW * 0.5),
      rect.bottomRight.translate(-borderW * 0.5, -borderW * 0.5),
    ]) {
      canvas.drawCircle(c, 2.5 * scale, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(
        c,
        5.0 * scale,
        Paint()
          ..color = const Color(0xFFD4AF37).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 * scale,
      );
    }
  }

  void _drawFilm120Frame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Matte Deep Black Film Base
    final basePaint = Paint()..color = const Color(0xFF0F0F12);
    canvas.drawRect(rect, basePaint);

    // 2. Film Frame Border Guideline
    final guidePaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.85), guidePaint);

    // 3. Hasselblad style magazine notches on left and right
    final notchPaint = Paint()..color = const Color(0xFF000000);
    final double midY = rect.center.dy;
    final double notchSize = 7.0 * scale;

    canvas.drawRect(Rect.fromLTWH(rect.left, midY - 24 * scale, notchSize, 12 * scale), notchPaint);
    canvas.drawRect(Rect.fromLTWH(rect.left, midY + 12 * scale, notchSize, 12 * scale), notchPaint);
    canvas.drawRect(Rect.fromLTWH(rect.right - notchSize, midY - 24 * scale, notchSize, 12 * scale), notchPaint);
    canvas.drawRect(Rect.fromLTWH(rect.right - notchSize, midY + 12 * scale, notchSize, 12 * scale), notchPaint);

    // 4. Registration crosshairs (+)
    final crossPaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..strokeWidth = 1.0 * scale;
    final double crossLen = 6.0 * scale;

    canvas.drawLine(Offset(rect.center.dx - crossLen / 2, rect.top + borderW * 0.4), Offset(rect.center.dx + crossLen / 2, rect.top + borderW * 0.4), crossPaint);
    canvas.drawLine(Offset(rect.center.dx, rect.top + borderW * 0.4 - crossLen / 2), Offset(rect.center.dx, rect.top + borderW * 0.4 + crossLen / 2), crossPaint);

    canvas.drawLine(Offset(rect.center.dx - crossLen / 2, rect.bottom - borderW * 0.4), Offset(rect.center.dx + crossLen / 2, rect.bottom - borderW * 0.4), crossPaint);
    canvas.drawLine(Offset(rect.center.dx, rect.bottom - borderW * 0.4 - crossLen / 2), Offset(rect.center.dx, rect.bottom - borderW * 0.4 + crossLen / 2), crossPaint);
  }

  void _drawVintageNewspaperFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Aged Newsprint Paper Base
    final basePaint = Paint()..color = const Color(0xFFECE4D0);
    canvas.drawRect(rect, basePaint);

    // 2. Classic Newspaper Outer & Inner Border Rules
    final thickRule = Paint()
      ..color = const Color(0xFF2E241E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.3), thickRule);

    final thinRule = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.3 + 3.0 * scale), thinRule);
  }

  void _drawGalleryCanvasFloatFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Deep Matte Charcoal Shadowbox
    final boxPaint = Paint()..color = const Color(0xFF1E1E22);
    canvas.drawRect(rect, boxPaint);

    // 2. Beveled Wood Edge
    final bevelPaint = Paint()
      ..color = const Color(0xFF383842).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.4), bevelPaint);

    // 3. Deep Inset Shadow to simulate 3D Floater Box
    final innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRect(rect.deflate(borderW - 1.0 * scale), innerShadow);
  }

  void _drawOilPaintingFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Gilded Museum Gold Base with deep gradient
    final goldPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          const Color(0xFFC5A059),
          const Color(0xFFE8D08D),
          const Color(0xFF8C6D2D),
          const Color(0xFFD4AF37),
        ],
        [0.0, 0.35, 0.7, 1.0],
      );
    canvas.drawRect(rect, goldPaint);

    // 2. Multi-tier Baroque Stepped Ridges
    for (int i = 1; i <= 3; i++) {
      final double inset = borderW * (i / 4.0);
      final hlPaint = Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale;
      canvas.drawRect(rect.deflate(inset), hlPaint);

      final shPaint = Paint()
        ..color = const Color(0xFF5D4037).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale;
      canvas.drawRect(rect.deflate(inset + 1.2 * scale), shPaint);
    }

    // 3. Four Corner Rococo Ornaments
    for (final c in [
      rect.topLeft.translate(borderW * 0.6, borderW * 0.6),
      rect.topRight.translate(-borderW * 0.6, borderW * 0.6),
      rect.bottomLeft.translate(borderW * 0.6, -borderW * 0.6),
      rect.bottomRight.translate(-borderW * 0.6, -borderW * 0.6),
    ]) {
      canvas.drawCircle(c, 3.5 * scale, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(
        c,
        6.0 * scale,
        Paint()
          ..color = const Color(0xFF8C6D2D).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );
    }
  }

  void _drawFineArtDeckleFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Natural Ash Wood Frame
    final woodPaint = Paint()..color = const Color(0xFFDED5C7);
    canvas.drawRect(rect, woodPaint);

    // 2. Subtle wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0xFFC7BCAB).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    for (double y = rect.top + 4 * scale; y < rect.bottom; y += 8 * scale) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y + 1.5 * scale), grainPaint);
    }

    // 3. Inner shadow rim
    final rimPaint = Paint()
      ..color = const Color(0xFF8D8171).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRect(rect.deflate(borderW), rimPaint);
  }

  void _drawStudioCuratorFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Ultra-clean Anodized Black Aluminum Frame
    final basePaint = Paint()..color = const Color(0xFF111111);
    canvas.drawRect(rect, basePaint);

    // 2. Precision Chamfer Highlight Line
    final edgePaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRect(rect.deflate(0.5 * scale), edgePaint);

    // 3. Crisp Inner Border
    final innerPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRect(rect.deflate(borderW), innerPaint);
  }

  void _drawDoublePinstripeFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    final basePaint = Paint()..color = const Color(0xFF18181B);
    canvas.drawRect(rect, basePaint);

    final stripePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;

    canvas.drawRect(rect.deflate(borderW * 0.3), stripePaint);
    canvas.drawRect(rect.deflate(borderW * 0.55), stripePaint);

    final diamondPaint = Paint()..color = const Color(0xFFFFDF79);
    for (final c in [
      rect.topLeft.translate(borderW * 0.42, borderW * 0.42),
      rect.topRight.translate(-borderW * 0.42, borderW * 0.42),
      rect.bottomLeft.translate(borderW * 0.42, -borderW * 0.42),
      rect.bottomRight.translate(-borderW * 0.42, -borderW * 0.42),
    ]) {
      final path = Path()
        ..moveTo(c.dx, c.dy - 4 * scale)
        ..lineTo(c.dx + 4 * scale, c.dy)
        ..lineTo(c.dx, c.dy + 4 * scale)
        ..lineTo(c.dx - 4 * scale, c.dy)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }
  }

  void _drawNeonCyberpunkFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    final basePaint = Paint()..color = const Color(0xFF0B0C10);
    canvas.drawRect(rect, basePaint);

    final cyanGlow = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 10.0 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(borderW * 0.2), Radius.circular(8 * scale)), cyanGlow);

    final magentaLine = Paint()
      ..color = const Color(0xFFFF0080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(borderW * 0.4), Radius.circular(6 * scale)), magentaLine);
  }

  void _drawWeddingBotanicalFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    final basePaint = Paint()..color = const Color(0xFFFCFBF7);
    canvas.drawRect(rect, basePaint);

    final goldLine = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.45), goldLine);

    final leafPaint = Paint()
      ..color = const Color(0xFF8A9A86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    for (final c in [
      rect.topLeft.translate(borderW * 0.45, borderW * 0.45),
      rect.topRight.translate(-borderW * 0.45, borderW * 0.45),
      rect.bottomLeft.translate(borderW * 0.45, -borderW * 0.45),
      rect.bottomRight.translate(-borderW * 0.45, -borderW * 0.45),
    ]) {
      canvas.drawCircle(c, 6.0 * scale, leafPaint);
      canvas.drawCircle(c.translate(4 * scale, -4 * scale), 3.0 * scale, Paint()..color = const Color(0xFFD4AF37));
    }
  }

  void _drawStandardCleanFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    final framePaint = Paint()..color = frameColor;
    canvas.drawRect(rect, framePaint);

    if (template.id == 'minimal_clean') {
      final borderLine = Paint()
        ..color = const Color(0xFF3F3F46)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale;
      canvas.drawRect(rect, borderLine);
    }
  }

  void _drawVintageTicketFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Warm Aged Cardstock Base
    final basePaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [const Color(0xFFF7EBD4), const Color(0xFFEDE0C4)],
        [0.0, 1.0],
      );
    canvas.drawRect(rect, basePaint);

    // 2. Guilloche Dual Framing Lines
    final outerFramePaint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.22), outerFramePaint);

    final innerFramePaint = Paint()
      ..color = const Color(0xFFA1887F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.38), innerFramePaint);

    // 3. Circular Punch-bite Notches on Left & Right Margins
    final double punchR = borderW * 0.55;
    final double punchY = rect.bottom - borderW * 2.2;
    final bitePaint = Paint()
      ..color = const Color(0xFF09090B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(rect.left, punchY), punchR, bitePaint);
    canvas.drawCircle(Offset(rect.right, punchY), punchR, bitePaint);

    // 4. Corner 45-degree Angled Cutouts (Vé xé góc)
    final cornerBiteR = borderW * 0.28;
    for (final c in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      canvas.drawCircle(c, cornerBiteR, bitePaint);
    }

    // 5. Vintage Microprint along top rail
    final tpTop = TextPainter(
      text: TextSpan(
        text: '★ COMPAGNIE INTERNATIONALE DES WAGONS-LITS • BILLET DE PASSAGE ★',
        style: TextStyle(
          color: const Color(0xFF8D6E63),
          fontSize: 5.2 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - borderW * 2);
    tpTop.paint(canvas, Offset(rect.center.dx - tpTop.width / 2, rect.top + borderW * 0.08));
  }

  void _drawDarkroomClotheslineFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Deep Studio Black Base
    final basePaint = Paint()..color = const Color(0xFF141210);
    canvas.drawRect(rect, basePaint);

    // 2. Atmospheric Ruby Darkroom Safelight Ambient Glow
    final safelightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(rect.center.dx, rect.top + borderW * 0.5),
        rect.width * 0.65,
        [
          const Color(0x555C121B),
          const Color(0x223E0D12),
          const Color(0x00141210),
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, safelightPaint);

    // 3. Subtle Studio Wall Texture / Border
    final rimPaint = Paint()
      ..color = const Color(0xFF2E2926)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.3), rimPaint);
  }

  void _drawAntiqueCartographyFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Rich Aged Map Parchment
    final mapBasePaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [const Color(0xFFF2E7D5), const Color(0xFFE5D5BD)],
        [0.0, 1.0],
      );
    canvas.drawRect(rect, mapBasePaint);

    // 2. Outer Deep Walnut Rim
    final rimPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.15), rimPaint);

    // 3. Maritime Navigation Graticule (Degree Alternating Black & Cream Segments)
    final double segLen = 14.0 * scale;
    final double bandW = borderW * 0.35;
    final Rect graticuleRect = rect.deflate(borderW * 0.25);
    final darkSeg = Paint()..color = const Color(0xFF2B1B17);
    final lightSeg = Paint()..color = const Color(0xFFFAF2E1);

    // Top Graticule Edge
    bool alt = true;
    for (double x = graticuleRect.left; x < graticuleRect.right; x += segLen) {
      final double w = math.min(segLen, graticuleRect.right - x);
      canvas.drawRect(Rect.fromLTWH(x, graticuleRect.top, w, bandW), alt ? darkSeg : lightSeg);
      alt = !alt;
    }
    // Bottom Graticule Edge
    alt = false;
    for (double x = graticuleRect.left; x < graticuleRect.right; x += segLen) {
      final double w = math.min(segLen, graticuleRect.right - x);
      canvas.drawRect(Rect.fromLTWH(x, graticuleRect.bottom - bandW, w, bandW), alt ? darkSeg : lightSeg);
      alt = !alt;
    }
    // Left Graticule Edge
    alt = true;
    for (double y = graticuleRect.top + bandW; y < graticuleRect.bottom - bandW; y += segLen) {
      final double h = math.min(segLen, graticuleRect.bottom - bandW - y);
      canvas.drawRect(Rect.fromLTWH(graticuleRect.left, y, bandW, h), alt ? darkSeg : lightSeg);
      alt = !alt;
    }
    // Right Graticule Edge
    alt = false;
    for (double y = graticuleRect.top + bandW; y < graticuleRect.bottom - bandW; y += segLen) {
      final double h = math.min(segLen, graticuleRect.bottom - bandW - y);
      canvas.drawRect(Rect.fromLTWH(graticuleRect.right - bandW, y, bandW, h), alt ? darkSeg : lightSeg);
      alt = !alt;
    }

    // Inner Map Boundary Line
    final innerMapLine = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRect(rect.deflate(borderW * 0.65), innerMapLine);

    // 4 Corner Antique Brass Brackets with Rivets
    final double bracketSize = borderW * 0.9;
    final brassPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.topLeft.translate(bracketSize, bracketSize),
        [const Color(0xFFD4AF37), const Color(0xFF8C6239)],
        [0.0, 1.0],
      );

    for (final corner in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      final double signX = (corner.dx == rect.topLeft.dx) ? 1.0 : -1.0;
      final double signY = (corner.dy == rect.topLeft.dy) ? 1.0 : -1.0;
      final p = Path()
        ..moveTo(corner.dx + signX * borderW * 0.18, corner.dy + signY * borderW * 0.18)
        ..lineTo(corner.dx + signX * bracketSize, corner.dy + signY * borderW * 0.18)
        ..lineTo(corner.dx + signX * borderW * 0.18, corner.dy + signY * bracketSize)
        ..close();
      canvas.drawPath(p, brassPaint);

      // Brass Rivet
      final rivetCenter = Offset(corner.dx + signX * borderW * 0.45, corner.dy + signY * borderW * 0.45);
      canvas.drawCircle(rivetCenter, 2.0 * scale, Paint()..color = const Color(0xFF3E2723));
      canvas.drawCircle(rivetCenter, 1.0 * scale, Paint()..color = const Color(0xFFFFD54F));
    }
  }

  void _drawCassetteTapeFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Molded Charcoal Cassette Body
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(10 * scale));
    final bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [const Color(0xFF2D2D34), const Color(0xFF1E1E22)],
        [0.0, 1.0],
      );
    canvas.drawRRect(rrect, bodyPaint);

    // 2. Beveled Inner Plastic Shell
    final bevelPaint = Paint()
      ..color = const Color(0xFF45454F).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRRect(rrect.deflate(borderW * 0.3), bevelPaint);

    // 3. Side Traction Grip Ridges (Gân ma sát 2 bên thân cassette)
    final ribPaint = Paint()
      ..color = const Color(0xFF151518)
      ..strokeWidth = 1.8 * scale;
    final double midY = rect.center.dy;
    for (int r = -3; r <= 3; r++) {
      final double y = midY + r * 6 * scale;
      canvas.drawLine(Offset(rect.left + 2 * scale, y), Offset(rect.left + borderW * 0.22, y), ribPaint);
      canvas.drawLine(Offset(rect.right - borderW * 0.22, y), Offset(rect.right - 2 * scale, y), ribPaint);
    }

    // 4. Corner Philips Screws
    final double screwInset = borderW * 0.42;
    final screwBase = Paint()..color = const Color(0xFF9E9E9E);
    final screwSlot = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 0.9 * scale;

    for (final sc in [
      rect.topLeft.translate(screwInset, screwInset),
      rect.topRight.translate(-screwInset, screwInset),
      rect.bottomLeft.translate(screwInset, -screwInset),
      rect.bottomRight.translate(-screwInset, -screwInset),
    ]) {
      canvas.drawCircle(sc, 3.2 * scale, screwBase);
      canvas.drawCircle(sc, 3.2 * scale, Paint()..color = const Color(0xFF616161)..style = PaintingStyle.stroke..strokeWidth = 0.8 * scale);
      // Screw Cross (+)
      canvas.drawLine(sc.translate(-1.8 * scale, 0), sc.translate(1.8 * scale, 0), screwSlot);
      canvas.drawLine(sc.translate(0, -1.8 * scale), sc.translate(0, 1.8 * scale), screwSlot);
    }

    // 5. Tape Shell Micro-engraving
    final tpBrand = TextPainter(
      text: TextSpan(
        text: 'C-90  HIGH BIAS 70µs • COMPACT CASSETTE • TYPE II',
        style: TextStyle(
          color: const Color(0xFF757575),
          fontSize: 5.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - borderW * 2);
    tpBrand.paint(canvas, Offset(rect.center.dx - tpBrand.width / 2, rect.top + borderW * 0.12));
  }

  void _drawRetroViewmasterFrame(Canvas canvas, Rect rect, double borderW, double scale) {
    // 1. Classic Red Molded Plastic Casing
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(16 * scale));
    final casingPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [const Color(0xFFE53935), const Color(0xFFC62828), const Color(0xFF8E0000)],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(rrect, casingPaint);

    // 2. 3D Plastic Highlight & Shadow Edges
    final highlightEdge = Paint()
      ..color = const Color(0x66FFCDD2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale;
    canvas.drawRRect(rrect.deflate(1.5 * scale), highlightEdge);

    final innerGroove = Paint()
      ..color = const Color(0xFF5A0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRRect(rrect.deflate(borderW * 0.35), innerGroove);

    // 3. Right-side Film Advance Lever (Cần gạt đẩy đĩa View-Master)
    final double leverW = 10.0 * scale;
    final double leverH = 34.0 * scale;
    final double leverY = rect.center.dy - leverH / 2;
    final Rect leverRect = Rect.fromLTWH(rect.right - leverW * 0.6, leverY, leverW, leverH);

    final leverPaint = Paint()..color = const Color(0xFFF5F5DC);
    canvas.drawRRect(RRect.fromRectAndRadius(leverRect, Radius.circular(4 * scale)), leverPaint);
    final leverShade = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(leverRect, Radius.circular(4 * scale)), leverShade);

    // 4. Dual Stereoscopic Viewing Lens Indicators (Đường viền ống ngắm kép)
    final double lensR = borderW * 0.45;
    final lensRim = Paint()
      ..color = const Color(0x44FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawCircle(rect.topLeft.translate(borderW * 0.7, borderW * 0.7), lensR, lensRim);
    canvas.drawCircle(rect.topRight.translate(-borderW * 0.7, borderW * 0.7), lensR, lensRim);
  }

  // -------------------------------------------------------------
  // Post-Photo Foreground Decorations
  // -------------------------------------------------------------
  void _drawForegroundDecorations(
    Canvas canvas,
    Rect totalRect,
    Rect innerRect,
    Rect matRect,
    double borderW,
    double scale,
    double polaroidExtra, {
    double ticketExtra = 0.0,
    double cassetteExtra = 0.0,
  }) {
    // 1. Scrapbook Washi Tapes
    if (template.id == 'scrapbook_kraft') {
      _drawWashiTapes(canvas, innerRect, scale);
    }

    // 2. Vintage Stamp Cancellation Postmark
    if (template.id == 'vintage_stamp') {
      _drawPostalCancelStamp(canvas, innerRect, scale);
    }

    // 3. Magazine Vogue Masthead & Barcode
    if (template.id == 'magazine_vogue') {
      _drawMagazineOverlay(canvas, totalRect, innerRect, scale);
    }

    // 4. Museum Exhibition Brass Plaque
    if (template.id == 'museum_gallery' && (captionText?.isNotEmpty ?? false)) {
      _drawMuseumBrassPlaque(canvas, totalRect, innerRect, matRect, scale);
    }

    // 5. Polaroid Handwritten Caption
    if (template.id == 'polaroid_classic') {
      _drawPolaroidCaption(canvas, totalRect, polaroidExtra, scale);
    }

    // 6. Vintage Postcard Overlay
    if (template.id == 'vintage_postcard') {
      _drawVintagePostcardDecorations(canvas, totalRect, innerRect, scale);
    }

    // 7. Retro Album Corner Photo Mounts
    if (template.id == 'retro_album_corners') {
      _drawRetroAlbumCornerMounts(canvas, innerRect, scale);
    }

    // 8. Medium Format 120 Film Rebate
    if (template.id == 'film_120_hasselblad') {
      _drawFilm120RebateText(canvas, totalRect, innerRect, scale);
    }

    // 9. Vintage Newspaper Masthead & Rules
    if (template.id == 'vintage_newspaper') {
      _drawVintageNewspaperMasthead(canvas, totalRect, innerRect, borderW, scale);
    }

    // 10. Gallery Canvas Float Blind Deboss Seal & Edition
    if (template.id == 'gallery_canvas_float') {
      _drawGalleryFloatDecorations(canvas, totalRect, innerRect, scale);
    }

    // 11. Oil Painting Museum Nameplate & Highlights
    if (template.id == 'oil_painting_canvas') {
      _drawOilPaintingDecorations(canvas, totalRect, innerRect, matRect, scale);
    }

    // 12. Fine Art Deckle Edge & Red Wax Seal
    if (template.id == 'fineart_deckle_edge') {
      _drawFineArtDeckleDecorations(canvas, totalRect, innerRect, scale);
    }

    // 13. Studio Minimal Curator Label
    if (template.id == 'studio_minimal_curator') {
      _drawStudioCuratorDecorations(canvas, totalRect, innerRect, scale);
    }

    // 14. Vintage Boarding Ticket Stub & Punches
    if (template.id == 'vintage_boarding_ticket') {
      _drawVintageTicketDecorations(canvas, totalRect, innerRect, matRect, ticketExtra, scale);
    }

    // 15. Darkroom Clothesline & Wooden Pegs
    if (template.id == 'darkroom_clothesline') {
      _drawDarkroomClotheslineDecorations(canvas, totalRect, innerRect, scale);
    }

    // 16. Antique Cartography Compass & Coordinates
    if (template.id == 'antique_cartography') {
      _drawAntiqueCartographyDecorations(canvas, totalRect, innerRect, borderW, scale);
    }

    // 17. 80s Cassette Tape Reels & Synthwave Stripes
    if (template.id == 'cassette_tape_80s') {
      _drawCassetteTapeDecorations(canvas, totalRect, innerRect, cassetteExtra, scale);
    }

    // 18. Retro View-Master Stereoscopic Reel Markers
    if (template.id == 'retro_viewmaster') {
      _drawRetroViewmasterDecorations(canvas, totalRect, innerRect, borderW, scale);
    }
  }

  void _drawWashiTapes(Canvas canvas, Rect rect, double scale) {
    final tapePaint = Paint()
      ..color = const Color(0xE0E08272)
      ..style = PaintingStyle.fill;
    final double tLen = 42.0 * scale;
    final double tW = 18.0 * scale;

    // Top-Left Tape
    final pTL = Path()
      ..moveTo(rect.left - 12 * scale, rect.top + tW)
      ..lineTo(rect.left + tW, rect.top - 12 * scale)
      ..lineTo(rect.left + tW + tLen * 0.4, rect.top - 12 * scale + tW * 0.4)
      ..lineTo(rect.left - 12 * scale + tLen * 0.4, rect.top + tW + tW * 0.4)
      ..close();
    canvas.drawPath(pTL, tapePaint);

    // Top-Right Tape (Sage Green)
    final tapeGreen = Paint()..color = const Color(0xE082A892);
    final pTR = Path()
      ..moveTo(rect.right - tW - tLen * 0.4, rect.top - 12 * scale)
      ..lineTo(rect.right + 12 * scale, rect.top + tW)
      ..lineTo(rect.right + 12 * scale - tW * 0.4, rect.top + tW + tLen * 0.4)
      ..lineTo(rect.right - tW - tLen * 0.4 - tW * 0.4, rect.top - 12 * scale + tLen * 0.4)
      ..close();
    canvas.drawPath(pTR, tapeGreen);

    // Bottom-Left Tape
    final pBL = Path()
      ..moveTo(rect.left - 12 * scale, rect.bottom - tW)
      ..lineTo(rect.left + tW, rect.bottom + 12 * scale)
      ..lineTo(rect.left + tW + tLen * 0.4, rect.bottom + 12 * scale - tW * 0.4)
      ..lineTo(rect.left - 12 * scale + tLen * 0.4, rect.bottom - tW - tW * 0.4)
      ..close();
    canvas.drawPath(pBL, tapeGreen);

    // Bottom-Right Tape
    final pBR = Path()
      ..moveTo(rect.right - tW - tLen * 0.4, rect.bottom + 12 * scale)
      ..lineTo(rect.right + 12 * scale, rect.bottom - tW)
      ..lineTo(rect.right + 12 * scale - tW * 0.4, rect.bottom - tW - tLen * 0.4)
      ..lineTo(rect.right - tW - tLen * 0.4 - tW * 0.4, rect.bottom + 12 * scale - tLen * 0.4)
      ..close();
    canvas.drawPath(pBR, tapePaint);
  }

  void _drawPostalCancelStamp(Canvas canvas, Rect rect, double scale) {
    final stampPaint = Paint()
      ..color = const Color(0xAA9E2A2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;

    final Offset center = rect.bottomRight.translate(-25 * scale, -25 * scale);
    final double radius = 32.0 * scale;

    canvas.drawCircle(center, radius, stampPaint);
    canvas.drawCircle(center, radius - 5 * scale, stampPaint..strokeWidth = 1.0 * scale);

    final datePainter = TextPainter(
      text: TextSpan(
        text: 'POSTAL\n2026',
        style: TextStyle(
          color: const Color(0xAA9E2A2B),
          fontSize: 8.0 * scale,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    datePainter.paint(canvas, center.translate(-datePainter.width / 2, -datePainter.height / 2));

    final wavePaint = Paint()
      ..color = const Color(0x889E2A2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    for (int i = -2; i <= 2; i++) {
      final double wy = center.dy + i * 8.0 * scale;
      final wave = Path();
      wave.moveTo(center.dx - radius - 30 * scale, wy);
      wave.quadraticBezierTo(center.dx - radius - 15 * scale, wy - 3 * scale, center.dx - radius, wy);
      wave.quadraticBezierTo(center.dx - radius + 15 * scale, wy + 3 * scale, center.dx - radius + 30 * scale, wy);
      canvas.drawPath(wave, wavePaint);
    }
  }

  void _drawMagazineOverlay(Canvas canvas, Rect totalRect, Rect innerRect, double scale) {
    final String title = (captionText?.isNotEmpty ?? false) ? captionText! : 'VOGUE';
    final mastheadPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: totalRect.width * 0.14,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0 * scale,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10 * scale, offset: Offset(2 * scale, 2 * scale)),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: totalRect.width);

    mastheadPainter.paint(canvas, Offset(totalRect.center.dx - mastheadPainter.width / 2, innerRect.top + 8 * scale));

    final subPainter = TextPainter(
      text: TextSpan(
        text: 'SPECIAL LUXURY EDITION • 2026',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 10 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0 * scale,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4 * scale, offset: Offset(1 * scale, 1 * scale)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas, Offset(totalRect.center.dx - subPainter.width / 2, innerRect.top + mastheadPainter.height + 4 * scale));

    final double bcW = 55.0 * scale;
    final double bcH = 30.0 * scale;
    final Rect bcRect = Rect.fromLTWH(innerRect.right - bcW - 12 * scale, innerRect.bottom - bcH - 12 * scale, bcW, bcH);

    canvas.drawRRect(RRect.fromRectAndRadius(bcRect, Radius.circular(3 * scale)), Paint()..color = Colors.white.withValues(alpha: 0.92));
    final barPaint = Paint()..color = Colors.black..strokeWidth = 1.5 * scale;

    final double startX = bcRect.left + 5 * scale;
    for (double x = startX; x < bcRect.right - 5 * scale; x += 3.5 * scale) {
      canvas.drawLine(Offset(x, bcRect.top + 4 * scale), Offset(x, bcRect.bottom - 6 * scale), barPaint);
    }
  }

  void _drawMuseumBrassPlaque(Canvas canvas, Rect totalRect, Rect innerRect, Rect matRect, double scale) {
    final double plaqueW = math.min(matRect.width * 0.55, 180.0 * scale);
    final double plaqueH = 32.0 * scale;
    final double cy = innerRect.bottom + (matRect.bottom - innerRect.bottom) * 0.5;

    final Rect pRect = Rect.fromCenter(
      center: Offset(totalRect.center.dx, cy),
      width: plaqueW,
      height: plaqueH,
    );

    // Plaque drop shadow on white mat
    final pShadow = Path()..addRRect(RRect.fromRectAndRadius(pRect, Radius.circular(3 * scale)));
    canvas.drawShadow(pShadow, Colors.black.withValues(alpha: 0.3), 4.0 * scale, true);

    // Brass Metallic Gradient
    final brassPaint = Paint()
      ..shader = ui.Gradient.linear(
        pRect.topLeft,
        pRect.bottomRight,
        [
          const Color(0xFFFFECB3),
          const Color(0xFFD4AF37),
          const Color(0xFF8D6E63),
          const Color(0xFFFFD54F),
        ],
        [0.0, 0.35, 0.7, 1.0],
      );
    canvas.drawRRect(RRect.fromRectAndRadius(pRect, Radius.circular(3 * scale)), brassPaint);

    // Brass Plaque Border
    final borderPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(pRect, Radius.circular(3 * scale)), borderPaint);

    // 4 Corner Screws
    final screwPaint = Paint()..color = const Color(0xFF4E342E);
    for (final sc in [
      pRect.topLeft.translate(5 * scale, 5 * scale),
      pRect.topRight.translate(-5 * scale, 5 * scale),
      pRect.bottomLeft.translate(5 * scale, -5 * scale),
      pRect.bottomRight.translate(-5 * scale, -5 * scale),
    ]) {
      canvas.drawCircle(sc, 1.5 * scale, screwPaint);
    }

    // Engraved Text
    final tp = TextPainter(
      text: TextSpan(
        text: (captionText?.isNotEmpty ?? false) ? captionText! : 'FINE ART EXHIBITION',
        style: TextStyle(
          color: const Color(0xFF2E1C14),
          fontSize: 9.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0 * scale,
          fontFamily: 'serif',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: plaqueW - 16 * scale);

    tp.paint(canvas, Offset(pRect.center.dx - tp.width / 2, pRect.center.dy - tp.height / 2));
  }

  void _drawPolaroidCaption(Canvas canvas, Rect totalRect, double polaroidExtra, double scale) {
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'Memories • Forever';
    final double cy = totalRect.bottom - polaroidExtra * 0.5;

    final tp = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF27272A),
          fontSize: (polaroidExtra * 0.22).clamp(12.0 * scale, 96.0 * scale),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5 * scale,
          fontStyle: FontStyle.italic,
          fontFamily: 'cursive',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: totalRect.width * 0.8);

    tp.paint(canvas, Offset(totalRect.center.dx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawVintagePostcardDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double scale) {
    // 1. Air Mail Blue Badge (Top Left)
    final badgeRect = Rect.fromLTWH(innerRect.left + 4 * scale, innerRect.top - 20 * scale, 86 * scale, 16 * scale);
    final badgePaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, Radius.circular(3 * scale)), badgePaint);

    final badgeBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect.deflate(1.2 * scale), Radius.circular(2 * scale)), badgeBorder);

    final tpBadge = TextPainter(
      text: TextSpan(
        text: 'PAR AVION  AIR MAIL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 6.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpBadge.paint(canvas, Offset(badgeRect.center.dx - tpBadge.width / 2, badgeRect.center.dy - tpBadge.height / 2));

    // 2. Vintage Postmark Stamp (Top Right)
    final Offset postmarkCenter = Offset(innerRect.right - 26 * scale, innerRect.top - 8 * scale);
    final inkPaint = Paint()
      ..color = const Color(0xB0263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawCircle(postmarkCenter, 16 * scale, inkPaint);
    canvas.drawCircle(postmarkCenter, 12 * scale, inkPaint);

    final tpStamp = TextPainter(
      text: TextSpan(
        text: 'POSTAL\n1974',
        style: TextStyle(
          color: const Color(0xB0263238),
          fontSize: 5.0 * scale,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tpStamp.paint(canvas, Offset(postmarkCenter.dx - tpStamp.width / 2, postmarkCenter.dy - tpStamp.height / 2));

    // Wavy cancellation ink lines
    for (int j = -2; j <= 2; j++) {
      final double wy = postmarkCenter.dy + j * 4.5 * scale;
      final wavePath = Path();
      wavePath.moveTo(postmarkCenter.dx + 18 * scale, wy);
      for (double wx = 0; wx < 30 * scale; wx += 7 * scale) {
        wavePath.relativeQuadraticBezierTo(1.8 * scale, -1.8 * scale, 3.5 * scale, 0);
        wavePath.relativeQuadraticBezierTo(1.8 * scale, 1.8 * scale, 3.5 * scale, 0);
      }
      canvas.drawPath(wavePath, inkPaint);
    }

    // 3. Bottom Caption (Retro Script/Typewriter)
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'GREETINGS FROM • 1974';
    final tpCap = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF4E342E),
          fontSize: 9.5 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8 * scale,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRect.width);
    tpCap.paint(canvas, Offset(totalRect.center.dx - tpCap.width / 2, innerRect.bottom + 6 * scale));
  }

  void _drawRetroAlbumCornerMounts(Canvas canvas, Rect innerRect, double scale) {
    final double gapPx = gapSize * scale * 0.8;
    final double mountSize = 16.0 * scale;

    final mountPaint = Paint()..color = const Color(0xFF212121);
    final goldSlit = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;

    for (int i = 0; i < layout.slots.length; i++) {
      final slot = layout.slots[i];
      final slotL = innerRect.left + slot.x * innerRect.width + (slot.x > 0.001 ? gapPx / 2 : 0.0);
      final slotT = innerRect.top + slot.y * innerRect.height + (slot.y > 0.001 ? gapPx / 2 : 0.0);
      final slotR = innerRect.left + (slot.x + slot.w) * innerRect.width - ((slot.x + slot.w) < 0.999 ? gapPx / 2 : 0.0);
      final slotB = innerRect.top + (slot.y + slot.h) * innerRect.height - ((slot.y + slot.h) < 0.999 ? gapPx / 2 : 0.0);
      if (slotR <= slotL || slotB <= slotT) continue;

      final sRect = Rect.fromLTRB(slotL, slotT, slotR, slotB);

      // Top-Left corner mount
      final pTL = Path()
        ..moveTo(sRect.left, sRect.top + mountSize)
        ..lineTo(sRect.left + mountSize, sRect.top)
        ..lineTo(sRect.left, sRect.top)
        ..close();
      canvas.drawPath(pTL, mountPaint);
      canvas.drawLine(Offset(sRect.left, sRect.top + mountSize), Offset(sRect.left + mountSize, sRect.top), goldSlit);

      // Top-Right corner mount
      final pTR = Path()
        ..moveTo(sRect.right - mountSize, sRect.top)
        ..lineTo(sRect.right, sRect.top + mountSize)
        ..lineTo(sRect.right, sRect.top)
        ..close();
      canvas.drawPath(pTR, mountPaint);
      canvas.drawLine(Offset(sRect.right - mountSize, sRect.top), Offset(sRect.right, sRect.top + mountSize), goldSlit);

      // Bottom-Left corner mount
      final pBL = Path()
        ..moveTo(sRect.left, sRect.bottom - mountSize)
        ..lineTo(sRect.left + mountSize, sRect.bottom)
        ..lineTo(sRect.left, sRect.bottom)
        ..close();
      canvas.drawPath(pBL, mountPaint);
      canvas.drawLine(Offset(sRect.left, sRect.bottom - mountSize), Offset(sRect.left + mountSize, sRect.bottom), goldSlit);

      // Bottom-Right corner mount
      final pBR = Path()
        ..moveTo(sRect.right - mountSize, sRect.bottom)
        ..lineTo(sRect.right, sRect.bottom - mountSize)
        ..lineTo(sRect.right, sRect.bottom)
        ..close();
      canvas.drawPath(pBR, mountPaint);
      canvas.drawLine(Offset(sRect.right - mountSize, sRect.bottom), Offset(sRect.right, sRect.bottom - mountSize), goldSlit);
    }
  }

  void _drawFilm120RebateText(Canvas canvas, Rect totalRect, Rect innerRect, double scale) {
    // Top film text
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'KODAK PORTRA 400 • 120';
    final tpTop = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFFFF9800),
          fontSize: 8.0 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.2 * scale,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: totalRect.width);
    tpTop.paint(canvas, Offset(totalRect.center.dx - tpTop.width / 2, innerRect.top - 16 * scale));

    // Bottom film text
    final tpBotL = TextPainter(
      text: TextSpan(
        text: '▶ 12',
        style: TextStyle(
          color: const Color(0xFFFF9800),
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpBotL.paint(canvas, Offset(innerRect.left + 6 * scale, innerRect.bottom + 5 * scale));

    final tpBotR = TextPainter(
      text: TextSpan(
        text: 'EXP 120 • SAFETY FILM',
        style: TextStyle(
          color: const Color(0xFFFF9800),
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5 * scale,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpBotR.paint(canvas, Offset(innerRect.right - tpBotR.width - 6 * scale, innerRect.bottom + 5 * scale));
  }

  void _drawVintageNewspaperMasthead(Canvas canvas, Rect totalRect, Rect innerRect, double borderW, double scale) {
    final double bannerTop = totalRect.top + borderW * 0.8;
    final double bannerBottom = innerRect.top - 4 * scale;
    final double cy = (bannerTop + bannerBottom) * 0.5;

    // Newspaper title
    final String title = (captionText?.isNotEmpty ?? false) ? captionText! : 'THE DAILY CHRONICLE';
    final tpTitle = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: const Color(0xFF1E140E),
          fontSize: 11.5 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2 * scale,
          fontFamily: 'serif',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: totalRect.width - 32 * scale);
    tpTitle.paint(canvas, Offset(totalRect.center.dx - tpTitle.width / 2, cy - tpTitle.height * 0.6));

    // Subtitle rule
    final tpSub = TextPainter(
      text: TextSpan(
        text: 'EST. 1928 • SPECIAL PICTORIAL EDITION • FIVE CENTS',
        style: TextStyle(
          color: const Color(0xFF5D4037),
          fontSize: 5.5 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSub.paint(canvas, Offset(totalRect.center.dx - tpSub.width / 2, cy + tpTitle.height * 0.45));

    // Bottom Asterisks Rule
    final tpStars = TextPainter(
      text: TextSpan(
        text: '★   ★   ★',
        style: TextStyle(
          color: const Color(0xFF5D4037),
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 3.0 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpStars.paint(canvas, Offset(totalRect.center.dx - tpStars.width / 2, innerRect.bottom + 5 * scale));
  }

  void _drawGalleryFloatDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double scale) {
    // 1. Blind Debossed Circular Gallery Seal (Bottom Right of mat)
    final Offset sealCenter = Offset(innerRect.right - 28 * scale, innerRect.bottom + 18 * scale);
    final debossLight = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    final debossDark = Paint()
      ..color = const Color(0xFFD5CEBF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;

    canvas.drawCircle(sealCenter.translate(0.5 * scale, 0.5 * scale), 14 * scale, debossLight);
    canvas.drawCircle(sealCenter, 14 * scale, debossDark);
    canvas.drawCircle(sealCenter, 10 * scale, debossDark);

    // Star icon inside seal
    final starPaint = Paint()..color = const Color(0xFFC4BCAD);
    canvas.drawCircle(sealCenter, 3.0 * scale, starPaint);

    // 2. Fine Artist Pencil Edition Number (Bottom Left)
    final tpEdition = TextPainter(
      text: TextSpan(
        text: 'Ed. 1/50 • Artist Proof',
        style: TextStyle(
          color: const Color(0xFF757575),
          fontSize: 7.5 * scale,
          fontStyle: FontStyle.italic,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEdition.paint(canvas, Offset(innerRect.left + 6 * scale, innerRect.bottom + 14 * scale));

    // 3. Center Contemporary Gallery Typography
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'CONTEMPORARY ART • COLLECTION 2026';
    final tpCap = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF2E2E33),
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.2 * scale,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRect.width * 0.7);
    tpCap.paint(canvas, Offset(totalRect.center.dx - tpCap.width / 2, innerRect.bottom + 14 * scale));
  }

  void _drawOilPaintingDecorations(Canvas canvas, Rect totalRect, Rect innerRect, Rect matRect, double scale) {
    // Miniature Gilded Brass Picture Plaque (Bottom Center)
    final double plaqueW = math.min(matRect.width * 0.5, 150.0 * scale);
    final double plaqueH = 26.0 * scale;
    final double cy = innerRect.bottom + (matRect.bottom - innerRect.bottom) * 0.5;

    final Rect pRect = Rect.fromCenter(
      center: Offset(totalRect.center.dx, cy),
      width: plaqueW,
      height: plaqueH,
    );

    // Shadow
    final pShadow = Path()..addRRect(RRect.fromRectAndRadius(pRect, Radius.circular(2 * scale)));
    canvas.drawShadow(pShadow, Colors.black.withValues(alpha: 0.4), 4.0 * scale, true);

    // Gilt metallic brass plate gradient
    final plaquePaint = Paint()
      ..shader = ui.Gradient.linear(
        pRect.topLeft,
        pRect.bottomRight,
        [
          const Color(0xFFFFE082),
          const Color(0xFFD4AF37),
          const Color(0xFF8D6E63),
          const Color(0xFFFFD54F),
        ],
        [0.0, 0.35, 0.7, 1.0],
      );
    canvas.drawRRect(RRect.fromRectAndRadius(pRect, Radius.circular(2 * scale)), plaquePaint);

    final pBorder = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(pRect, Radius.circular(2 * scale)), pBorder);

    // Engraved title
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'MASTERPIECE GALLERY';
    final tp = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF2E1C14),
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.8 * scale,
          fontFamily: 'serif',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: plaqueW - 12 * scale);
    tp.paint(canvas, Offset(pRect.center.dx - tp.width / 2, pRect.center.dy - tp.height / 2));
  }

  void _drawFineArtDeckleDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double scale) {
    // 1. Hand-torn deckle paper edge outline around inner photo canvas
    final deckleShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRect(innerRect.inflate(1.5 * scale), deckleShadow);

    // 2. Crimson Wax Seal (Bottom Left)
    final Offset sealCenter = Offset(innerRect.left + 22 * scale, innerRect.bottom + 18 * scale);
    final waxPaint = Paint()
      ..shader = ui.Gradient.linear(
        sealCenter.translate(-12 * scale, -12 * scale),
        sealCenter.translate(12 * scale, 12 * scale),
        [
          const Color(0xFFD32F2F),
          const Color(0xFFB71C1C),
          const Color(0xFF7F0000),
        ],
        [0.0, 0.5, 1.0],
      );
    final waxShadow = Path()..addOval(Rect.fromCircle(center: sealCenter, radius: 12 * scale));
    canvas.drawShadow(waxShadow, Colors.black.withValues(alpha: 0.35), 4.0 * scale, true);
    canvas.drawCircle(sealCenter, 12 * scale, waxPaint);

    final waxEmboss = Paint()
      ..color = const Color(0xFFFFCDD2).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawCircle(sealCenter, 8 * scale, waxEmboss);

    // Inner Crest Monogram
    final tpMonogram = TextPainter(
      text: TextSpan(
        text: '✦',
        style: TextStyle(
          color: const Color(0xFFFFEBEE),
          fontSize: 8.0 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMonogram.paint(canvas, Offset(sealCenter.dx - tpMonogram.width / 2, sealCenter.dy - tpMonogram.height / 2));

    // 3. Artist Cursive Pencil Signature (Bottom Right)
    final tpSig = TextPainter(
      text: TextSpan(
        text: 'Hand Signed • 2026',
        style: TextStyle(
          color: const Color(0xFF5D4037),
          fontSize: 8.5 * scale,
          fontStyle: FontStyle.italic,
          fontFamily: 'cursive',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSig.paint(canvas, Offset(innerRect.right - tpSig.width - 6 * scale, innerRect.bottom + 14 * scale));

    // 4. Center Caption
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'ORIGINAL WORK • LIMITED EDITION';
    final tpCap = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF424242),
          fontSize: 8.0 * scale,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0 * scale,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRect.width * 0.6);
    tpCap.paint(canvas, Offset(totalRect.center.dx - tpCap.width / 2, innerRect.bottom + 14 * scale));
  }

  void _drawStudioCuratorDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double scale) {
    final double cy = innerRect.bottom + 16 * scale;

    // 1. Curator Exhibition Title (Swiss Grotesk Typography)
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'EXHIBIT NO. 07 • CURATED COLLECTION';
    final tpTitle = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF111111),
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRect.width);
    tpTitle.paint(canvas, Offset(totalRect.center.dx - tpTitle.width / 2, cy - tpTitle.height * 0.5));

    // 2. Sub-line Metadata
    final tpMeta = TextPainter(
      text: TextSpan(
        text: 'ARCHIVAL PIGMENT PRINT ON 100% COTTON RAG • 1:1 MASTER EDITION',
        style: TextStyle(
          color: const Color(0xFF888888),
          fontSize: 5.5 * scale,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMeta.paint(canvas, Offset(totalRect.center.dx - tpMeta.width / 2, cy + tpTitle.height * 0.65));
  }

  void _drawVintageTicketDecorations(Canvas canvas, Rect totalRect, Rect innerRect, Rect matRect, double ticketExtra, double scale) {
    // 1. Perforated Detachment Line (Đường răng cưa xé cuống vé)
    final double perfY = innerRect.bottom + 8 * scale;
    final perfPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 1.2 * scale;
    const double dashW = 4.0;
    const double spaceW = 3.5;
    double curX = totalRect.left + 12 * scale;
    while (curX < totalRect.right - 12 * scale) {
      canvas.drawLine(Offset(curX, perfY), Offset(curX + dashW * scale, perfY), perfPaint);
      curX += (dashW + spaceW) * scale;
    }

    // "✂ TEAR HERE" small instruction
    final tpTear = TextPainter(
      text: TextSpan(
        text: '✂ TEAR HERE  •  VOID IF DETACHED',
        style: TextStyle(
          color: const Color(0xFF8D6E63),
          fontSize: 5.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTear.paint(canvas, Offset(totalRect.center.dx - tpTear.width / 2, perfY - tpTear.height - 2 * scale));

    // 2. Ticket Stub Region
    final double stubCenterY = (perfY + matRect.bottom) * 0.5;

    // Left: Passenger Class / Serial Red Rubber Stamp
    final Rect stampBox = Rect.fromLTWH(matRect.left + 6 * scale, stubCenterY - 11 * scale, 48 * scale, 22 * scale);
    final stampPaint = Paint()
      ..color = const Color(0xFFC62828).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(stampBox, Radius.circular(2 * scale)), stampPaint);

    final tpClass = TextPainter(
      text: TextSpan(
        text: '№ 84920\n1st CLASS',
        style: TextStyle(
          color: const Color(0xFFC62828).withValues(alpha: 0.9),
          fontSize: 6.0 * scale,
          fontWeight: FontWeight.bold,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: stampBox.width);
    tpClass.paint(canvas, Offset(stampBox.center.dx - tpClass.width / 2, stampBox.center.dy - tpClass.height / 2));

    // Center: Ticket Destination / Caption
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'ORIENT EXPRESS • VOITURE-LITS';
    final tpCap = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF2E1C14),
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5 * scale,
          fontFamily: 'serif',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: matRect.width - 120 * scale);
    tpCap.paint(canvas, Offset(totalRect.center.dx - tpCap.width / 2, stubCenterY - tpCap.height / 2));

    // Right: Realistic Vertical Barcode Lines
    final double bcW = 46.0 * scale;
    final double bcH = 20.0 * scale;
    final double bcL = matRect.right - bcW - 6 * scale;
    final barPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 1.2 * scale;
    const List<double> barSpacings = [2, 5, 8, 10, 13, 17, 21, 23, 27, 30, 34, 37, 40, 43];
    for (final s in barSpacings) {
      final double bx = bcL + (s / 46.0) * bcW;
      canvas.drawLine(Offset(bx, stubCenterY - bcH / 2), Offset(bx, stubCenterY + bcH / 2), barPaint);
    }

    // 3. Tilted Transit Ink Stamp across corner
    canvas.save();
    final Offset stampCenter = Offset(innerRect.right - 28 * scale, innerRect.bottom - 24 * scale);
    canvas.translate(stampCenter.dx, stampCenter.dy);
    canvas.rotate(-12 * math.pi / 180.0);

    final stampInk = Paint()
      ..color = const Color(0x994A148C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawCircle(Offset.zero, 20 * scale, stampInk);
    canvas.drawCircle(Offset.zero, 16 * scale, stampInk);

    final tpInk = TextPainter(
      text: TextSpan(
        text: '★ RAILWAY ★\n14 OCT 1934\nVALIDÉ',
        style: TextStyle(
          color: const Color(0x994A148C),
          fontSize: 5.0 * scale,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tpInk.paint(canvas, Offset(-tpInk.width / 2, -tpInk.height / 2));
    canvas.restore();
  }

  void _drawDarkroomClotheslineDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double scale) {
    // 1. Clothesline Cord across the top
    final double ropeY = innerRect.top - 14 * scale;

    // Cord drop shadow
    final ropeShadow = Paint()
      ..color = const Color(0x40000000)
      ..strokeWidth = 2.5 * scale;
    canvas.drawLine(Offset(totalRect.left, ropeY + 2 * scale), Offset(totalRect.right, ropeY + 2 * scale), ropeShadow);

    // Twisted hemp cord line
    final ropePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.0 * scale;
    canvas.drawLine(Offset(totalRect.left, ropeY), Offset(totalRect.right, ropeY), ropePaint);

    // 2. Two Wooden Clothespins (Kẹp gỗ)
    final double peg1X = innerRect.left + innerRect.width * 0.28;
    final double peg2X = innerRect.left + innerRect.width * 0.72;

    for (final px in [peg1X, peg2X]) {
      final double pegW = 10.0 * scale;
      final double pegTop = ropeY - 10 * scale;
      final double pegBottom = innerRect.top + 16 * scale;
      final Rect pegRect = Rect.fromLTRB(px - pegW / 2, pegTop, px + pegW / 2, pegBottom);

      // Clothespin Drop Shadow onto Photo
      final pegShadow = Path()..addRRect(RRect.fromRectAndRadius(pegRect.translate(2 * scale, 3 * scale), Radius.circular(2 * scale)));
      canvas.drawShadow(pegShadow, Colors.black.withValues(alpha: 0.5), 4.0 * scale, true);

      // Wooden Peg Body (Natural Birchwood Gradient)
      final woodPaint = Paint()
        ..shader = ui.Gradient.linear(
          pegRect.topLeft,
          pegRect.bottomRight,
          [const Color(0xFFD7CCC8), const Color(0xFFA1887F)],
          [0.0, 1.0],
        );
      canvas.drawRRect(RRect.fromRectAndRadius(pegRect, Radius.circular(2 * scale)), woodPaint);

      // Center Jaw Slit Line
      final slitPaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 0.8 * scale;
      canvas.drawLine(Offset(px, pegTop + 4 * scale), Offset(px, pegBottom - 2 * scale), slitPaint);

      // Metal Torsion Spring Loop (Vòng lò xo kim loại)
      final double springY = ropeY + 2 * scale;
      final springPaint = Paint()..color = const Color(0xFFB0BEC5);
      canvas.drawCircle(Offset(px, springY), 3.8 * scale, springPaint);
      canvas.drawCircle(Offset(px, springY), 2.0 * scale, Paint()..color = const Color(0xFF37474F));
    }

    // 3. Red Laboratory Archival Stamp (Bottom Right)
    final Rect labRect = Rect.fromLTWH(innerRect.right - 88 * scale, innerRect.bottom - 22 * scale, 82 * scale, 16 * scale);
    final labBorder = Paint()
      ..color = const Color(0xAAE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(labRect, Radius.circular(2 * scale)), labBorder);

    final tpLab = TextPainter(
      text: TextSpan(
        text: 'ILFORD BROMIDE • PROOF #01',
        style: TextStyle(
          color: const Color(0xAAE53935),
          fontSize: 5.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLab.paint(canvas, Offset(labRect.center.dx - tpLab.width / 2, labRect.center.dy - tpLab.height / 2));

    // 4. Caption (Laboratory Typewriter Style)
    if (captionText?.isNotEmpty ?? false) {
      final tpCap = TextPainter(
        text: TextSpan(
          text: captionText!,
          style: TextStyle(
            color: const Color(0xFFE0E0E0),
            fontSize: 8.0 * scale,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2 * scale,
            fontFamily: 'monospace',
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: innerRect.width - 100 * scale);
      tpCap.paint(canvas, Offset(innerRect.left + 12 * scale, innerRect.bottom - 18 * scale));
    }
  }

  void _drawAntiqueCartographyDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double borderW, double scale) {
    // 1. Navigation Rhumb Lines (Đường hoa tiêu hàng hải)
    final rhumbPaint = Paint()
      ..color = const Color(0x28B8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    canvas.drawLine(innerRect.topLeft, innerRect.bottomRight, rhumbPaint);
    canvas.drawLine(innerRect.topRight, innerRect.bottomLeft, rhumbPaint);
    canvas.drawLine(Offset(innerRect.center.dx, innerRect.top), Offset(innerRect.center.dx, innerRect.bottom), rhumbPaint);
    canvas.drawLine(Offset(innerRect.left, innerRect.center.dy), Offset(innerRect.right, innerRect.center.dy), rhumbPaint);

    // 2. 8-Point Antique Compass Rose (La bàn hàng hải cổ điển)
    final Offset crCenter = Offset(innerRect.right - 34 * scale, innerRect.bottom - 34 * scale);
    final double crRadius = 24.0 * scale;

    // Concentric rings
    final ringPaint = Paint()
      ..color = const Color(0x884E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawCircle(crCenter, crRadius, ringPaint);
    canvas.drawCircle(crCenter, crRadius * 0.7, ringPaint);

    // Degree ticks
    final tickPaint = Paint()
      ..color = const Color(0x884E342E)
      ..strokeWidth = 0.8 * scale;
    for (int t = 0; t < 16; t++) {
      final double angle = t * (math.pi / 8);
      final p1 = crCenter + Offset(math.cos(angle) * (crRadius - 3 * scale), math.sin(angle) * (crRadius - 3 * scale));
      final p2 = crCenter + Offset(math.cos(angle) * crRadius, math.sin(angle) * crRadius);
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 8 Faceted Compass Points
    final goldHalf = Paint()..color = const Color(0xCCFFD54F);
    final darkHalf = Paint()..color = const Color(0xCC3E2723);

    const List<double> mainAngles = [0, math.pi / 2, math.pi, 3 * math.pi / 2];
    for (final a in mainAngles) {
      final double len = crRadius * 1.05;
      final tip = crCenter + Offset(math.cos(a) * len, math.sin(a) * len);
      final sideL = crCenter + Offset(math.cos(a - math.pi / 8) * (crRadius * 0.35), math.sin(a - math.pi / 8) * (crRadius * 0.35));
      final sideR = crCenter + Offset(math.cos(a + math.pi / 8) * (crRadius * 0.35), math.sin(a + math.pi / 8) * (crRadius * 0.35));

      final p1 = Path()..moveTo(crCenter.dx, crCenter.dy)..lineTo(sideL.dx, sideL.dy)..lineTo(tip.dx, tip.dy)..close();
      final p2 = Path()..moveTo(crCenter.dx, crCenter.dy)..lineTo(sideR.dx, sideR.dy)..lineTo(tip.dx, tip.dy)..close();
      canvas.drawPath(p1, goldHalf);
      canvas.drawPath(p2, darkHalf);
    }

    // Ordinal Points (NE, SE, SW, NW)
    const List<double> ordAngles = [math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4];
    for (final a in ordAngles) {
      final double len = crRadius * 0.75;
      final tip = crCenter + Offset(math.cos(a) * len, math.sin(a) * len);
      final sideL = crCenter + Offset(math.cos(a - math.pi / 8) * (crRadius * 0.25), math.sin(a - math.pi / 8) * (crRadius * 0.25));
      final sideR = crCenter + Offset(math.cos(a + math.pi / 8) * (crRadius * 0.25), math.sin(a + math.pi / 8) * (crRadius * 0.25));

      final p1 = Path()..moveTo(crCenter.dx, crCenter.dy)..lineTo(sideL.dx, sideL.dy)..lineTo(tip.dx, tip.dy)..close();
      final p2 = Path()..moveTo(crCenter.dx, crCenter.dy)..lineTo(sideR.dx, sideR.dy)..lineTo(tip.dx, tip.dy)..close();
      canvas.drawPath(p1, goldHalf);
      canvas.drawPath(p2, darkHalf);
    }

    // North Marker 'N'
    final tpN = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: const Color(0xFFC62828),
          fontSize: 6.5 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpN.paint(canvas, Offset(crCenter.dx - tpN.width / 2, crCenter.dy - crRadius - 9 * scale));

    // 3. Cartouche Banner at Top or Bottom
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'TERRA INCOGNITA • 34°N 118°W';
    final double bannerW = math.min(innerRect.width * 0.65, 200.0 * scale);
    final double bannerH = 22.0 * scale;
    final Rect bRect = Rect.fromCenter(
      center: Offset(innerRect.center.dx, innerRect.bottom - 16 * scale),
      width: bannerW,
      height: bannerH,
    );

    // Parchment ribbon background
    final ribbonPaint = Paint()..color = const Color(0xEEF3E7D3);
    canvas.drawRRect(RRect.fromRectAndRadius(bRect, Radius.circular(3 * scale)), ribbonPaint);
    final ribbonBorder = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(bRect, Radius.circular(3 * scale)), ribbonBorder);

    final tpBanner = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF3E2723),
          fontSize: 8.0 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5 * scale,
          fontFamily: 'serif',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: bannerW - 10 * scale);
    tpBanner.paint(canvas, Offset(bRect.center.dx - tpBanner.width / 2, bRect.center.dy - tpBanner.height / 2));
  }

  void _drawCassetteTapeDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double cassetteExtra, double scale) {
    // 1. 80s Retro Synthwave Accent Stripes across the top of photo
    final double stripeY = innerRect.top + 4 * scale;
    final double stripeH = 3.2 * scale;
    final double stripeW = innerRect.width;

    canvas.drawRect(Rect.fromLTWH(innerRect.left, stripeY, stripeW, stripeH), Paint()..color = const Color(0xFFE53935));
    canvas.drawRect(Rect.fromLTWH(innerRect.left, stripeY + stripeH, stripeW, stripeH), Paint()..color = const Color(0xFFFB8C00));
    canvas.drawRect(Rect.fromLTWH(innerRect.left, stripeY + stripeH * 2, stripeW, stripeH), Paint()..color = const Color(0xFFFDD835));

    // "SIDE A" Retro Badge
    final Rect badgeRect = Rect.fromLTWH(innerRect.left + 8 * scale, stripeY + stripeH * 3 + 4 * scale, 34 * scale, 14 * scale);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, Radius.circular(2 * scale)), Paint()..color = const Color(0xFF212124));
    final tpSide = TextPainter(
      text: TextSpan(
        text: 'SIDE A',
        style: TextStyle(
          color: Colors.white,
          fontSize: 6.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSide.paint(canvas, Offset(badgeRect.center.dx - tpSide.width / 2, badgeRect.center.dy - tpSide.height / 2));

    // Top Handwritten Mixtape Title
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'AWESOME MIX VOL. 1';
    final tpTitle = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFF1E1E24),
          fontSize: 9.0 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2 * scale,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: innerRect.width - 60 * scale);
    tpTitle.paint(canvas, Offset(badgeRect.right + 10 * scale, badgeRect.center.dy - tpTitle.height / 2));

    // 2. Bottom Tape Spool Window (Guồng quay băng Cassette)
    final double winH = cassetteExtra * 0.78;
    final double winW = math.min(innerRect.width * 0.76, 220.0 * scale);
    final double winY = innerRect.bottom + (cassetteExtra - winH) * 0.5 + 4 * scale;
    final Rect winRect = Rect.fromCenter(
      center: Offset(innerRect.center.dx, winY + winH / 2),
      width: winW,
      height: winH,
    );

    // Smoked Clear Acrylic Window
    canvas.drawRRect(RRect.fromRectAndRadius(winRect, Radius.circular(4 * scale)), Paint()..color = const Color(0xFF141416));
    final winBorder = Paint()
      ..color = const Color(0xFF42424E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(winRect, Radius.circular(4 * scale)), winBorder);

    // Dual Tape Reels (2 Guồng bánh răng xoay)
    final double reelR = winH * 0.36;
    final Offset leftReel = Offset(winRect.left + winW * 0.28, winRect.center.dy);
    final Offset rightReel = Offset(winRect.right - winW * 0.28, winRect.center.dy);

    // Left Spool with wound magnetic tape pack
    canvas.drawCircle(leftReel, reelR * 1.15, Paint()..color = const Color(0xFF3E2723));
    // Right Spool with smaller tape pack
    canvas.drawCircle(rightReel, reelR * 0.85, Paint()..color = const Color(0xFF3E2723));

    // Reel plastic bodies (White 6-point drive gear teeth)
    final reelWhite = Paint()..color = const Color(0xFFE0E0E0);
    final gearTeeth = Paint()..color = const Color(0xFF1E1E22);

    for (final c in [leftReel, rightReel]) {
      canvas.drawCircle(c, reelR * 0.65, reelWhite);
      canvas.drawCircle(c, reelR * 0.32, gearTeeth);
      // 6 Gear teeth nubs
      for (int g = 0; g < 6; g++) {
        final double ga = g * (math.pi / 3);
        final gp = c + Offset(math.cos(ga) * (reelR * 0.48), math.sin(ga) * (reelR * 0.48));
        canvas.drawCircle(gp, 1.2 * scale, gearTeeth);
      }
    }

    // Horizontal Magnetic Tape Path connecting spools
    final tapeLine = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 2.5 * scale;
    canvas.drawLine(Offset(leftReel.dx, winRect.bottom - 4 * scale), Offset(rightReel.dx, winRect.bottom - 4 * scale), tapeLine);

    // Center Tape Counter Scale [ 100 • 50 • 0 ]
    final tpScale = TextPainter(
      text: TextSpan(
        text: '100 • 50 • 0',
        style: TextStyle(
          color: const Color(0xFFB0BEC5),
          fontSize: 5.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpScale.paint(canvas, Offset(winRect.center.dx - tpScale.width / 2, winRect.center.dy - tpScale.height / 2));
  }

  void _drawRetroViewmasterDecorations(Canvas canvas, Rect totalRect, Rect innerRect, double borderW, double scale) {
    // 1. Stereoscopic View Aperture Mask (Khung nhìn 3D View-Master bo tròn)
    final RRect apertureRRect = RRect.fromRectAndRadius(innerRect.inflate(2 * scale), Radius.circular(10 * scale));
    final maskShadow = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRRect(apertureRRect, maskShadow);

    // 2. View-Master Disc Reel Index Notches (Khía đĩa tròn hoài niệm xung quanh viền)
    final notchPaint = Paint()..color = const Color(0xFF7F0000);
    const double notchSize = 6.0;
    // Top & Bottom Notch Bites
    canvas.drawRect(Rect.fromLTWH(innerRect.center.dx - notchSize * scale / 2, totalRect.top + borderW * 0.2, notchSize * scale, 5 * scale), notchPaint);
    canvas.drawRect(Rect.fromLTWH(innerRect.center.dx - notchSize * scale / 2, totalRect.bottom - borderW * 0.2 - 5 * scale, notchSize * scale, 5 * scale), notchPaint);

    // 3. Top View-Master Branding Badge
    final tpBrand = TextPainter(
      text: TextSpan(
        text: 'VIEW-MASTER® 3D STEREO REEL',
        style: TextStyle(
          color: const Color(0xFFFFF9C4),
          fontSize: 6.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpBrand.paint(canvas, Offset(totalRect.center.dx - tpBrand.width / 2, totalRect.top + borderW * 0.35));

    // 4. Bottom Reel Label & Caption
    final String caption = (captionText?.isNotEmpty ?? false) ? captionText! : 'SCENIC WONDERS • REEL NO. 1';
    final double hubW = math.min(innerRect.width * 0.70, 210.0 * scale);
    final double hubH = 20.0 * scale;
    final Rect hubRect = Rect.fromCenter(
      center: Offset(totalRect.center.dx, totalRect.bottom - borderW * 0.5),
      width: hubW,
      height: hubH,
    );

    // White Reel Paper Hub
    canvas.drawRRect(RRect.fromRectAndRadius(hubRect, Radius.circular(10 * scale)), Paint()..color = const Color(0xFFFAF6EE));
    final hubBorder = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(hubRect, Radius.circular(10 * scale)), hubBorder);

    final tpCaption = TextPainter(
      text: TextSpan(
        text: caption,
        style: TextStyle(
          color: const Color(0xFFB71C1C),
          fontSize: 7.5 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2 * scale,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: hubW - 12 * scale);
    tpCaption.paint(canvas, Offset(hubRect.center.dx - tpCaption.width / 2, hubRect.center.dy - tpCaption.height / 2));
  }

  // -------------------------------------------------------------
  // Photo Transform Rendering
  // -------------------------------------------------------------
  void _drawTransformedPhoto(Canvas canvas, Rect slotRect, ui.Image img, SlotTransform transform) {
    canvas.save();

    final double cx = slotRect.center.dx;
    final double cy = slotRect.center.dy;
    canvas.translate(cx, cy);

    if (transform.rotation != 0) {
      canvas.rotate(transform.rotation * math.pi / 180.0);
    }
    if (transform.flipH || transform.flipV) {
      canvas.scale(transform.flipH ? -1.0 : 1.0, transform.flipV ? -1.0 : 1.0);
    }

    final double imgW = img.width.toDouble();
    final double imgH = img.height.toDouble();
    final double scaleCover = math.max(slotRect.width / imgW, slotRect.height / imgH);

    final double drawnW = imgW * scaleCover * transform.zoom;
    final double drawnH = imgH * scaleCover * transform.zoom;

    final double maxPanX = math.max(0.0, (drawnW - slotRect.width) / 2.0);
    final double maxPanY = math.max(0.0, (drawnH - slotRect.height) / 2.0);
    final double px = transform.panX * maxPanX;
    final double py = transform.panY * maxPanY;

    final Rect destRect = Rect.fromCenter(
      center: Offset(px, py),
      width: drawnW,
      height: drawnH,
    );

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..colorFilter = filterPreset.colorFilter;

    final Rect srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
    canvas.drawImageRect(img, srcRect, destRect, paint);

    canvas.restore();
  }

  void _drawEmptySlot(Canvas canvas, Rect slotRect, int index, double scale) {
    final bg = Paint()..color = const Color(0xFF18181B);
    canvas.drawRect(slotRect, bg);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Ô #${index + 1}\nChạm để nạp ảnh',
        style: TextStyle(
          color: const Color(0xFF71717A),
          fontSize: 12 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: slotRect.width);

    textPainter.paint(
      canvas,
      Offset(
        slotRect.center.dx - textPainter.width / 2,
        slotRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawSelectionOverlay(Canvas canvas, Rect slotRect, int slotIndex, double scale) {
    const Color indigo = Color(0xFF6366F1);
    const Color glow = Color(0xFF818CF8);

    final glowPaint = Paint()
      ..color = glow.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale;
    canvas.drawRect(slotRect.inflate(1.0 * scale), glowPaint);

    final mainPaint = Paint()
      ..color = indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale;
    canvas.drawRect(slotRect, mainPaint);

    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * scale;
    final double bLen = math.min(18.0 * scale, slotRect.width * 0.2);

    canvas.drawLine(slotRect.topLeft, slotRect.topLeft.translate(bLen, 0), bracketPaint);
    canvas.drawLine(slotRect.topLeft, slotRect.topLeft.translate(0, bLen), bracketPaint);
    canvas.drawLine(slotRect.topRight, slotRect.topRight.translate(-bLen, 0), bracketPaint);
    canvas.drawLine(slotRect.topRight, slotRect.topRight.translate(0, bLen), bracketPaint);
    canvas.drawLine(slotRect.bottomLeft, slotRect.bottomLeft.translate(bLen, 0), bracketPaint);
    canvas.drawLine(slotRect.bottomLeft, slotRect.bottomLeft.translate(0, -bLen), bracketPaint);
    canvas.drawLine(slotRect.bottomRight, slotRect.bottomRight.translate(-bLen, 0), bracketPaint);
    canvas.drawLine(slotRect.bottomRight, slotRect.bottomRight.translate(0, -bLen), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant FramePainter oldDelegate) {
    return true; // Dynamic continuous interactive transforms
  }
}
