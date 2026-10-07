import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_frame_mobile/models/layout_model.dart';
import 'package:photo_frame_mobile/models/template_model.dart';
import 'package:photo_frame_mobile/models/filter_model.dart';
import 'package:photo_frame_mobile/widgets/frame_painter.dart';

void main() {
  group('Collage Layouts Parity Tests', () {
    test('LayoutsCatalog contains all 37 curated layouts across 1 to 6 photos', () {
      expect(LayoutsCatalog.all.length, greaterThanOrEqualTo(37));

      for (int count = 1; count <= 6; count++) {
        final layouts = LayoutsCatalog.forCount(count);
        expect(layouts.isNotEmpty, isTrue, reason: 'Layouts for $count photos should not be empty');
        expect(layouts.length, greaterThanOrEqualTo(6), reason: 'Each photo count has at least 6 curated presets');

        for (final layout in layouts) {
          expect(layout.slots.length, equals(count));
          expect(layout.iconSymbol.isNotEmpty, isTrue);
          expect(layout.aspectPreset.isNotEmpty, isTrue);

          for (final slot in layout.slots) {
            expect(slot.x, greaterThanOrEqualTo(0.0));
            expect(slot.y, greaterThanOrEqualTo(0.0));
            expect(slot.w, greaterThan(0.0));
            expect(slot.h, greaterThan(0.0));
            expect(slot.x + slot.w, lessThanOrEqualTo(1.001));
            expect(slot.y + slot.h, lessThanOrEqualTo(1.001));
          }
        }
      }
    });

    test('FramePainter renders slots with custom gap, corner radius, and gridBgColor cleanly', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final template = TemplatesCatalog.all.first;
      final layout = LayoutsCatalog.findById('grid_4_quad_2x2');

      final painter = FramePainter(
        images: [],
        template: template,
        layout: layout,
        slotTransforms: const {},
        filterPreset: FilterEngine.presets.first,
        borderRatio: 0.08,
        matRatio: 0.06,
        frameColor: const Color(0xFFD4AF37),
        matColor: const Color(0xFF18181B),
        hasShadow: true,
        gapSize: 12.0,
        cellCornerRadius: 8.0,
        gridBgColor: const Color(0xFFFFFFFF),
      );

      // Should execute without throwing any exceptions
      expect(() => painter.paint(canvas, const Size(800, 800)), returnsNormally);
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('FramePainter renders all templates at mobile screen size (360x360) without errors', () {
      for (final tmpl in TemplatesCatalog.all) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final layout = LayoutsCatalog.all.first;

        final painter = FramePainter(
          images: [],
          template: tmpl,
          layout: layout,
          slotTransforms: const {},
          filterPreset: FilterEngine.presets.first,
          borderRatio: tmpl.defaultBorderRatio,
          matRatio: tmpl.defaultMatRatio,
          frameColor: tmpl.defaultFrameColor,
          matColor: tmpl.defaultMatColor,
          hasShadow: tmpl.hasShadow,
          captionText: tmpl.defaultCaption,
          gapSize: 8.0,
          cellCornerRadius: 0.0,
          gridBgColor: tmpl.defaultMatColor,
        );

        expect(
          () => painter.paint(canvas, const Size(360, 360)),
          returnsNormally,
          reason: 'Template ${tmpl.id} (${tmpl.name}) should paint cleanly at 360x360',
        );
        final pic = recorder.endRecording();
        expect(pic, isNotNull);
      }
    });
  });
}
