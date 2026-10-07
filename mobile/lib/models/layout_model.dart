import 'dart:ui';
import 'package:flutter/material.dart';

class SlotRect {
  final double x;
  final double y;
  final double w;
  final double h;

  const SlotRect(this.x, this.y, this.w, this.h);

  Rect toRect(Size size) {
    return Rect.fromLTWH(
      x * size.width,
      y * size.height,
      w * size.width,
      h * size.height,
    );
  }
}

class CollageLayout {
  final String id;
  final String name;
  final int photoCount;
  final String category;
  final String description;
  final String aspectPreset; // "1:1", "4:5", "3:4", "9:16", "16:9", "original"
  final List<SlotRect> slots;
  final String iconSymbol;

  const CollageLayout({
    required this.id,
    required this.name,
    required this.photoCount,
    required this.category,
    required this.description,
    required this.slots,
    this.aspectPreset = "1:1",
    this.iconSymbol = "🔲",
  });
}

class LayoutsCatalog {
  static const List<CollageLayout> all = [
    // =========================================================
    // 1 ẢNH (SINGLE PHOTO) - 6 MẪU TỈ LỆ
    // =========================================================
    CollageLayout(
      id: "grid_1_original",
      name: "1 Ảnh Gốc (Nguyên Bản)",
      photoCount: 1,
      category: "1 Ảnh",
      description: "Giữ trọn vẹn 100% tỉ lệ khung hình gốc của ảnh ban đầu.",
      aspectPreset: "original",
      slots: [SlotRect(0.0, 0.0, 1.0, 1.0)],
      iconSymbol: "◻️",
    ),
    CollageLayout(
      id: "grid_1_square",
      name: "1 Ảnh Vuông (1:1 Square)",
      photoCount: 1,
      category: "1 Ảnh",
      description: "Tỉ lệ 1:1 chuẩn vuông cho ảnh đại diện, Instagram, kỷ niệm.",
      aspectPreset: "1:1",
      slots: [SlotRect(0.0, 0.0, 1.0, 1.0)],
      iconSymbol: "⏹️",
    ),
    CollageLayout(
      id: "grid_1_portrait_4_5",
      name: "1 Ảnh Dọc (4:5 Instagram)",
      photoCount: 1,
      category: "1 Ảnh",
      description: "Tỉ lệ dọc 4:5 tối ưu diện tích hiển thị trên bảng tin mạng xã hội.",
      aspectPreset: "4:5",
      slots: [SlotRect(0.0, 0.0, 1.0, 1.0)],
      iconSymbol: "▯",
    ),
    CollageLayout(
      id: "grid_1_portrait_3_4",
      name: "1 Ảnh Dọc Nghệ Thuật (3:4)",
      photoCount: 1,
      category: "1 Ảnh",
      description: "Tỉ lệ chân dung tiêu chuẩn của các triển lãm hội họa và nhiếp ảnh.",
      aspectPreset: "3:4",
      slots: [SlotRect(0.0, 0.0, 1.0, 1.0)],
      iconSymbol: "▯",
    ),
    CollageLayout(
      id: "grid_1_story_9_16",
      name: "1 Dọc Tràn Viền (9:16 Story)",
      photoCount: 1,
      category: "1 Ảnh",
      description: "Định dạng dọc 9:16 tràn viền cho Story Instagram, TikTok, Reels.",
      aspectPreset: "9:16",
      slots: [SlotRect(0.0, 0.0, 1.0, 1.0)],
      iconSymbol: "📱",
    ),
    CollageLayout(
      id: "grid_1_cinema_16_9",
      name: "1 Ngang Điện Ảnh (16:9)",
      photoCount: 1,
      category: "1 Ảnh",
      description: "Tỉ lệ màn ảnh rộng 16:9 cho ảnh phong cảnh, du lịch hùng vĩ.",
      aspectPreset: "16:9",
      slots: [SlotRect(0.0, 0.0, 1.0, 1.0)],
      iconSymbol: "🖥️",
    ),

    // =========================================================
    // 2 ẢNH (TWO PHOTOS) - 6 MẪU
    // =========================================================
    CollageLayout(
      id: "grid_2_split_v",
      name: "2 Cột Dọc Song Song (Side-by-Side)",
      photoCount: 2,
      category: "2 Ảnh",
      description: "Hai ảnh song song thẳng đứng cân đối 50/50, tuyệt vời cho so sánh hoặc chân dung đôi.",
      aspectPreset: "1:1",
      slots: [
        SlotRect(0.0, 0.0, 0.5, 1.0),
        SlotRect(0.5, 0.0, 0.5, 1.0),
      ],
      iconSymbol: "▥",
    ),
    CollageLayout(
      id: "grid_2_split_h",
      name: "2 Hàng Ngang Trên Dưới (Stacked)",
      photoCount: 2,
      category: "2 Ảnh",
      description: "Hai ảnh xếp lớp trên dưới, phong cách ảnh phim điện ảnh cinematic.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 1.0, 0.5),
        SlotRect(0.0, 0.5, 1.0, 0.5),
      ],
      iconSymbol: "▤",
    ),
    CollageLayout(
      id: "grid_2_asym_left",
      name: "1 Lớn Trái (65%) + 1 Nhỏ Phải (35%)",
      photoCount: 2,
      category: "2 Ảnh",
      description: "Bố cục tạp chí nghệ thuật với ảnh chính nổi bật và ảnh phụ bổ trợ.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 0.65, 1.0),
        SlotRect(0.65, 0.0, 0.35, 1.0),
      ],
      iconSymbol: "◧",
    ),
    CollageLayout(
      id: "grid_2_asym_right",
      name: "1 Nhỏ Trái (35%) + 1 Lớn Phải (65%)",
      photoCount: 2,
      category: "2 Ảnh",
      description: "Bố cục đảo ngược điểm nhấn về bên phải tạo nhịp điệu thị giác độc đáo.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 0.35, 1.0),
        SlotRect(0.35, 0.0, 0.65, 1.0),
      ],
      iconSymbol: "◨",
    ),
    CollageLayout(
      id: "grid_2_diagonal",
      name: "Bố Cục So Le Chéo (Diagonal)",
      photoCount: 2,
      category: "2 Ảnh",
      description: "Hai ảnh xếp so le góc chéo phong cách thiết kế mỹ thuật hiện đại.",
      aspectPreset: "1:1",
      slots: [
        SlotRect(0.0, 0.0, 0.62, 0.62),
        SlotRect(0.38, 0.38, 0.62, 0.62),
      ],
      iconSymbol: "◪",
    ),
    CollageLayout(
      id: "grid_2_polaroid_duo",
      name: "Cặp Đôi Tạp Chí (Duo Feature)",
      photoCount: 2,
      category: "2 Ảnh",
      description: "Khoảng thở rộng rãi giữa hai bức ảnh mang hơi thở triển lãm gallery.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.05, 0.05, 0.42, 0.9),
        SlotRect(0.53, 0.05, 0.42, 0.9),
      ],
      iconSymbol: "🎞️",
    ),

    // =========================================================
    // 3 ẢNH (THREE PHOTOS) - 7 MẪU
    // =========================================================
    CollageLayout(
      id: "grid_3_triptych",
      name: "Bộ Ba Triptych 3 Cột (Gallery)",
      photoCount: 3,
      category: "3 Ảnh",
      description: "Ba dải ảnh dọc song song kinh điển của các phòng trưng bày nghệ thuật tranh bộ ba.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 1.0 / 3.0, 1.0),
        SlotRect(1.0 / 3.0, 0.0, 1.0 / 3.0, 1.0),
        SlotRect(2.0 / 3.0, 0.0, 1.0 / 3.0, 1.0),
      ],
      iconSymbol: "川",
    ),
    CollageLayout(
      id: "grid_3_split_h",
      name: "Bộ Ba 3 Hàng Ngang (Cinema Strip)",
      photoCount: 3,
      category: "3 Ảnh",
      description: "Ba khung cảnh theo dòng thời gian xếp tầng từ trên xuống dưới.",
      aspectPreset: "3:4",
      slots: [
        SlotRect(0.0, 0.0, 1.0, 1.0 / 3.0),
        SlotRect(0.0, 1.0 / 3.0, 1.0, 1.0 / 3.0),
        SlotRect(0.0, 2.0 / 3.0, 1.0, 1.0 / 3.0),
      ],
      iconSymbol: "☰",
    ),
    CollageLayout(
      id: "grid_3_hero_left",
      name: "1 Lớn Trái (60%) + 2 Nhỏ Phải",
      photoCount: 3,
      category: "3 Ảnh",
      description: "Một ảnh tiêu điểm rộng bên trái cùng hai ảnh chi tiết xếp chồng bên phải.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.6, 1.0),
        SlotRect(0.6, 0.0, 0.4, 0.5),
        SlotRect(0.6, 0.5, 0.4, 0.5),
      ],
      iconSymbol: "◧",
    ),
    CollageLayout(
      id: "grid_3_hero_right",
      name: "2 Nhỏ Trái + 1 Lớn Phải (60%)",
      photoCount: 3,
      category: "3 Ảnh",
      description: "Hai ảnh nhỏ mở màn dẫn lối đến bức ảnh lớn ấn tượng bên phải.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.4, 0.5),
        SlotRect(0.0, 0.5, 0.4, 0.5),
        SlotRect(0.4, 0.0, 0.6, 1.0),
      ],
      iconSymbol: "◨",
    ),
    CollageLayout(
      id: "grid_3_hero_top",
      name: "1 To Toàn Cảnh Trên (60%) + 2 Nhỏ Dưới",
      photoCount: 3,
      category: "3 Ảnh",
      description: "Ảnh toàn cảnh landscape hùng vĩ phía trên và hai ảnh cận cảnh phía dưới.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 1.0, 0.6),
        SlotRect(0.0, 0.6, 0.5, 0.4),
        SlotRect(0.5, 0.6, 0.5, 0.4),
      ],
      iconSymbol: "⬒",
    ),
    CollageLayout(
      id: "grid_3_hero_bottom",
      name: "2 Nhỏ Trên + 1 To Toàn Cảnh Dưới",
      photoCount: 3,
      category: "3 Ảnh",
      description: "Hai ảnh khoảnh khắc phía trên nâng đỡ bức ảnh trọng tâm lớn phía dưới.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.5, 0.4),
        SlotRect(0.5, 0.0, 0.5, 0.4),
        SlotRect(0.0, 0.4, 1.0, 0.6),
      ],
      iconSymbol: "⬓",
    ),
    CollageLayout(
      id: "grid_3_center_focus",
      name: "Tâm Điểm Ở Giữa (Center Hero Focus)",
      photoCount: 3,
      category: "3 Ảnh",
      description: "Ảnh chính giữa khổ rộng lớn hơn kẹp giữa 2 ảnh dải biên.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 0.25, 1.0),
        SlotRect(0.25, 0.0, 0.5, 1.0),
        SlotRect(0.75, 0.0, 0.25, 1.0),
      ],
      iconSymbol: "⫴",
    ),

    // =========================================================
    // 4 ẢNH (FOUR PHOTOS) - 6 MẪU
    // =========================================================
    CollageLayout(
      id: "grid_4_quad_2x2",
      name: "Lưới 2x2 Cân Đối (Classic Quad)",
      photoCount: 4,
      category: "4 Ảnh",
      description: "Lưới 4 ô vuông hoàn hảo, cân xứng và tinh tế cho mọi thể loại ảnh.",
      aspectPreset: "1:1",
      slots: [
        SlotRect(0.0, 0.0, 0.5, 0.5),
        SlotRect(0.5, 0.0, 0.5, 0.5),
        SlotRect(0.0, 0.5, 0.5, 0.5),
        SlotRect(0.5, 0.5, 0.5, 0.5),
      ],
      iconSymbol: "田",
    ),
    CollageLayout(
      id: "grid_4_hero_left",
      name: "1 Lớn Trái (60%) + 3 Cột Nhỏ Phải",
      photoCount: 4,
      category: "4 Ảnh",
      description: "Ảnh chính chiếm trọn vế trái, vế phải gồm 3 khung hình diễn biến nhịp nhàng.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.6, 1.0),
        SlotRect(0.6, 0.0, 0.4, 1.0 / 3.0),
        SlotRect(0.6, 1.0 / 3.0, 0.4, 1.0 / 3.0),
        SlotRect(0.6, 2.0 / 3.0, 0.4, 1.0 / 3.0),
      ],
      iconSymbol: "◧",
    ),
    CollageLayout(
      id: "grid_4_hero_top",
      name: "1 To Rộng Trên (55%) + 3 Ô Nhỏ Dưới",
      photoCount: 4,
      category: "4 Ảnh",
      description: "Bố cục tạp chí du lịch: 1 phong cảnh lớn bên trên cùng 3 điểm nhấn hành trình.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 1.0, 0.55),
        SlotRect(0.0, 0.55, 1.0 / 3.0, 0.45),
        SlotRect(1.0 / 3.0, 0.55, 1.0 / 3.0, 0.45),
        SlotRect(2.0 / 3.0, 0.55, 1.0 / 3.0, 0.45),
      ],
      iconSymbol: "⬒",
    ),
    CollageLayout(
      id: "grid_4_strip_v",
      name: "4 Ô Dọc Photo Booth Hàn Quốc",
      photoCount: 4,
      category: "4 Ảnh",
      description: "Dải ảnh photobooth 4 tầng 4 biểu cảm cực hot của giới trẻ Hàn Quốc.",
      aspectPreset: "9:16",
      slots: [
        SlotRect(0.0, 0.0, 1.0, 0.25),
        SlotRect(0.0, 0.25, 1.0, 0.25),
        SlotRect(0.0, 0.5, 1.0, 0.25),
        SlotRect(0.0, 0.75, 1.0, 0.25),
      ],
      iconSymbol: "🎞️",
    ),
    CollageLayout(
      id: "grid_4_strip_h",
      name: "4 Cột Dọc Liền Kề (Panorama)",
      photoCount: 4,
      category: "4 Ảnh",
      description: "Bốn cột dọc dàn trải góc nhìn panorama rộng lớn.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 0.25, 1.0),
        SlotRect(0.25, 0.0, 0.25, 1.0),
        SlotRect(0.5, 0.0, 0.25, 1.0),
        SlotRect(0.75, 0.0, 0.25, 1.0),
      ],
      iconSymbol: "llll",
    ),
    CollageLayout(
      id: "grid_4_asym_mosaic",
      name: "Khảm Nghệ Thuật So Le (Mosaic Dynamic)",
      photoCount: 4,
      category: "4 Ảnh",
      description: "Các ô kích thước so le tạo cảm giác phóng khoáng và giàu năng lượng thị giác.",
      aspectPreset: "1:1",
      slots: [
        SlotRect(0.0, 0.0, 0.58, 0.42),
        SlotRect(0.58, 0.0, 0.42, 0.58),
        SlotRect(0.0, 0.42, 0.42, 0.58),
        SlotRect(0.42, 0.58, 0.58, 0.42),
      ],
      iconSymbol: "◈",
    ),

    // =========================================================
    // 5 ẢNH (FIVE PHOTOS) - 6 MẪU
    // =========================================================
    CollageLayout(
      id: "grid_5_center_hero",
      name: "1 Tâm Điểm Lớn + 4 Góc Vệ Tinh",
      photoCount: 5,
      category: "5 Ảnh",
      description: "Một ảnh to nằm ngay chính giữa được vây quanh bởi 4 ảnh phụ ở 4 góc.",
      aspectPreset: "1:1",
      slots: [
        SlotRect(0.0, 0.0, 0.35, 0.35),
        SlotRect(0.65, 0.0, 0.35, 0.35),
        SlotRect(0.18, 0.18, 0.64, 0.64), // Center Hero
        SlotRect(0.0, 0.65, 0.35, 0.35),
        SlotRect(0.65, 0.65, 0.35, 0.35),
      ],
      iconSymbol: "❖",
    ),
    CollageLayout(
      id: "grid_5_hero_left_4quad",
      name: "1 Lớn Trái (55%) + Lưới 4 Nhỏ Phải (2x2)",
      photoCount: 5,
      category: "5 Ảnh",
      description: "Bố cục chuẩn vàng: Vế trái là ảnh điểm nhấn, vế phải là lưới 4 ảnh sinh động.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.55, 1.0),
        SlotRect(0.55, 0.0, 0.225, 0.5),
        SlotRect(0.775, 0.0, 0.225, 0.5),
        SlotRect(0.55, 0.5, 0.225, 0.5),
        SlotRect(0.775, 0.5, 0.225, 0.5),
      ],
      iconSymbol: "◧",
    ),
    CollageLayout(
      id: "grid_5_2_top_3_bottom",
      name: "2 Tầng (2 Ảnh Lớn Trên + 3 Ảnh Dưới)",
      photoCount: 5,
      category: "5 Ảnh",
      description: "Hai ảnh chủ đạo ở hàng trên, ba ảnh kỷ niệm bổ sung ở hàng dưới.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.5, 0.55),
        SlotRect(0.5, 0.0, 0.5, 0.55),
        SlotRect(0.0, 0.55, 1.0 / 3.0, 0.45),
        SlotRect(1.0 / 3.0, 0.55, 1.0 / 3.0, 0.45),
        SlotRect(2.0 / 3.0, 0.55, 1.0 / 3.0, 0.45),
      ],
      iconSymbol: "▤",
    ),
    CollageLayout(
      id: "grid_5_3_top_2_bottom",
      name: "2 Tầng (3 Ảnh Trên + 2 Ảnh Lớn Dưới)",
      photoCount: 5,
      category: "5 Ảnh",
      description: "Ba ảnh nhỏ dàn hàng trên mở màn cho hai ảnh đắt giá kích thước lớn phía dưới.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 1.0 / 3.0, 0.45),
        SlotRect(1.0 / 3.0, 0.0, 1.0 / 3.0, 0.45),
        SlotRect(2.0 / 3.0, 0.0, 1.0 / 3.0, 0.45),
        SlotRect(0.0, 0.45, 0.5, 0.55),
        SlotRect(0.5, 0.45, 0.5, 0.55),
      ],
      iconSymbol: "▤",
    ),
    CollageLayout(
      id: "grid_5_hero_top_4strip",
      name: "1 To Toàn Cảnh Trên + 4 Ô Nhỏ Dưới",
      photoCount: 5,
      category: "5 Ảnh",
      description: "Toàn cảnh rộng lớn phía trên, phía dưới là chuỗi 4 khung hình nhỏ chi tiết.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 1.0, 0.6),
        SlotRect(0.0, 0.6, 0.25, 0.4),
        SlotRect(0.25, 0.6, 0.25, 0.4),
        SlotRect(0.5, 0.6, 0.25, 0.4),
        SlotRect(0.75, 0.6, 0.25, 0.4),
      ],
      iconSymbol: "⬒",
    ),
    CollageLayout(
      id: "grid_5_mosaic_chic",
      name: "Tạp Chí Mosaic Chic (5 Khung Tự Nhiên)",
      photoCount: 5,
      category: "5 Ảnh",
      description: "Sự pha trộn nhịp điệu kích thước tạo nét hiện đại cho lookbook thời trang.",
      aspectPreset: "1:1",
      slots: [
        SlotRect(0.0, 0.0, 0.4, 0.6),
        SlotRect(0.4, 0.0, 0.6, 0.4),
        SlotRect(0.4, 0.4, 0.3, 0.6),
        SlotRect(0.7, 0.4, 0.3, 0.6),
        SlotRect(0.0, 0.6, 0.4, 0.4),
      ],
      iconSymbol: "◫",
    ),

    // =========================================================
    // 6 ẢNH (SIX PHOTOS) - 6 MẪU
    // =========================================================
    CollageLayout(
      id: "grid_6_grid_3x2",
      name: "Lưới 3 Cột x 2 Hàng (Gallery 6 Classic)",
      photoCount: 6,
      category: "6 Ảnh",
      description: "Lưới 6 ô kinh điển đều đặn, hiển thị trọn vẹn bộ sưu tập hoặc album ảnh chuyến đi.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 1.0 / 3.0, 0.5),
        SlotRect(1.0 / 3.0, 0.0, 1.0 / 3.0, 0.5),
        SlotRect(2.0 / 3.0, 0.0, 1.0 / 3.0, 0.5),
        SlotRect(0.0, 0.5, 1.0 / 3.0, 0.5),
        SlotRect(1.0 / 3.0, 0.5, 1.0 / 3.0, 0.5),
        SlotRect(2.0 / 3.0, 0.5, 1.0 / 3.0, 0.5),
      ],
      iconSymbol: "▦",
    ),
    CollageLayout(
      id: "grid_6_grid_2x3",
      name: "Lưới 2 Cột x 3 Hàng Dọc (Pinterest/Story)",
      photoCount: 6,
      category: "6 Ảnh",
      description: "Bố cục dọc 6 ô thanh thoát, chuẩn định dạng bảng tin Pinterest và Instagram Story.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.5, 1.0 / 3.0),
        SlotRect(0.5, 0.0, 0.5, 1.0 / 3.0),
        SlotRect(0.0, 1.0 / 3.0, 0.5, 1.0 / 3.0),
        SlotRect(0.5, 1.0 / 3.0, 0.5, 1.0 / 3.0),
        SlotRect(0.0, 2.0 / 3.0, 0.5, 1.0 / 3.0),
        SlotRect(0.5, 2.0 / 3.0, 0.5, 1.0 / 3.0),
      ],
      iconSymbol: "目",
    ),
    CollageLayout(
      id: "grid_6_hero_left",
      name: "1 Hero Lớn Trái (50%) + Lưới 5 Nhỏ Phải",
      photoCount: 6,
      category: "6 Ảnh",
      description: "Một ảnh trung tâm siêu to bên trái kèm 5 ảnh nhỏ bổ trợ bao bọc bên phải.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.0, 0.0, 0.5, 1.0),
        SlotRect(0.5, 0.0, 0.25, 0.5),
        SlotRect(0.75, 0.0, 0.25, 0.5),
        SlotRect(0.5, 0.5, 1.0 / 6.0, 0.5),
        SlotRect(0.5 + 1.0 / 6.0, 0.5, 1.0 / 6.0, 0.5),
        SlotRect(0.5 + 2.0 / 6.0, 0.5, 1.0 / 6.0, 0.5),
      ],
      iconSymbol: "◧",
    ),
    CollageLayout(
      id: "grid_6_center_dual",
      name: "2 Ảnh Lớn Trung Tâm + 4 Góc Nhỏ",
      photoCount: 6,
      category: "6 Ảnh",
      description: "Hai ảnh trung tâm lớn nằm giữa, xung quanh là 4 khoảnh khắc mini ở 4 góc.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 0.25, 0.5),
        SlotRect(0.0, 0.5, 0.25, 0.5),
        SlotRect(0.25, 0.0, 0.25, 1.0), // Big 1
        SlotRect(0.5, 0.0, 0.25, 1.0), // Big 2
        SlotRect(0.75, 0.0, 0.25, 0.5),
        SlotRect(0.75, 0.5, 0.25, 0.5),
      ],
      iconSymbol: "◫",
    ),
    CollageLayout(
      id: "grid_6_photobooth_duo",
      name: "2 Cặp Dải Photo Booth (Duo Photostrip)",
      photoCount: 6,
      category: "6 Ảnh",
      description: "Hai dải photostrip 3 tầng đặt song song cạnh nhau cực phong cách.",
      aspectPreset: "4:5",
      slots: [
        SlotRect(0.06, 0.04, 0.41, 0.28),
        SlotRect(0.06, 0.36, 0.41, 0.28),
        SlotRect(0.06, 0.68, 0.41, 0.28),
        SlotRect(0.53, 0.04, 0.41, 0.28),
        SlotRect(0.53, 0.36, 0.41, 0.28),
        SlotRect(0.53, 0.68, 0.41, 0.28),
      ],
      iconSymbol: "🎞️",
    ),
    CollageLayout(
      id: "grid_6_fashion_spread",
      name: "Trang Đôi Tạp Chí (Fashion Spread)",
      photoCount: 6,
      category: "6 Ảnh",
      description: "Bố cục trang đôi tạp chí Vogue với độ cao tầng bậc tinh mỹ và sang trọng.",
      aspectPreset: "16:9",
      slots: [
        SlotRect(0.0, 0.0, 0.35, 0.65),
        SlotRect(0.35, 0.0, 0.35, 0.35),
        SlotRect(0.70, 0.0, 0.30, 0.50),
        SlotRect(0.0, 0.65, 0.35, 0.35),
        SlotRect(0.35, 0.35, 0.35, 0.65),
        SlotRect(0.70, 0.50, 0.30, 0.50),
      ],
      iconSymbol: "📰",
    ),
  ];

  static List<CollageLayout> forCount(int count) {
    return all.where((l) => l.photoCount == count).toList();
  }

  static CollageLayout findById(String id) {
    return all.firstWhere((l) => l.id == id, orElse: () => all.first);
  }
}
