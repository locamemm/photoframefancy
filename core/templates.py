"""
PhotoFrameFancy - Template Registry & Specifications
Defines presets and styling rules for each frame category.
"""

from dataclasses import dataclass, field
from typing import Dict, Any, List


@dataclass
class FrameTemplate:
    id: str
    name: str
    category: str
    description: str
    default_border_ratio: float = 0.05  # border relative to image size
    default_mat_ratio: float = 0.08     # inner mat relative to image size
    default_frame_color: str = "#2C2C2E"
    default_mat_color: str = "#F8F7F2"
    has_corner_accents: bool = False
    has_shadow: bool = True
    aspect_preset: str = "original"     # "original", "1:1", "4:5", "3:4", "9:16", "16:9"
    supports_caption: bool = False
    default_caption: str = ""
    icon_symbol: str = "🖼️"


TEMPLATES: Dict[str, FrameTemplate] = {
    # 0. MINIMAL & BORDERLESS
    "minimal_clean": FrameTemplate(
        id="minimal_clean",
        name="Tối Giản Thuần Khiết (Không Viền)",
        category="Hiện Đại & Tinh Tế",
        description="Không viền ngoài rườm rà, giữ trọn vẹn bố cục ảnh và khe lưới sạch sẽ.",
        default_border_ratio=0.0,
        default_mat_ratio=0.0,
        default_frame_color="#FFFFFF",
        default_mat_color="#FFFFFF",
        has_corner_accents=False,
        has_shadow=False,
        icon_symbol="⬜",
    ),
    # 1. CLASSIC & ROYAL
    "gold_baroque": FrameTemplate(
        id="gold_baroque",
        name="Hoàng Gia Vàng Kim",
        category="Cổ Điển & Sang Trọng",
        description="Khung mạ vàng hoàng gia sang trọng với viền nổi 3 lớp, góc chạm khắc tinh xảo và bóng sâu.",
        default_border_ratio=0.07,
        default_mat_ratio=0.06,
        default_frame_color="#D4AF37",
        default_mat_color="#18181B",
        has_corner_accents=True,
        has_shadow=True,
        icon_symbol="👑",
    ),
    "dark_walnut": FrameTemplate(
        id="dark_walnut",
        name="Gỗ Óc Chó Quý Tộc",
        category="Cổ Điển & Sang Trọng",
        description="Khung gỗ óc chó sẫm màu với chỉ vàng nẹp trong, ghép góc vát 45 độ và vân gỗ tự nhiên.",
        default_border_ratio=0.08,
        default_mat_ratio=0.07,
        default_frame_color="#3D2314",
        default_mat_color="#F4EFEA",
        has_corner_accents=False,
        has_shadow=True,
        icon_symbol="🪵",
    ),
    "antique_bronze": FrameTemplate(
        id="antique_bronze",
        name="Đồng Cổ Điển Nghệ Thuật",
        category="Cổ Điển & Sang Trọng",
        description="Khung đồng cổ ánh kim rêu phong phong cách bảo tàng Louvre với viền gờ nổi.",
        default_border_ratio=0.065,
        default_mat_ratio=0.05,
        default_frame_color="#7B5B33",
        default_mat_color="#242220",
        has_corner_accents=True,
        has_shadow=True,
        icon_symbol="🏛️",
    ),
    "museum_gallery": FrameTemplate(
        id="museum_gallery",
        name="Khung Triển Lãm Passe-partout",
        category="Cổ Điển & Sang Trọng",
        description="Phong cách triển lãm tranh quốc tế: Viền ngoài đen mun mảnh mai, bìa matting dày cắt xiên 45°.",
        default_border_ratio=0.03,
        default_mat_ratio=0.12,
        default_frame_color="#121212",
        default_mat_color="#FDFBF7",
        has_corner_accents=False,
        has_shadow=True,
        supports_caption=True,
        default_caption="Art Gallery Collection",
        icon_symbol="🖼️",
    ),

    # 2. MODERN & MINIMALIST
    "modern_floating": FrameTemplate(
        id="modern_floating",
        name="Khung Nổi 3D Tối Giản",
        category="Hiện Đại & Tinh Tế",
        description="Ảnh lơ lửng trên phông nền với bóng đổ mềm nhiều lớp siêu thực (Soft Elevation Shadow).",
        default_border_ratio=0.0,
        default_mat_ratio=0.10,
        default_frame_color="#FFFFFF",
        default_mat_color="#EBECEF",
        has_corner_accents=False,
        has_shadow=True,
        icon_symbol="✨",
    ),
    "nordic_clean": FrameTemplate(
        id="nordic_clean",
        name="Bắc Âu Tinh Khôi (Nordic)",
        category="Hiện Đại & Tinh Tế",
        description="Viền gỗ sồi sáng màu thanh lịch, góc bo cong mềm mại và khoảng trắng thoáng đãng.",
        default_border_ratio=0.04,
        default_mat_ratio=0.08,
        default_frame_color="#E8D8C8",
        default_mat_color="#FAFAFA",
        has_corner_accents=False,
        has_shadow=True,
        icon_symbol="🕊️",
    ),
    "double_pinstripe": FrameTemplate(
        id="double_pinstripe",
        name="Chỉ Đôi Thượng Lưu",
        category="Hiện Đại & Tinh Tế",
        description="Khung viền chỉ đôi song song mạ vàng tinh tế, phong cách ấn phẩm thương hiệu cao cấp.",
        default_border_ratio=0.02,
        default_mat_ratio=0.10,
        default_frame_color="#1E1E24",
        default_mat_color="#FAF9F6",
        has_corner_accents=False,
        has_shadow=True,
        icon_symbol="📐",
    ),
    "neon_cyberpunk": FrameTemplate(
        id="neon_cyberpunk",
        name="Neon Cyberpunk Glow",
        category="Hiện Đại & Tinh Tế",
        description="Viền phát sáng Gradient Cyan & Magenta rực rỡ trên nền đen tuyền huyền bí.",
        default_border_ratio=0.03,
        default_mat_ratio=0.08,
        default_frame_color="#00F0FF",
        default_mat_color="#0B0C10",
        has_corner_accents=False,
        has_shadow=False,
        icon_symbol="⚡",
    ),

    # 3. RETRO & CREATIVE
    "polaroid_classic": FrameTemplate(
        id="polaroid_classic",
        name="Ảnh Chụp Lấy Liền Polaroid",
        category="Hoài Niệm & Nghệ Thuật",
        description="Khung film polaroid cổ điển với phần đuôi ảnh rộng kèm chữ ký viết tay độc bản.",
        default_border_ratio=0.05,
        default_mat_ratio=0.08,
        default_frame_color="#000000",
        default_mat_color="#FBFBF9",
        has_corner_accents=False,
        has_shadow=True,
        aspect_preset="4:5",
        supports_caption=True,
        default_caption="Memories • Forever",
        icon_symbol="📸",
    ),
    "film_35mm": FrameTemplate(
        id="film_35mm",
        name="Cuộn Phim 35mm Cổ Điển",
        category="Hoài Niệm & Nghệ Thuật",
        description="Băng phim điện ảnh Kodak/Fuji với lỗ đục film (sprockets) và mã số khung phim hoài cổ.",
        default_border_ratio=0.04,
        default_mat_ratio=0.10,
        default_frame_color="#111111",
        default_mat_color="#0A0A0A",
        has_corner_accents=False,
        has_shadow=False,
        aspect_preset="3:2",
        supports_caption=True,
        default_caption="KODAK GOLD 200  ▶  24A",
        icon_symbol="🎞️",
    ),
    "vintage_stamp": FrameTemplate(
        id="vintage_stamp",
        name="Tem Thư Bưu Chính Cổ Điển",
        category="Hoài Niệm & Nghệ Thuật",
        description="Viền răng cưa tem thư cổ bưu chính kèm mộc bưu điện tròn đóng dấu kỷ niệm.",
        default_border_ratio=0.03,
        default_mat_ratio=0.08,
        default_frame_color="#D9CBB7",
        default_mat_color="#F8F3EA",
        has_corner_accents=False,
        has_shadow=True,
        supports_caption=True,
        default_caption="POSTE AERIENNE • SPECIAL",
        icon_symbol="✉️",
    ),
    "scrapbook_kraft": FrameTemplate(
        id="scrapbook_kraft",
        name="Sổ Kỷ Niệm & Băng Dính Washi",
        category="Hoài Niệm & Nghệ Thuật",
        description="Khung giấy thô mộc Vintage Kraft Paper với băng dính washi dán chéo 4 góc ảnh.",
        default_border_ratio=0.02,
        default_mat_ratio=0.10,
        default_frame_color="#8C7355",
        default_mat_color="#E8DFD0",
        has_corner_accents=True,
        has_shadow=True,
        icon_symbol="📒",
    ),

    # 4. EDITORIAL & SPECIAL OCCASIONS
    "magazine_vogue": FrameTemplate(
        id="magazine_vogue",
        name="Bìa Tạp Chí Thời Trang (Vogue Style)",
        category="Tạp Chí & Thời Trang",
        description="Thiết kế ấn phẩm thời trang quốc tế với tiêu đề sang trọng, số phát hành và mã vạch nghệ thuật.",
        default_border_ratio=0.02,
        default_mat_ratio=0.05,
        default_frame_color="#FFFFFF",
        default_mat_color="#FFFFFF",
        has_corner_accents=False,
        has_shadow=True,
        aspect_preset="3:4",
        supports_caption=True,
        default_caption="AESTHETIC • ISSUE NO. 10",
        icon_symbol="📰",
    ),
    "wedding_botanical": FrameTemplate(
        id="wedding_botanical",
        name="Hoa Cỏ & Nhẫn Cưới Tinh Tế",
        category="Tạp Chí & Thời Trang",
        description="Viền cành lá nguyệt quế và hoa nhã nhặn, màu champagne ánh vàng thích hợp cho ảnh cưới/lãng mạn.",
        default_border_ratio=0.04,
        default_mat_ratio=0.10,
        default_frame_color="#C5A059",
        default_mat_color="#FDFBF7",
        has_corner_accents=True,
        has_shadow=True,
        supports_caption=True,
        default_caption="Save The Date • Sweet Love",
        icon_symbol="🌿",
    ),
}


def get_categories() -> List[str]:
    """Get list of unique categories."""
    cats = []
    for t in TEMPLATES.values():
        if t.category not in cats:
            cats.append(t.category)
    return cats


def get_templates_by_category(category: str) -> List[FrameTemplate]:
    """Return all templates in a given category."""
    return [t for t in TEMPLATES.values() if t.category == category]
