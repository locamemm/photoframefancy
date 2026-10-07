import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../models/layout_model.dart';
import '../models/transform_model.dart';
import '../models/filter_model.dart';
import 'frame_painter.dart';

class InteractiveCanvas extends StatefulWidget {
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
  final double gapSize;
  final double cellCornerRadius;
  final Color? gridBgColor;
  final Function(int slotIndex)? onSlotSelected;
  final VoidCallback? onTransformChanged;
  final Function(int slotA, int slotB)? onSwapSlots;

  const InteractiveCanvas({
    super.key,
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
    this.gapSize = 8.0,
    this.cellCornerRadius = 0.0,
    this.gridBgColor,
    this.onSlotSelected,
    this.onTransformChanged,
    this.onSwapSlots,
  });

  @override
  State<InteractiveCanvas> createState() => _InteractiveCanvasState();
}

class _InteractiveCanvasState extends State<InteractiveCanvas> {
  int? activeEditingSlot;
  double _baseZoom = 1.0;

  void exitEditing() {
    if (activeEditingSlot != null) {
      setState(() {
        activeEditingSlot = null;
      });
    }
  }

  void _onDoubleTapDown(TapDownDetails details, BoxConstraints constraints) {
    final double canvasSize = constraints.maxWidth;
    final Offset pos = details.localPosition;

    final double minDim = canvasSize;
    final double pad = widget.hasShadow ? minDim * 0.05 : 0.0;
    final Rect totalRect = Rect.fromLTWH(pad, pad, canvasSize - pad * 2, canvasSize - pad * 2);

    final double borderW = (minDim * widget.borderRatio).clamp(2.0, minDim * 0.45);
    final double matW = (minDim * widget.matRatio).clamp(0.0, minDim * 0.45);
    final double polaroidExtra = (widget.template.id == 'polaroid_classic') ? minDim * 0.16 : 0.0;
    final double museumExtra = (widget.template.id == 'museum_gallery' && (widget.captionText?.isNotEmpty ?? false))
        ? minDim * 0.08
        : 0.0;
    final double newspaperExtra = (widget.template.id == 'vintage_newspaper') ? minDim * 0.08 : 0.0;
    final double ticketExtra = (widget.template.id == 'vintage_boarding_ticket') ? minDim * 0.10 : 0.0;
    final double clotheslineExtra = (widget.template.id == 'darkroom_clothesline') ? minDim * 0.08 : 0.0;
    final double cassetteExtra = (widget.template.id == 'cassette_tape_80s') ? minDim * 0.09 : 0.0;

    final double topB = (widget.template.id == 'film_35mm')
        ? borderW * 1.5
        : (widget.template.id == 'darkroom_clothesline' ? borderW + clotheslineExtra : borderW);
    final double botB = (widget.template.id == 'film_35mm')
        ? borderW * 1.5
        : (widget.template.id == 'polaroid_classic'
            ? borderW + polaroidExtra
            : (widget.template.id == 'vintage_boarding_ticket'
                ? borderW + ticketExtra
                : (widget.template.id == 'cassette_tape_80s'
                    ? borderW + cassetteExtra
                    : borderW)));

    final Rect matRect = Rect.fromLTRB(
      totalRect.left + borderW,
      totalRect.top + topB,
      totalRect.right - borderW,
      totalRect.bottom - botB,
    );

    final Rect innerRect = (widget.template.id == 'modern_floating')
        ? matRect
        : Rect.fromLTRB(
            matRect.left + matW,
            matRect.top + matW + newspaperExtra,
            matRect.right - matW,
            matRect.bottom - matW - museumExtra,
          );

    if (innerRect.contains(pos)) {
      final double nx = (pos.dx - innerRect.left) / innerRect.width;
      final double ny = (pos.dy - innerRect.top) / innerRect.height;

      for (int i = 0; i < widget.layout.slots.length; i++) {
        final slot = widget.layout.slots[i];
        if (nx >= slot.x && nx <= (slot.x + slot.w) && ny >= slot.y && ny <= (slot.y + slot.h)) {
          setState(() {
            activeEditingSlot = i;
          });
          widget.onSlotSelected?.call(i);
          return;
        }
      }
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (activeEditingSlot != null) {
      final transform = widget.slotTransforms[activeEditingSlot!] ?? SlotTransform();
      _baseZoom = transform.zoom;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, BoxConstraints constraints) {
    if (activeEditingSlot == null) return;

    final transform = widget.slotTransforms.putIfAbsent(activeEditingSlot!, () => SlotTransform());
    setState(() {
      // 1. Pinch to zoom
      if (details.scale != 1.0) {
        transform.zoom = (_baseZoom * details.scale).clamp(1.0, 3.0);
      }

      // 2. Pan / Drag (1 finger)
      final double slotDim = constraints.maxWidth * 0.4;
      final double dx = details.focalPointDelta.dx / slotDim;
      final double dy = details.focalPointDelta.dy / slotDim;

      transform.panX = (transform.panX + dx * 1.5).clamp(-1.0, 1.0);
      transform.panY = (transform.panY + dy * 1.5).clamp(-1.0, 1.0);
    });

    widget.onTransformChanged?.call();
  }

  void _showSwapSlotDialog(BuildContext context) {
    if (activeEditingSlot == null) return;
    final int current = activeEditingSlot!;
    final int totalSlots = widget.layout.slots.length;

    if (totalSlots <= 1) return;

    if (totalSlots == 2) {
      final int otherSlot = current == 0 ? 1 : 0;
      widget.onSwapSlots?.call(current, otherSlot);
      setState(() {
        activeEditingSlot = otherSlot;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đổi vị trí ảnh giữa Ô #1 và Ô #2!'),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF6366F1),
        ),
      );
      return;
    }

    // Modal picker for > 2 slots
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Color(0xFF818CF8), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Đổi vị trí Ô #${current + 1} với:',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chọn ô ảnh bạn muốn hoán đổi vị trí hiển thị:',
                  style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(totalSlots, (idx) {
                    if (idx == current) return const SizedBox.shrink();
                    return ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onSwapSlots?.call(current, idx);
                        setState(() {
                          activeEditingSlot = idx;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã đổi vị trí ảnh giữa Ô #${current + 1} và Ô #${idx + 1}!'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFF6366F1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.swap_calls, size: 16),
                      label: Text('Ô #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27272A),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double canvasW = constraints.maxWidth;
        final double canvasH = constraints.maxHeight;
        final double side = canvasW < canvasH ? canvasW : canvasH;

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Gesture detector wrapping CustomPaint for 120 FPS gestures
                GestureDetector(
                  onDoubleTapDown: (details) => _onDoubleTapDown(details, constraints),
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: (details) => _onScaleUpdate(details, constraints),
                  onTap: () {
                    // Tap on canvas background exits edit mode
                    if (activeEditingSlot != null) {
                      exitEditing();
                    }
                  },
                  child: CustomPaint(
                    size: Size(side, side),
                    painter: FramePainter(
                      images: widget.images,
                      template: widget.template,
                      layout: widget.layout,
                      slotTransforms: widget.slotTransforms,
                      filterPreset: widget.filterPreset,
                      borderRatio: widget.borderRatio,
                      matRatio: widget.matRatio,
                      frameColor: widget.frameColor,
                      matColor: widget.matColor,
                      hasShadow: widget.hasShadow,
                      captionText: widget.captionText,
                      activeEditingSlot: activeEditingSlot,
                      gapSize: widget.gapSize,
                      cellCornerRadius: widget.cellCornerRadius,
                      gridBgColor: widget.gridBgColor,
                    ),
                  ),
                ),

                // Floating Contextual Toolbar when editing a slot
                if (activeEditingSlot != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xE618181B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Done button
                            ElevatedButton.icon(
                              onPressed: exitEditing,
                              icon: const Icon(Icons.check, size: 15, color: Colors.white),
                              label: const Text('Xong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Swap Slot Button (Đổi vị trí ảnh)
                            if (widget.layout.slots.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: ElevatedButton.icon(
                                  onPressed: () => _showSwapSlotDialog(context),
                                  icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                                  label: Text(
                                    'Đổi Vị Trí (${activeEditingSlot! + 1})',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),

                            // Rotate Left
                            IconButton(
                              icon: const Icon(Icons.rotate_left, color: Colors.white, size: 20),
                              tooltip: 'Xoay trái',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final t = widget.slotTransforms.putIfAbsent(activeEditingSlot!, () => SlotTransform());
                                setState(() {
                                  t.rotation = (t.rotation - 90) % 360;
                                });
                                widget.onTransformChanged?.call();
                              },
                            ),
                            const SizedBox(width: 2),

                            // Rotate Right
                            IconButton(
                              icon: const Icon(Icons.rotate_right, color: Colors.white, size: 20),
                              tooltip: 'Xoay phải',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final t = widget.slotTransforms.putIfAbsent(activeEditingSlot!, () => SlotTransform());
                                setState(() {
                                  t.rotation = (t.rotation + 90) % 360;
                                });
                                widget.onTransformChanged?.call();
                              },
                            ),
                            const SizedBox(width: 2),

                            // Flip Horizontal
                            IconButton(
                              icon: const Icon(Icons.flip, color: Colors.white, size: 20),
                              tooltip: 'Lật ngang',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final t = widget.slotTransforms.putIfAbsent(activeEditingSlot!, () => SlotTransform());
                                setState(() {
                                  t.flipH = !t.flipH;
                                });
                                widget.onTransformChanged?.call();
                              },
                            ),
                            const SizedBox(width: 2),

                            // Reset Slot
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Color(0xFFF87171), size: 20),
                              tooltip: 'Đặt lại',
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                final t = widget.slotTransforms.putIfAbsent(activeEditingSlot!, () => SlotTransform());
                                setState(() {
                                  t.reset();
                                });
                                widget.onTransformChanged?.call();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
