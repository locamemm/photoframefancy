import 'package:flutter/material.dart';

class FilterPreset {
  final String id;
  final String name;
  final ColorFilter? colorFilter;

  const FilterPreset({
    required this.id,
    required this.name,
    this.colorFilter,
  });
}

class FilterEngine {
  static const List<FilterPreset> presets = [
    FilterPreset(
      id: 'original',
      name: 'Gốc (Original)',
      colorFilter: null,
    ),
    FilterPreset(
      id: 'warm_film',
      name: 'Phim Ấm (Warm)',
      colorFilter: ColorFilter.matrix(<double>[
        1.15, 0.05, 0.0, 0, 10,
        0.02, 1.05, 0.0, 0, 6,
        0.0, 0.0, 0.90, 0, -5,
        0, 0, 0, 1, 0,
      ]),
    ),
    FilterPreset(
      id: 'sepia',
      name: 'Cổ Điển (Sepia)',
      colorFilter: ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0, 0, 0, 1, 0,
      ]),
    ),
    FilterPreset(
      id: 'bw_classic',
      name: 'Đen Trắng (B&W)',
      colorFilter: ColorFilter.matrix(<double>[
        0.299 * 1.2, 0.587 * 1.2, 0.114 * 1.2, 0, -10,
        0.299 * 1.2, 0.587 * 1.2, 0.114 * 1.2, 0, -10,
        0.299 * 1.2, 0.587 * 1.2, 0.114 * 1.2, 0, -10,
        0, 0, 0, 1, 0,
      ]),
    ),
    FilterPreset(
      id: 'cool_cinematic',
      name: 'Điện Ảnh (Cool)',
      colorFilter: ColorFilter.matrix(<double>[
        1.08, 0.0, 0.0, 0, 6,
        0.0, 0.98, 0.0, 0, 0,
        0.0, 0.05, 1.20, 0, 14,
        0, 0, 0, 1, 0,
      ]),
    ),
    FilterPreset(
      id: 'vivid',
      name: 'Rực Rỡ (Vivid)',
      colorFilter: ColorFilter.matrix(<double>[
        1.3, -0.15, -0.15, 0, 5,
        -0.15, 1.3, -0.15, 0, 5,
        -0.15, -0.15, 1.3, 0, 5,
        0, 0, 0, 1, 0,
      ]),
    ),
    FilterPreset(
      id: 'muted_pastel',
      name: 'Pastel (Muted)',
      colorFilter: ColorFilter.matrix(<double>[
        0.8, 0.1, 0.1, 0, 15,
        0.1, 0.8, 0.1, 0, 15,
        0.1, 0.1, 0.8, 0, 15,
        0, 0, 0, 1, 0,
      ]),
    ),
    FilterPreset(
      id: 'noir_dramatic',
      name: 'Kịch Tính (Noir)',
      colorFilter: ColorFilter.matrix(<double>[
        0.45, 0.45, 0.10, 0, -25,
        0.45, 0.45, 0.10, 0, -25,
        0.45, 0.45, 0.10, 0, -25,
        0, 0, 0, 1, 0,
      ]),
    ),
  ];
}
