import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'models/template_model.dart';
import 'models/layout_model.dart';
import 'models/transform_model.dart';
import 'models/filter_model.dart';
import 'widgets/interactive_canvas.dart';
import 'services/export_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF09090B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PhotoFrameFancyApp());
}

class PhotoFrameFancyApp extends StatelessWidget {
  const PhotoFrameFancyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoFrameFancy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFD4AF37),
          surface: Color(0xFF18181B),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainStudioScreen(),
    );
  }
}

class MainStudioScreen extends StatefulWidget {
  const MainStudioScreen({super.key});

  @override
  State<MainStudioScreen> createState() => _MainStudioScreenState();
}

class _MainStudioScreenState extends State<MainStudioScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<State<InteractiveCanvas>> _canvasKey = GlobalKey();

  // State
  List<ui.Image> _images = [];
  int _activePhotoCount = 2;
  CollageLayout _selectedLayout = LayoutsCatalog.all[6]; // 2 photos vertical split
  FrameTemplate _selectedTemplate = TemplatesCatalog.all[0]; // Gold Baroque
  FilterPreset _selectedFilter = FilterEngine.presets[0]; // Original
  final Map<int, SlotTransform> _slotTransforms = {};

  double _borderRatio = 0.08;
  double _matRatio = 0.06;
  Color _frameColor = const Color(0xFFD4AF37);
  Color _matColor = const Color(0xFF18181B);
  bool _hasShadow = true;
  String _captionText = '';

  int _layoutSubTab = 0; // 0: Chọn Mẫu Bố Cục (38 mẫu), 1: Tinh Chỉnh Khe & Bo Góc
  double _gapSize = 8.0; // Khoảng cách khe lưới (0 - 24px)
  double _cellCornerRadius = 0.0; // Bo tròn góc từng ô ảnh (0 - 24px)
  Color _gridBgColor = const Color(0xFFFFFFFF);

  int _selectedTab = 1; // 0: Ảnh, 1: Lưới, 2: Khung, 3: Hiệu Ứng
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _applyTemplateDefaults(_selectedTemplate);
    _loadInitialDemoPhotos();
  }

  void _applyTemplateDefaults(FrameTemplate tmpl) {
    _borderRatio = tmpl.defaultBorderRatio;
    _matRatio = tmpl.defaultMatRatio;
    _frameColor = tmpl.defaultFrameColor;
    _matColor = tmpl.defaultMatColor;
    _hasShadow = tmpl.hasShadow;
    _captionText = tmpl.defaultCaption ?? '';
    _gridBgColor = tmpl.defaultMatColor;
  }

  Future<void> _loadInitialDemoPhotos() async {
    const demoPaths = [
      'assets/demo/portrait.jpg',
      'assets/demo/landscape.jpg',
      'assets/demo/coffee.jpg',
      'assets/demo/flowers.jpg',
      'assets/demo/architecture.jpg',
      'assets/demo/beach.jpg',
    ];

    List<ui.Image> loaded = [];
    for (final path in demoPaths) {
      try {
        final ByteData data = await rootBundle.load(path);
        final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final ui.FrameInfo fi = await codec.getNextFrame();
        loaded.add(fi.image);
      } catch (e) {
        debugPrint('Could not load demo asset: $path, $e');
      }
    }

    if (mounted && loaded.isNotEmpty) {
      setState(() {
        _images = loaded;
      });
    }
  }

  Future<void> _pickPhotosFromGallery() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      List<ui.Image> newImages = [];
      for (final xf in pickedFiles) {
        try {
          final Uint8List bytes = await xf.readAsBytes();
          final ui.Codec codec = await ui.instantiateImageCodec(bytes);
          final ui.FrameInfo fi = await codec.getNextFrame();
          newImages.add(fi.image);
        } catch (e) {
          debugPrint('Error decoding picked image: $e');
        }
      }

      if (mounted && newImages.isNotEmpty) {
        setState(() {
          _images = newImages;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nạp ${newImages.length} bức ảnh từ thiết bị!'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _resetTransforms() {
    setState(() {
      _slotTransforms.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đặt lại toàn bộ vị trí & Zoom ảnh về mặc định!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _swapSlots(int slotA, int slotB) {
    if (slotA == slotB) return;
    setState(() {
      // Ensure images list has enough items so indices are valid
      while (_images.length <= math.max(slotA, slotB) && _images.isNotEmpty) {
        _images.add(_images[_images.length % _images.length]);
      }
      if (slotA < _images.length && slotB < _images.length) {
        final temp = _images[slotA];
        _images[slotA] = _images[slotB];
        _images[slotB] = temp;
      }
      // Also swap slot pan/zoom/rotation transforms if any
      final transA = _slotTransforms[slotA];
      final transB = _slotTransforms[slotB];
      if (transA != null || transB != null) {
        _slotTransforms[slotA] = transB ?? SlotTransform();
        _slotTransforms[slotB] = transA ?? SlotTransform();
      }
    });
  }

  Future<void> _exportAndSave() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hoặc nạp ít nhất 1 ảnh!')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final String savedPath = await ExportService.renderAndSaveArtwork(
        images: _images,
        template: _selectedTemplate,
        layout: _selectedLayout,
        slotTransforms: _slotTransforms,
        filterPreset: _selectedFilter,
        borderRatio: _borderRatio,
        matRatio: _matRatio,
        frameColor: _frameColor,
        matColor: _matColor,
        hasShadow: _hasShadow,
        captionText: _captionText.isEmpty ? null : _captionText,
        gapSize: _gapSize,
        cellCornerRadius: _cellCornerRadius,
        gridBgColor: _gridBgColor,
        exportResolution: 2400,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF18181B),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Đã Lưu Thành Công!', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: const Text(
              'Tác phẩm ảnh lồng khung chất lượng cao (2400x2400) đã được lưu vào Album ảnh của máy.',
              style: TextStyle(color: Color(0xFFA1A1AA)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ExportService.shareArtwork(savedPath);
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Chia Sẻ'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xuất ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        title: const Row(
          children: [
            Text('🖼️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'PhotoFrameFancy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFA1A1AA)),
            tooltip: 'Đặt lại',
            onPressed: _resetTransforms,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportAndSave,
              icon: _isExporting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt, size: 16, color: Colors.white),
              label: Text(_isExporting ? 'Đang lưu...' : 'Lưu Ảnh', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Center Stage: Interactive Canvas
            Expanded(
              child: Container(
                color: const Color(0xFF0F0F12),
                padding: const EdgeInsets.all(12),
                child: InteractiveCanvas(
                  key: _canvasKey,
                  images: _images,
                  template: _selectedTemplate,
                  layout: _selectedLayout,
                  slotTransforms: _slotTransforms,
                  filterPreset: _selectedFilter,
                  borderRatio: _borderRatio,
                  matRatio: _matRatio,
                  frameColor: _frameColor,
                  matColor: _matColor,
                  hasShadow: _hasShadow,
                  captionText: _captionText.isEmpty ? null : _captionText,
                  gapSize: _gapSize,
                  cellCornerRadius: _cellCornerRadius,
                  gridBgColor: _gridBgColor,
                  onSwapSlots: _swapSlots,
                ),
              ),
            ),

            // Bottom Navigation & Panel
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 4 Category Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryTab(0, Icons.photo_library_outlined, 'Ảnh'),
                _buildCategoryTab(1, Icons.grid_view_rounded, 'Lưới Ghép'),
                _buildCategoryTab(2, Icons.crop_original, 'Mẫu Khung'),
                _buildCategoryTab(3, Icons.tune_rounded, 'Màu & Viền'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF27272A)),

          // Dynamic Tab Content (Fixed Height Carousel)
          SizedBox(
            height: 140,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildCurrentTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(int index, IconData icon, String label) {
    final bool isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF312E81) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFFC7D2FE) : const Color(0xFFA1A1AA)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPhotosTab();
      case 1:
        return _buildLayoutsTab();
      case 2:
        return _buildTemplatesTab();
      case 3:
        return _buildAdjustmentsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // TAB 0: Photos
  Widget _buildPhotosTab() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Add from Gallery button
        InkWell(
          onTap: _pickPhotosFromGallery,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 85,
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, color: Color(0xFF818CF8), size: 28),
                SizedBox(height: 6),
                Text('Thêm Ảnh', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Clear All Photos Button (khi danh sách có ảnh)
        if (_images.isNotEmpty)
          InkWell(
            onTap: () {
              setState(() {
                _images.clear();
                _slotTransforms.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa hết ảnh. Hãy bấm "Thêm Ảnh" để nạp ảnh mới từ máy!'),
                  backgroundColor: Color(0xFFDC2626),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 75,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_rounded, color: Color(0xFFF87171), size: 24),
                  SizedBox(height: 4),
                  Text('Xóa Hết', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

        // Thumbnails of loaded photos with individual Delete button
        ...List.generate(_images.length, (i) {
          return Container(
            width: 85,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3F3F46)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RawImage(image: _images[i], fit: BoxFit.cover),
                // Number badge
                Positioned(
                  bottom: 2,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                    child: Text('#${i + 1}', style: const TextStyle(fontSize: 9, color: Colors.white)),
                  ),
                ),
                // Delete button on top right of each thumbnail
                Positioned(
                  top: 3,
                  right: 3,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _images.removeAt(i);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã xóa ảnh #${i + 1}. Bạn có thể bấm "Thêm Ảnh" để nạp ảnh mới.'),
                          backgroundColor: const Color(0xFFDC2626),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xD9DC2626),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black45, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // TAB 1: Collage Layouts (38 PC Parity Curated Layouts + Gap & Corner Radius)
  Widget _buildLayoutsTab() {
    return Column(
      children: [
        // Mode & Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Photo Count Filter Chips (1 to 6)
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (ctx, i) {
                      final count = i + 1;
                      final isSel = _activePhotoCount == count;
                      final countTotal = LayoutsCatalog.forCount(count).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            '$count Ảnh ($countTotal)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : Colors.white70,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: const Color(0xFF4F46E5),
                          backgroundColor: const Color(0xFF27272A),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _activePhotoCount = count;
                                final layouts = LayoutsCatalog.forCount(count);
                                if (layouts.isNotEmpty) {
                                  _selectedLayout = layouts.first;
                                }
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Sub-tab switcher: [📐 Bố Cục] vs [⚙️ Khe & Bo Góc]
              InkWell(
                onTap: () {
                  setState(() {
                    _layoutSubTab = _layoutSubTab == 0 ? 1 : 0;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _layoutSubTab == 1 ? const Color(0xFF059669) : const Color(0xFF3F3F46),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _layoutSubTab == 1 ? const Color(0xFF34D399) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _layoutSubTab == 1 ? Icons.grid_on : Icons.tune,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _layoutSubTab == 1 ? 'Mẫu Bố Cục' : 'Khe & Bo Góc',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // SubTab Content: Mode 0 = Layout Cards Carousel, Mode 1 = Gap / Corner Radius / Grid Color Tuning
        Expanded(
          child: _layoutSubTab == 0
              ? _buildLayoutCardsCarousel()
              : _buildGridTuningControls(),
        ),
      ],
    );
  }

  Widget _buildLayoutCardsCarousel() {
    final currentLayouts = LayoutsCatalog.forCount(_activePhotoCount);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: currentLayouts.length,
      itemBuilder: (ctx, idx) {
        final l = currentLayouts[idx];
        final isSel = _selectedLayout.id == l.id;

        return InkWell(
          onTap: () => setState(() => _selectedLayout = l),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 145,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFF312E81) : const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? const Color(0xFF818CF8) : const Color(0xFF3F3F46),
                width: isSel ? 2.0 : 1.0,
              ),
              boxShadow: isSel
                  ? [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 8)]
                  : null,
            ),
            child: Row(
              children: [
                // Visual diagram icon box
                Container(
                  width: 44,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? const Color(0xFF818CF8) : const Color(0xFF3F3F46),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.iconSymbol,
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF3F3F46),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          l.aspectPreset,
                          style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Name & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          color: isSel ? Colors.white : const Color(0xFFE4E4E7),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF9CA3AF),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridTuningControls() {
    final colorOptions = [
      {'name': 'Trắng', 'color': const Color(0xFFFFFFFF)},
      {'name': 'Đen', 'color': const Color(0xFF18181B)},
      {'name': 'Kem Be', 'color': const Color(0xFFF5F2EB)},
      {'name': 'Cát Ấm', 'color': const Color(0xFFE7DEC8)},
      {'name': 'Gỗ Nâu', 'color': const Color(0xFF3E2723)},
      {'name': 'Xám Đậm', 'color': const Color(0xFF334155)},
    ];

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      children: [
        // 1. Grid Gap Stepper & Presets
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3F3F46)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.line_weight, size: 13, color: Color(0xFF818CF8)),
                  const SizedBox(width: 4),
                  Text('Khe Lưới: ${_gapSize.toInt()}px',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _gapSize = (_gapSize - 2).clamp(0.0, 24.0)),
                    child: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.white70),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _gapSize = (_gapSize + 2).clamp(0.0, 24.0)),
                    child: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [0.0, 4.0, 8.0, 14.0, 20.0].map((g) {
                  final isSel = _gapSize == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => setState(() => _gapSize = g),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF4F46E5) : const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${g.toInt()}p',
                            style: TextStyle(fontSize: 9, color: isSel ? Colors.white : Colors.white70)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // 2. Cell Corner Radius Stepper & Presets
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3F3F46)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.rounded_corner, size: 13, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text('Bo Góc Ô: ${_cellCornerRadius.toInt()}px',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _cellCornerRadius = (_cellCornerRadius - 2).clamp(0.0, 24.0)),
                    child: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.white70),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => setState(() => _cellCornerRadius = (_cellCornerRadius + 2).clamp(0.0, 24.0)),
                    child: const Icon(Icons.add_circle_outline, size: 16, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [0.0, 6.0, 10.0, 16.0, 22.0].map((r) {
                  final isSel = _cellCornerRadius == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      onTap: () => setState(() => _cellCornerRadius = r),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF059669) : const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${r.toInt()}p',
                            style: TextStyle(fontSize: 9, color: isSel ? Colors.white : Colors.white70)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // 3. Grid Gap Color Palette
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3F3F46)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_outlined, size: 13, color: Color(0xFFF59E0B)),
                  SizedBox(width: 4),
                  Text('Màu Rãnh Lưới',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: colorOptions.map((opt) {
                  final color = opt['color'] as Color;
                  final isSel = _gridBgColor == color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _gridBgColor = color),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? const Color(0xFF6366F1) : Colors.white54,
                            width: isSel ? 2.5 : 1.0,
                          ),
                          boxShadow: isSel
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)]
                              : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _selectedTemplateCategory = 'Tất Cả';

  // TAB 2: Frame Templates
  Widget _buildTemplatesTab() {
    final categories = ['Tất Cả', 'Cổ Điển', 'Gỗ Tự Nhiên', 'Nghệ Thuật', 'Vintage', 'Hiện Đại', 'Tối Giản'];
    final filtered = _selectedTemplateCategory == 'Tất Cả'
        ? TemplatesCatalog.all
        : TemplatesCatalog.all.where((t) => t.category == _selectedTemplateCategory).toList();

    return Column(
      children: [
        // Category Pills
        SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final isSel = _selectedTemplateCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  label: Text(cat, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : Colors.white70)),
                  selected: isSel,
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: const Color(0xFF27272A),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onSelected: (s) {
                    if (s) setState(() => _selectedTemplateCategory = cat);
                  },
                ),
              );
            },
          ),
        ),

        // Template Cards
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final tmpl = filtered[i];
              final isSel = _selectedTemplate.id == tmpl.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTemplate = tmpl;
                    _applyTemplateDefaults(tmpl);
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF312E81) : const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel ? const Color(0xFF818CF8) : const Color(0xFF3F3F46),
                      width: isSel ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: tmpl.defaultFrameColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white60, width: 1.2),
                          boxShadow: [
                            BoxShadow(color: tmpl.defaultFrameColor.withValues(alpha: 0.4), blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tmpl.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : const Color(0xFFD4D4D8),
                        ),
                      ),
                      Text(
                        tmpl.category,
                        style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // TAB 3: Adjustments & Filters
  Widget _buildAdjustmentsTab() {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. Color Filter presets
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bộ Lọc Màu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFA1A1AA))),
            const SizedBox(height: 4),
            Row(
              children: FilterEngine.presets.map((f) {
                final isSel = _selectedFilter.id == f.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f.name, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : Colors.white70)),
                    selected: isSel,
                    selectedColor: const Color(0xFFD97706),
                    backgroundColor: const Color(0xFF27272A),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    onSelected: (s) {
                      if (s) setState(() => _selectedFilter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const VerticalDivider(width: 24, color: Color(0xFF27272A)),

        // 2. Border Width Stepper
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Viền: ${(_borderRatio * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: () => setState(() => _borderRatio = (_borderRatio - 0.01).clamp(0.01, 0.15)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: () => setState(() => _borderRatio = (_borderRatio + 0.01).clamp(0.01, 0.15)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 3. Matting Margin Stepper
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Đệm Mat: ${(_matRatio * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: () => setState(() => _matRatio = (_matRatio - 0.01).clamp(0.0, 0.20)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: () => setState(() => _matRatio = (_matRatio + 0.01).clamp(0.0, 0.20)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 3b. Grid Gap Stepper
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Khe Lưới: ${_gapSize.toInt()}px', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: () => setState(() => _gapSize = (_gapSize - 2).clamp(0.0, 24.0)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: () => setState(() => _gapSize = (_gapSize + 2).clamp(0.0, 24.0)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 3c. Cell Corner Radius Stepper
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Bo Góc: ${_cellCornerRadius.toInt()}px', style: const TextStyle(fontSize: 10, color: Colors.white70)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: () => setState(() => _cellCornerRadius = (_cellCornerRadius - 2).clamp(0.0, 24.0)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    onPressed: () => setState(() => _cellCornerRadius = (_cellCornerRadius + 2).clamp(0.0, 24.0)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 4. Drop Shadow Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(10)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Bóng Đổ', style: TextStyle(fontSize: 10, color: Colors.white70)),
              Switch(
                value: _hasShadow,
                activeThumbColor: const Color(0xFF6366F1),
                activeTrackColor: const Color(0xFF312E81),
                onChanged: (val) => setState(() => _hasShadow = val),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // 5. Edit Caption Dialog Button
        InkWell(
          onTap: () {
            final ctrl = TextEditingController(text: _captionText);
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF18181B),
                title: const Text('Nhập Chữ Ký / Tiêu Đề', style: TextStyle(color: Colors.white, fontSize: 16)),
                content: TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Kỷ Niệm 2026, VOGUE, Fine Art...',
                    hintStyle: TextStyle(color: Colors.white38),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _captionText = ctrl.text);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                    child: const Text('Áp Dụng'),
                  ),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF818CF8), width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_note, size: 20, color: Color(0xFFC7D2FE)),
                const SizedBox(height: 4),
                Text(
                  _captionText.isEmpty ? 'Thêm Chữ Ký' : 'Chữ: $_captionText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
