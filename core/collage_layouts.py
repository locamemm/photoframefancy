"""
PhotoFrameFancy - Collage & Grid Layout Definitions
Provides 30+ sophisticated grid and collage layouts for 2, 3, 4, 5, and 6 photos.
Each layout defines normalized slot bounding boxes (x, y, w, h) in [0.0, 1.0].
"""

from dataclasses import dataclass
from typing import List, Tuple, Dict, Any, Optional


@dataclass
class CollageLayout:
    id: str
    name: str
    photo_count: int
    category: str
    description: str
    aspect_preset: str  # "1:1", "4:5", "3:4", "16:9", "9:16", "3:2"
    # List of (x, y, w, h) in range 0.0 - 1.0
    slots: List[Tuple[float, float, float, float]]
    icon_symbol: str = "🔲"


COLLAGE_LAYOUTS: Dict[str, CollageLayout] = {
    # =========================================================
    # 1 ẢNH (SINGLE PHOTO) - 6 MẪU TỈ LỆ
    # =========================================================
    "grid_1_original": CollageLayout(
        id="grid_1_original",
        name="1 Ảnh Gốc (Tỉ Lệ Nguyên Bản)",
        photo_count=1,
        category="1 Ảnh",
        description="Giữ trọn vẹn 100% tỉ lệ khung hình gốc của ảnh ban đầu.",
        aspect_preset="original",
        slots=[(0.0, 0.0, 1.0, 1.0)],
        icon_symbol="◻️",
    ),
    "grid_1_square": CollageLayout(
        id="grid_1_square",
        name="1 Ảnh Vuông (1:1 Square)",
        photo_count=1,
        category="1 Ảnh",
        description="Tỉ lệ 1:1 chuẩn vuông cho ảnh đại diện, Instagram, kỷ niệm.",
        aspect_preset="1:1",
        slots=[(0.0, 0.0, 1.0, 1.0)],
        icon_symbol="⏹️",
    ),
    "grid_1_portrait_4_5": CollageLayout(
        id="grid_1_portrait_4_5",
        name="1 Ảnh Dọc (4:5 Instagram Portrait)",
        photo_count=1,
        category="1 Ảnh",
        description="Tỉ lệ dọc 4:5 tối ưu diện tích hiển thị trên bảng tin mạng xã hội.",
        aspect_preset="4:5",
        slots=[(0.0, 0.0, 1.0, 1.0)],
        icon_symbol="▯",
    ),
    "grid_1_portrait_3_4": CollageLayout(
        id="grid_1_portrait_3_4",
        name="1 Ảnh Dọc Nghệ Thuật (3:4 Portrait)",
        photo_count=1,
        category="1 Ảnh",
        description="Tỉ lệ chân dung tiêu chuẩn của các triển lãm hội họa và nhiếp ảnh.",
        aspect_preset="3:4",
        slots=[(0.0, 0.0, 1.0, 1.0)],
        icon_symbol="▯",
    ),
    "grid_1_story_9_16": CollageLayout(
        id="grid_1_story_9_16",
        name="1 Ảnh Dọc Đầy Màn Hình (9:16 Story)",
        photo_count=1,
        category="1 Ảnh",
        description="Định dạng dọc 9:16 tràn viền cho Story Instagram, TikTok, Reels.",
        aspect_preset="9:16",
        slots=[(0.0, 0.0, 1.0, 1.0)],
        icon_symbol="📱",
    ),
    "grid_1_cinema_16_9": CollageLayout(
        id="grid_1_cinema_16_9",
        name="1 Ảnh Ngang Điện Ảnh (16:9 Landscape)",
        photo_count=1,
        category="1 Ảnh",
        description="Tỉ lệ màn ảnh rộng 16:9 cho ảnh phong cảnh, du lịch hùng vĩ.",
        aspect_preset="16:9",
        slots=[(0.0, 0.0, 1.0, 1.0)],
        icon_symbol="🖥️",
    ),
    # =========================================================
    # 2 ẢNH (TWO PHOTOS) - 6 MẪU
    # =========================================================
    "grid_2_split_v": CollageLayout(
        id="grid_2_split_v",
        name="2 Cột Dọc Song Song (Side-by-Side)",
        photo_count=2,
        category="2 Ảnh",
        description="Hai ảnh song song thẳng đứng cân đối 50/50, tuyệt vời cho so sánh hoặc chân dung đôi.",
        aspect_preset="1:1",
        slots=[
            (0.0, 0.0, 0.5, 1.0),
            (0.5, 0.0, 0.5, 1.0),
        ],
        icon_symbol="▥",
    ),
    "grid_2_split_h": CollageLayout(
        id="grid_2_split_h",
        name="2 Hàng Ngang Trên Dưới (Stacked)",
        photo_count=2,
        category="2 Ảnh",
        description="Hai ảnh xếp lớp trên dưới, phong cách ảnh phim điện ảnh cinematic.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 1.0, 0.5),
            (0.0, 0.5, 1.0, 0.5),
        ],
        icon_symbol="▤",
    ),
    "grid_2_asym_left": CollageLayout(
        id="grid_2_asym_left",
        name="1 Lớn Trái (65%) + 1 Nhỏ Phải (35%)",
        photo_count=2,
        category="2 Ảnh",
        description="Bố cục tạp chí nghệ thuật với ảnh chính nổi bật và ảnh phụ bổ trợ.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 0.65, 1.0),
            (0.65, 0.0, 0.35, 1.0),
        ],
        icon_symbol="◧",
    ),
    "grid_2_asym_right": CollageLayout(
        id="grid_2_asym_right",
        name="1 Nhỏ Trái (35%) + 1 Lớn Phải (65%)",
        photo_count=2,
        category="2 Ảnh",
        description="Bố cục đảo ngược điểm nhấn về bên phải tạo nhịp điệu thị giác độc đáo.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 0.35, 1.0),
            (0.35, 0.0, 0.65, 1.0),
        ],
        icon_symbol="◨",
    ),
    "grid_2_diagonal": CollageLayout(
        id="grid_2_diagonal",
        name="Bố Cục So Le Chéo (Diagonal Staggered)",
        photo_count=2,
        category="2 Ảnh",
        description="Hai ảnh xếp so le góc chéo phong cách thiết kế mỹ thuật hiện đại.",
        aspect_preset="1:1",
        slots=[
            (0.0, 0.0, 0.62, 0.62),
            (0.38, 0.38, 0.62, 0.62),
        ],
        icon_symbol="◪",
    ),
    "grid_2_polaroid_duo": CollageLayout(
        id="grid_2_polaroid_duo",
        name="Cặp Đôi Tạp Chí (Duo Feature)",
        photo_count=2,
        category="2 Ảnh",
        description="Khoảng thở rộng rãi giữa hai bức ảnh mang hơi thở triển lãm gallery.",
        aspect_preset="4:5",
        slots=[
            (0.05, 0.05, 0.42, 0.9),
            (0.53, 0.05, 0.42, 0.9),
        ],
        icon_symbol="🎞️",
    ),

    # =========================================================
    # 3 ẢNH (THREE PHOTOS) - 7 MẪU
    # =========================================================
    "grid_3_triptych": CollageLayout(
        id="grid_3_triptych",
        name="Bộ Ba Triptych 3 Cột Dọc (Gallery Classic)",
        photo_count=3,
        category="3 Ảnh",
        description="Ba dải ảnh dọc song song kinh điển của các phòng trưng bày nghệ thuật tranh bộ ba.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 1/3, 1.0),
            (1/3, 0.0, 1/3, 1.0),
            (2/3, 0.0, 1/3, 1.0),
        ],
        icon_symbol="川",
    ),
    "grid_3_split_h": CollageLayout(
        id="grid_3_split_h",
        name="Bộ Ba 3 Hàng Ngang (Cinema Strip)",
        photo_count=3,
        category="3 Ảnh",
        description="Ba khung cảnh theo dòng thời gian xếp tầng từ trên xuống dưới.",
        aspect_preset="3:4",
        slots=[
            (0.0, 0.0, 1.0, 1/3),
            (0.0, 1/3, 1.0, 1/3),
            (0.0, 2/3, 1.0, 1/3),
        ],
        icon_symbol="☰",
    ),
    "grid_3_hero_left": CollageLayout(
        id="grid_3_hero_left",
        name="1 Lớn Trái (60%) + 2 Nhỏ Phải (Editorial Left)",
        photo_count=3,
        category="3 Ảnh",
        description="Một ảnh tiêu điểm rộng bên trái cùng hai ảnh chi tiết xếp chồng bên phải.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.6, 1.0),
            (0.6, 0.0, 0.4, 0.5),
            (0.6, 0.5, 0.4, 0.5),
        ],
        icon_symbol="◧",
    ),
    "grid_3_hero_right": CollageLayout(
        id="grid_3_hero_right",
        name="2 Nhỏ Trái + 1 Lớn Phải (60%)",
        photo_count=3,
        category="3 Ảnh",
        description="Hai ảnh nhỏ mở màn dẫn lối đến bức ảnh lớn ấn tượng bên phải.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.4, 0.5),
            (0.0, 0.5, 0.4, 0.5),
            (0.4, 0.0, 0.6, 1.0),
        ],
        icon_symbol="◨",
    ),
    "grid_3_hero_top": CollageLayout(
        id="grid_3_hero_top",
        name="1 To Toàn Cảnh Trên (60%) + 2 Nhỏ Dưới",
        photo_count=3,
        category="3 Ảnh",
        description="Ảnh toàn cảnh landscape hùng vĩ phía trên và hai ảnh cận cảnh phía dưới.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 1.0, 0.6),
            (0.0, 0.6, 0.5, 0.4),
            (0.5, 0.6, 0.5, 0.4),
        ],
        icon_symbol="⬒",
    ),
    "grid_3_hero_bottom": CollageLayout(
        id="grid_3_hero_bottom",
        name="2 Nhỏ Trên + 1 To Toàn Cảnh Dưới (60%)",
        photo_count=3,
        category="3 Ảnh",
        description="Hai ảnh khoảnh khắc phía trên nâng đỡ bức ảnh trọng tâm lớn phía dưới.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.5, 0.4),
            (0.5, 0.0, 0.5, 0.4),
            (0.0, 0.4, 1.0, 0.6),
        ],
        icon_symbol="⬓",
    ),
    "grid_3_center_focus": CollageLayout(
        id="grid_3_center_focus",
        name="Tâm Điểm Ở Giữa (Center Hero Focus)",
        photo_count=3,
        category="3 Ảnh",
        description="Ảnh chính giữa khổ rộng lớn hơn kẹp giữa 2 ảnh dải biên.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 0.25, 1.0),
            (0.25, 0.0, 0.5, 1.0),
            (0.75, 0.0, 0.25, 1.0),
        ],
        icon_symbol="⫴",
    ),

    # =========================================================
    # 4 ẢNH (FOUR PHOTOS) - 6 MẪU
    # =========================================================
    "grid_4_quad_2x2": CollageLayout(
        id="grid_4_quad_2x2",
        name="Lưới 2x2 Cân Đối (Classic Quad)",
        photo_count=4,
        category="4 Ảnh",
        description="Lưới 4 ô vuông hoàn hảo, cân xứng và tinh tế cho mọi thể loại ảnh.",
        aspect_preset="1:1",
        slots=[
            (0.0, 0.0, 0.5, 0.5),
            (0.5, 0.0, 0.5, 0.5),
            (0.0, 0.5, 0.5, 0.5),
            (0.5, 0.5, 0.5, 0.5),
        ],
        icon_symbol="田",
    ),
    "grid_4_hero_left": CollageLayout(
        id="grid_4_hero_left",
        name="1 Lớn Trái (60%) + 3 Cột Nhỏ Phải",
        photo_count=4,
        category="4 Ảnh",
        description="Ảnh chính chiếm trọn vế trái, vế phải gồm 3 khung hình diễn biến nhịp nhàng.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.6, 1.0),
            (0.6, 0.0, 0.4, 1/3),
            (0.6, 1/3, 0.4, 1/3),
            (0.6, 2/3, 0.4, 1/3),
        ],
        icon_symbol="◧",
    ),
    "grid_4_hero_top": CollageLayout(
        id="grid_4_hero_top",
        name="1 To Rộng Trên (55%) + 3 Ô Nhỏ Dưới",
        photo_count=4,
        category="4 Ảnh",
        description="Bố cục tạp chí du lịch: 1 phong cảnh lớn bên trên cùng 3 điểm nhấn hành trình.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 1.0, 0.55),
            (0.0, 0.55, 1/3, 0.45),
            (1/3, 0.55, 1/3, 0.45),
            (2/3, 0.55, 1/3, 0.45),
        ],
        icon_symbol="⬒",
    ),
    "grid_4_strip_v": CollageLayout(
        id="grid_4_strip_v",
        name="4 Ô Dọc Photo Booth Hàn Quốc (Vertical Strip)",
        photo_count=4,
        category="4 Ảnh",
        description="Dải ảnh photobooth 4 tầng 4 biểu cảm cực hot của giới trẻ Hàn Quốc.",
        aspect_preset="9:16",
        slots=[
            (0.0, 0.0, 1.0, 0.25),
            (0.0, 0.25, 1.0, 0.25),
            (0.0, 0.5, 1.0, 0.25),
            (0.0, 0.75, 1.0, 0.25),
        ],
        icon_symbol="🎞️",
    ),
    "grid_4_strip_h": CollageLayout(
        id="grid_4_strip_h",
        name="4 Cột Dọc Liền Kề (Panoramic 4 Columns)",
        photo_count=4,
        category="4 Ảnh",
        description="Bốn cột dọc dàn trải góc nhìn panorama rộng lớn.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 0.25, 1.0),
            (0.25, 0.0, 0.25, 1.0),
            (0.5, 0.0, 0.25, 1.0),
            (0.75, 0.0, 0.25, 1.0),
        ],
        icon_symbol="llll",
    ),
    "grid_4_asym_mosaic": CollageLayout(
        id="grid_4_asym_mosaic",
        name="Khảm Nghệ Thuật Bất Đối Xứng (Mosaic Dynamic)",
        photo_count=4,
        category="4 Ảnh",
        description="Các ô kích thước so le tạo cảm giác phóng khoáng và giàu năng lượng thị giác.",
        aspect_preset="1:1",
        slots=[
            (0.0, 0.0, 0.58, 0.42),
            (0.58, 0.0, 0.42, 0.58),
            (0.0, 0.42, 0.42, 0.58),
            (0.42, 0.58, 0.58, 0.42),
        ],
        icon_symbol="◈",
    ),

    # =========================================================
    # 5 ẢNH (FIVE PHOTOS) - 6 MẪU
    # =========================================================
    "grid_5_center_hero": CollageLayout(
        id="grid_5_center_hero",
        name="1 Tâm Điểm Lớn + 4 Góc Vệ Tinh (Center Hero)",
        photo_count=5,
        category="5 Ảnh",
        description="Một ảnh to nằm ngay chính giữa được vây quanh bởi 4 ảnh phụ ở 4 góc.",
        aspect_preset="1:1",
        slots=[
            (0.0, 0.0, 0.35, 0.35),
            (0.65, 0.0, 0.35, 0.35),
            (0.18, 0.18, 0.64, 0.64), # Center Hero
            (0.0, 0.65, 0.35, 0.35),
            (0.65, 0.65, 0.35, 0.35),
        ],
        icon_symbol="❖",
    ),
    "grid_5_hero_left_4quad": CollageLayout(
        id="grid_5_hero_left_4quad",
        name="1 Lớn Trái (55%) + Lưới 4 Nhỏ Phải (2x2)",
        photo_count=5,
        category="5 Ảnh",
        description="Bố cục chuẩn vàng: Vế trái là ảnh điểm nhấn, vế phải là lưới 4 ảnh sinh động.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.55, 1.0),
            (0.55, 0.0, 0.225, 0.5),
            (0.775, 0.0, 0.225, 0.5),
            (0.55, 0.5, 0.225, 0.5),
            (0.775, 0.5, 0.225, 0.5),
        ],
        icon_symbol="◧",
    ),
    "grid_5_2_top_3_bottom": CollageLayout(
        id="grid_5_2_top_3_bottom",
        name="2 Tầng (2 Ảnh Lớn Trên + 3 Ảnh Dưới)",
        photo_count=5,
        category="5 Ảnh",
        description="Hai ảnh chủ đạo ở hàng trên, ba ảnh kỷ niệm bổ sung ở hàng dưới.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.5, 0.55),
            (0.5, 0.0, 0.5, 0.55),
            (0.0, 0.55, 1/3, 0.45),
            (1/3, 0.55, 1/3, 0.45),
            (2/3, 0.55, 1/3, 0.45),
        ],
        icon_symbol="▤",
    ),
    "grid_5_3_top_2_bottom": CollageLayout(
        id="grid_5_3_top_2_bottom",
        name="2 Tầng (3 Ảnh Trên + 2 Ảnh Lớn Dưới)",
        photo_count=5,
        category="5 Ảnh",
        description="Ba ảnh nhỏ dàn hàng trên mở màn cho hai ảnh đắt giá kích thước lớn phía dưới.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 1/3, 0.45),
            (1/3, 0.0, 1/3, 0.45),
            (2/3, 0.0, 1/3, 0.45),
            (0.0, 0.45, 0.5, 0.55),
            (0.5, 0.45, 0.5, 0.55),
        ],
        icon_symbol="▤",
    ),
    "grid_5_hero_top_4strip": CollageLayout(
        id="grid_5_hero_top_4strip",
        name="1 To Toàn Cảnh Trên + 4 Ô Nhỏ Dưới",
        photo_count=5,
        category="5 Ảnh",
        description="Toàn cảnh rộng lớn phía trên, phía dưới là chuỗi 4 khung hình nhỏ chi tiết.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 1.0, 0.6),
            (0.0, 0.6, 0.25, 0.4),
            (0.25, 0.6, 0.25, 0.4),
            (0.5, 0.6, 0.25, 0.4),
            (0.75, 0.6, 0.25, 0.4),
        ],
        icon_symbol="⬒",
    ),
    "grid_5_mosaic_chic": CollageLayout(
        id="grid_5_mosaic_chic",
        name="Tạp Chí Mosaic Chic (5 Khung Tự Nhiên)",
        photo_count=5,
        category="5 Ảnh",
        description="Sự pha trộn nhịp điệu kích thước tạo nét hiện đại cho lookbook thời trang.",
        aspect_preset="1:1",
        slots=[
            (0.0, 0.0, 0.4, 0.6),
            (0.4, 0.0, 0.6, 0.4),
            (0.4, 0.4, 0.3, 0.6),
            (0.7, 0.4, 0.3, 0.6),
            (0.0, 0.6, 0.4, 0.4),
        ],
        icon_symbol="◫",
    ),

    # =========================================================
    # 6 ẢNH (SIX PHOTOS) - 6 MẪU
    # =========================================================
    "grid_6_grid_3x2": CollageLayout(
        id="grid_6_grid_3x2",
        name="Lưới 3 Cột x 2 Hàng (Classic 6 Gallery)",
        photo_count=6,
        category="6 Ảnh",
        description="Lưới 6 ô kinh điển đều đặn, hiển thị trọn vẹn bộ sưu tập hoặc album ảnh chuyến đi.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 1/3, 0.5),
            (1/3, 0.0, 1/3, 0.5),
            (2/3, 0.0, 1/3, 0.5),
            (0.0, 0.5, 1/3, 0.5),
            (1/3, 0.5, 1/3, 0.5),
            (2/3, 0.5, 1/3, 0.5),
        ],
        icon_symbol="▦",
    ),
    "grid_6_grid_2x3": CollageLayout(
        id="grid_6_grid_2x3",
        name="Lưới 2 Cột x 3 Hàng Dọc (Story/Pinterest 6)",
        photo_count=6,
        category="6 Ảnh",
        description="Bố cục dọc 6 ô thanh thoát, chuẩn định dạng bảng tin Pinterest và Instagram Story.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.5, 1/3),
            (0.5, 0.0, 0.5, 1/3),
            (0.0, 1/3, 0.5, 1/3),
            (0.5, 1/3, 0.5, 1/3),
            (0.0, 2/3, 0.5, 1/3),
            (0.5, 2/3, 0.5, 1/3),
        ],
        icon_symbol="目",
    ),
    "grid_6_hero_left": CollageLayout(
        id="grid_6_hero_left",
        name="1 Hero Lớn Trái (50%) + Lưới 5 Nhỏ Phải",
        photo_count=6,
        category="6 Ảnh",
        description="Một ảnh trung tâm siêu to bên trái kèm 5 ảnh nhỏ bổ trợ bao bọc bên phải.",
        aspect_preset="4:5",
        slots=[
            (0.0, 0.0, 0.5, 1.0),
            (0.5, 0.0, 0.25, 0.5),
            (0.75, 0.0, 0.25, 0.5),
            (0.5, 0.5, 1/6, 0.5),
            (0.5 + 1/6, 0.5, 1/6, 0.5),
            (0.5 + 2/6, 0.5, 1/6, 0.5),
        ],
        icon_symbol="◧",
    ),
    "grid_6_center_dual": CollageLayout(
        id="grid_6_center_dual",
        name="2 Ảnh Lớn Trung Tâm + 4 Góc Nhỏ",
        photo_count=6,
        category="6 Ảnh",
        description="Hai ảnh trung tâm lớn nằm giữa, xung quanh là 4 khoảnh khắc mini ở 4 góc.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 0.25, 0.5),
            (0.0, 0.5, 0.25, 0.5),
            (0.25, 0.0, 0.25, 1.0), # Big 1
            (0.5, 0.0, 0.25, 1.0),  # Big 2
            (0.75, 0.0, 0.25, 0.5),
            (0.75, 0.5, 0.25, 0.5),
        ],
        icon_symbol="◫",
    ),
    "grid_6_photobooth_duo": CollageLayout(
        id="grid_6_photobooth_duo",
        name="2 Cặp Dải Photo Booth (Duo Photostrip)",
        photo_count=6,
        category="6 Ảnh",
        description="Hai dải photostrip 3 tầng đặt song song cạnh nhau cực phong cách.",
        aspect_preset="4:5",
        slots=[
            # Left strip
            (0.06, 0.04, 0.41, 0.28),
            (0.06, 0.36, 0.41, 0.28),
            (0.06, 0.68, 0.41, 0.28),
            # Right strip
            (0.53, 0.04, 0.41, 0.28),
            (0.53, 0.36, 0.41, 0.28),
            (0.53, 0.68, 0.41, 0.28),
        ],
        icon_symbol="🎞️",
    ),
    "grid_6_fashion_spread": CollageLayout(
        id="grid_6_fashion_spread",
        name="Trang Đôi Tạp Chí Thời Trang (Fashion Spread)",
        photo_count=6,
        category="6 Ảnh",
        description="Bố cục trang đôi tạp chí Vogue với độ cao tầng bậc tinh mỹ và sang trọng.",
        aspect_preset="16:9",
        slots=[
            (0.0, 0.0, 0.35, 0.65),
            (0.35, 0.0, 0.35, 0.35),
            (0.70, 0.0, 0.30, 0.50),
            (0.0, 0.65, 0.35, 0.35),
            (0.35, 0.35, 0.35, 0.65),
            (0.70, 0.50, 0.30, 0.50),
        ],
        icon_symbol="📰",
    ),
}


def get_collage_categories() -> List[str]:
    """Return categories: 1 Ảnh, 2 Ảnh, 3 Ảnh, 4 Ảnh, 5 Ảnh, 6 Ảnh."""
    return ["1 Ảnh", "2 Ảnh", "3 Ảnh", "4 Ảnh", "5 Ảnh", "6 Ảnh"]


def get_layouts_by_photo_count(count: int) -> List[CollageLayout]:
    """Get all layouts matching a specific photo count."""
    return [l for l in COLLAGE_LAYOUTS.values() if l.photo_count == count]


def get_layouts_by_category(category: str) -> List[CollageLayout]:
    """Get all layouts matching a category name."""
    return [l for l in COLLAGE_LAYOUTS.values() if l.category == category]
