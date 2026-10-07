"""
PhotoFrameFancy - High-Performance Frame Rendering Engine
Renders 14+ artistic and luxury photo frames with customizable matting,
borders, textures, typography, and drop shadows.
"""

import math
import os
from typing import Dict, Any, Tuple, Optional, List
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageFont

from core.filters import apply_filter
from core.templates import TEMPLATES, FrameTemplate


FONT_DIR = "C:/Windows/Fonts"

def get_font(name: str, size: int) -> ImageFont.FreeTypeFont:
    """Safely load font from Windows fonts with fallback."""
    font_path = os.path.join(FONT_DIR, name)
    try:
        if os.path.exists(font_path):
            return ImageFont.truetype(font_path, int(size))
    except Exception:
        pass
    try:
        # Fallback to Arial or default
        return ImageFont.truetype("arial.ttf", int(size))
    except Exception:
        return ImageFont.load_default()


def hex_to_rgb(hex_str: str) -> Tuple[int, int, int]:
    """Convert hex string (#RRGGBB) to (R, G, B)."""
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 3:
        hex_str = "".join([c * 2 for c in hex_str])
    if len(hex_str) != 6:
        return (255, 255, 255)
    return tuple(int(hex_str[i:i + 2], 16) for i in (0, 2, 4))


def hex_to_rgba(hex_str: str, alpha: int = 255) -> Tuple[int, int, int, int]:
    """Convert hex string to (R, G, B, A)."""
    r, g, b = hex_to_rgb(hex_str)
    return (r, g, b, alpha)


_SHADOW_CACHE: Dict[Tuple, Tuple[Image.Image, int]] = {}
_GOLD_BASE_CACHE: Dict[Tuple, Image.Image] = {}
_WOOD_FRAME_CACHE: Dict[Tuple, Image.Image] = {}
_KRAFT_BASE_CACHE: Dict[Tuple, Image.Image] = {}
_SLOT_IMAGE_CACHE: Dict[Tuple, Image.Image] = {}
_BASE_ORIENTED_FILTERED_CACHE: Dict[Tuple, Image.Image] = {}

def get_base_oriented_filtered_photo(
    image: Image.Image,
    rotation: int = 0,
    flip_h: bool = False,
    flip_v: bool = False,
    filter_name: str = "original"
) -> Image.Image:
    """Pre-computes orientation, flips, rotation, and color filter with LRU caching."""
    cache_key = (id(image), image.size, rotation, flip_h, flip_v, filter_name)
    if cache_key in _BASE_ORIENTED_FILTERED_CACHE:
        return _BASE_ORIENTED_FILTERED_CACHE[cache_key]

    img = ImageOps.exif_transpose(image)
    if img.mode != "RGB":
        img = img.convert("RGB")

    if flip_h:
        img = ImageOps.mirror(img)
    if flip_v:
        img = ImageOps.flip(img)
    if rotation in [90, 180, 270]:
        img = img.rotate(360 - rotation, expand=True)

    if filter_name and filter_name != "original":
        img = apply_filter(img, filter_name)

    if len(_BASE_ORIENTED_FILTERED_CACHE) > 20:
        _BASE_ORIENTED_FILTERED_CACHE.pop(next(iter(_BASE_ORIENTED_FILTERED_CACHE)))
    _BASE_ORIENTED_FILTERED_CACHE[cache_key] = img
    return img

def create_drop_shadow(
    width: int,
    height: int,
    offset_x: int = 0,
    offset_y: int = 15,
    blur_radius: int = 25,
    shadow_color: Tuple[int, int, int, int] = (0, 0, 0, 140),
    corner_radius: int = 0
) -> Tuple[Image.Image, int]:
    """Generate a realistic, soft multi-stage drop shadow with LRU memory caching."""
    cache_key = (width, height, offset_x, offset_y, blur_radius, shadow_color, corner_radius)
    if cache_key in _SHADOW_CACHE:
        return _SHADOW_CACHE[cache_key]

    pad = blur_radius * 2 + max(abs(offset_x), abs(offset_y)) + 20
    shadow_w = width + pad * 2
    shadow_h = height + pad * 2
    
    # Shadow mask
    mask = Image.new("L", (shadow_w, shadow_h), 0)
    draw = ImageDraw.Draw(mask)
    
    x0 = pad + offset_x
    y0 = pad + offset_y
    x1 = x0 + width
    y1 = y0 + height
    
    if corner_radius > 0:
        draw.rounded_rectangle([x0, y0, x1, y1], radius=corner_radius, fill=shadow_color[3])
    else:
        draw.rectangle([x0, y0, x1, y1], fill=shadow_color[3])
        
    # Fast BoxBlur is 2.5x faster than GaussianBlur and looks indistinguishably soft
    mask = mask.filter(ImageFilter.BoxBlur(max(1, int(blur_radius * 0.85))))
    
    # Create shadow RGBA image
    shadow_img = Image.new("RGBA", (shadow_w, shadow_h), (*shadow_color[:3], 0))
    shadow_img.putalpha(mask)

    if len(_SHADOW_CACHE) > 25:
        _SHADOW_CACHE.pop(next(iter(_SHADOW_CACHE)))
    _SHADOW_CACHE[cache_key] = (shadow_img, pad)
    return shadow_img, pad


def process_source_photo(
    image: Image.Image,
    aspect_preset: str = "original",
    zoom: float = 1.0,
    pan_x: float = 0.0,
    pan_y: float = 0.0,
    rotation: int = 0,
    flip_h: bool = False,
    flip_v: bool = False,
    filter_name: str = "original",
    target_dim: Optional[Tuple[int, int]] = None,
    is_preview: bool = False
) -> Image.Image:
    """
    Transforms the source photo: orientation, flip, rotate, crop/aspect ratio, zoom, pan, and filter.
    Uses cached oriented & filtered base image so pan/zoom operations are pure ultra-fast sub-millisecond crops.
    """
    img = get_base_oriented_filtered_photo(
        image,
        rotation=rotation,
        flip_h=flip_h,
        flip_v=flip_v,
        filter_name=filter_name
    )

    orig_w, orig_h = img.size

    # Target Aspect Ratio
    if aspect_preset == "1:1":
        target_ratio = 1.0
    elif aspect_preset == "4:5":
        target_ratio = 4.0 / 5.0
    elif aspect_preset == "3:4":
        target_ratio = 3.0 / 4.0
    elif aspect_preset == "9:16":
        target_ratio = 9.0 / 16.0
    elif aspect_preset == "16:9":
        target_ratio = 16.0 / 9.0
    elif aspect_preset == "3:2":
        target_ratio = 3.0 / 2.0
    else:  # "original"
        if target_dim:
            target_ratio = target_dim[0] / max(1, target_dim[1])
        else:
            target_ratio = orig_w / max(1, orig_h)

    current_ratio = orig_w / max(1, orig_h)

    # Base crop box to match aspect ratio
    if current_ratio > target_ratio:
        # Source is wider, crop sides
        crop_h = orig_h
        crop_w = int(orig_h * target_ratio)
    else:
        # Source is taller, crop top/bottom
        crop_w = orig_w
        crop_h = int(orig_w / target_ratio)

    # Apply Zoom (1.0 to 3.0)
    zoom = max(1.0, min(3.0, zoom))
    final_w = crop_w / zoom
    final_h = crop_h / zoom

    # Available pan ranges in original coordinate space
    max_pan_x = max(0.0, (orig_w - final_w) / 2.0)
    max_pan_y = max(0.0, (orig_h - final_h) / 2.0)

    center_x = (orig_w / 2.0) + pan_x * max_pan_x
    center_y = (orig_h / 2.0) + pan_y * max_pan_y

    x0 = max(0.0, min(orig_w - final_w, center_x - final_w / 2.0))
    y0 = max(0.0, min(orig_h - final_h, center_y - final_h / 2.0))
    x1 = x0 + final_w
    y1 = y0 + final_h

    cropped = img.crop((int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))))

    if target_dim:
        resample_mode = Image.Resampling.BILINEAR if is_preview else Image.Resampling.LANCZOS
        cropped = cropped.resize(target_dim, resample_mode)

    return cropped


# -------------------------------------------------------------
# TEMPLATE RENDERERS
# -------------------------------------------------------------

def render_gold_baroque(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Royal Gold Baroque Frame with beveled metallic trim and ornate corners."""
    pw, ph = photo.size
    border = int(min(pw, ph) * p.get("border_ratio", 0.08))
    border = max(24, border)
    mat = int(min(pw, ph) * p.get("mat_ratio", 0.06))
    mat = max(16, mat)
    
    frame_color = p.get("frame_color", "#D4AF37")
    mat_color = p.get("mat_color", "#18181B")
    
    total_w = pw + (border + mat) * 2
    total_h = ph + (border + mat) * 2
    
    canvas = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    
    # 1. Outer Gold Bevel
    gold_rgb = hex_to_rgb(frame_color)
    gold_key = (total_w, total_h, gold_rgb, border)
    if gold_key in _GOLD_BASE_CACHE:
        gold_base = _GOLD_BASE_CACHE[gold_key].copy()
    else:
        gold_base = Image.new("RGBA", (total_w, total_h), (*gold_rgb, 255))
        arr = np.array(gold_base, dtype=np.int16)
        x = np.linspace(-1, 1, total_w)
        y = np.linspace(-1, 1, total_h)
        sheen = (np.sin(x[None, :] * 3 + y[:, None] * 2) * 22).astype(np.int16)
        for c in range(3):
            arr[:, :, c] = np.clip(arr[:, :, c] + sheen, 0, 255)
        gold_base = Image.fromarray(arr.astype(np.uint8))
        
        draw = ImageDraw.Draw(gold_base)
        steps = 4
        for i in range(steps):
            inset = int(border * (i / steps))
            draw.rectangle([inset, inset, total_w - inset - 1, total_h - inset - 1], outline=(255, 235, 150, 180), width=1)
            draw.rectangle([inset + 1, inset + 1, total_w - inset - 2, total_h - inset - 2], outline=(90, 70, 20, 140), width=1)
            
        if len(_GOLD_BASE_CACHE) > 10:
            _GOLD_BASE_CACHE.pop(next(iter(_GOLD_BASE_CACHE)))
        _GOLD_BASE_CACHE[gold_key] = gold_base.copy()
    
    canvas.paste(gold_base, (0, 0))
    
    # 2. Matting (inner passe-partout)
    mat_x0 = border
    mat_y0 = border
    mat_x1 = total_w - border
    mat_y1 = total_h - border
    
    mat_rgb = hex_to_rgb(mat_color)
    draw_canvas = ImageDraw.Draw(canvas)
    draw_canvas.rectangle([mat_x0, mat_y0, mat_x1, mat_y1], fill=(*mat_rgb, 255))
    
    # Inner gold fillet lip (dải chỉ vàng trong)
    fillet_inset = border + mat - 4
    draw_canvas.rectangle([fillet_inset, fillet_inset, total_w - fillet_inset, total_h - fillet_inset], outline=(*gold_rgb, 255), width=3)
    
    # 3. Paste Photo
    photo_x = border + mat
    photo_y = border + mat
    canvas.paste(photo, (photo_x, photo_y))
    
    # Inner shadow on photo
    inner_shadow = ImageDraw.Draw(canvas)
    inner_shadow.rectangle([photo_x, photo_y, photo_x + pw - 1, photo_y + ph - 1], outline=(0, 0, 0, 120), width=2)
    
    # 4. Corner Ornaments (Baroque Filigree)
    corner_size = int(border * 1.5)
    for cx, cy, flip_x, flip_y in [
        (border, border, False, False),
        (total_w - border, border, True, False),
        (border, total_h - border, False, True),
        (total_w - border, total_h - border, True, True),
    ]:
        draw_canvas.arc([cx - corner_size, cy - corner_size, cx + corner_size, cy + corner_size], 0, 360, fill=(255, 230, 130, 160), width=2)
        draw_canvas.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 240, 180, 255))
    
    # Drop shadow if requested
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=16, blur_radius=22)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(canvas, (pad, pad), canvas)
        res.info["inner_rect"] = (photo_x + pad, photo_y + pad, pw, ph)
        return res
        
    canvas.info["inner_rect"] = (photo_x, photo_y, pw, ph)
    return canvas


def render_dark_walnut(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Luxury Walnut Wood frame with procedural organic woodgrain & gold inlay."""
    pw, ph = photo.size
    border = int(min(pw, ph) * p.get("border_ratio", 0.08))
    border = max(24, border)
    mat = int(min(pw, ph) * p.get("mat_ratio", 0.07))
    mat = max(16, mat)
    
    frame_color = p.get("frame_color", "#3D2314")
    mat_color = p.get("mat_color", "#F4EFEA")
    
    total_w = pw + (border + mat) * 2
    total_h = ph + (border + mat) * 2
    
    wood_key = (total_w, total_h, frame_color, border)
    if wood_key in _WOOD_FRAME_CACHE:
        wood_frame = _WOOD_FRAME_CACHE[wood_key].copy()
    else:
        base_rgb = hex_to_rgb(frame_color)
        y_coords = np.linspace(0, 1, total_h)[:, None]
        x_coords = np.linspace(0, 1, total_w)[None, :]
        grain = (np.sin(y_coords * 90 + np.sin(x_coords * 12) * 5) * 16).astype(np.int16)
        
        wood_arr = np.zeros((total_h, total_w, 4), dtype=np.uint8)
        for c in range(3):
            col_c = np.clip(base_rgb[c] + grain, 0, 255).astype(np.uint8)
            wood_arr[:, :, c] = col_c
        wood_arr[:, :, 3] = 255
        wood_frame = Image.fromarray(wood_arr)
        
        draw = ImageDraw.Draw(wood_frame)
        # Miter corner joint lines (vát 45 độ)
        draw.line([0, 0, border, border], fill=(20, 10, 5, 200), width=2)
        draw.line([total_w, 0, total_w - border, border], fill=(20, 10, 5, 200), width=2)
        draw.line([0, total_h, border, total_h - border], fill=(20, 10, 5, 200), width=2)
        draw.line([total_w, total_h, total_w - border, total_h - border], fill=(20, 10, 5, 200), width=2)
        
        if len(_WOOD_FRAME_CACHE) > 10:
            _WOOD_FRAME_CACHE.pop(next(iter(_WOOD_FRAME_CACHE)))
        _WOOD_FRAME_CACHE[wood_key] = wood_frame.copy()
    
    # Mat board
    draw = ImageDraw.Draw(wood_frame)
    mat_rgb = hex_to_rgb(mat_color)
    draw.rectangle([border, border, total_w - border, total_h - border], fill=(*mat_rgb, 255))
    
    # Gold pinstripe inlay on mat
    gold_inlay = (212, 175, 55, 255)
    inlay_dist = border + 10
    draw.rectangle([inlay_dist, inlay_dist, total_w - inlay_dist, total_h - inlay_dist], outline=gold_inlay, width=2)
    
    # Paste photo
    photo_x = border + mat
    photo_y = border + mat
    wood_frame.paste(photo, (photo_x, photo_y))
    
    # Beveled inner mat cutout shadow
    draw.rectangle([photo_x, photo_y, photo_x + pw - 1, photo_y + ph - 1], outline=(50, 40, 30, 130), width=2)
    
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=18, blur_radius=25)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(wood_frame, (pad, pad), wood_frame)
        res.info["inner_rect"] = (photo_x + pad, photo_y + pad, pw, ph)
        return res
        
    wood_frame.info["inner_rect"] = (photo_x, photo_y, pw, ph)
    return wood_frame


def render_museum_gallery(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Museum Gallery with expansive beveled archival mat board & caption label."""
    pw, ph = photo.size
    border = int(min(pw, ph) * p.get("border_ratio", 0.035))
    border = max(14, border)
    mat = int(min(pw, ph) * p.get("mat_ratio", 0.12))
    mat = max(28, mat)
    
    caption = p.get("caption_text", "FINE ART GALLERY")
    has_caption = bool(caption.strip())
    bottom_extra = int(mat * 0.6) if has_caption else 0
    
    frame_color = p.get("frame_color", "#151515")
    mat_color = p.get("mat_color", "#FAF8F5")
    
    total_w = pw + (border + mat) * 2
    total_h = ph + (border + mat) * 2 + bottom_extra
    
    canvas = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    # Outer frame
    f_rgb = hex_to_rgb(frame_color)
    draw.rectangle([0, 0, total_w, total_h], fill=(*f_rgb, 255))
    
    # Mat board
    mat_rgb = hex_to_rgb(mat_color)
    draw.rectangle([border, border, total_w - border, total_h - border], fill=(*mat_rgb, 255))
    
    # Subtle paper texture on mat board
    arr_mat = np.random.normal(0, 1.5, (total_h - border * 2, total_w - border * 2)).astype(np.int16)
    
    # Paste photo
    photo_x = border + mat
    photo_y = border + mat
    canvas.paste(photo, (photo_x, photo_y))
    
    # Beveled edge shadow on photo cutout
    draw.rectangle([photo_x - 1, photo_y - 1, photo_x + pw, photo_y + ph], outline=(180, 175, 170, 200), width=1)
    draw.line([photo_x, photo_y + ph, photo_x + pw, photo_y + ph], fill=(80, 75, 70, 160), width=2)
    draw.line([photo_x + pw, photo_y, photo_x + pw, photo_y + ph], fill=(80, 75, 70, 160), width=2)
    
    # Gallery typography caption
    if has_caption:
        f_size = max(13, int(total_w * 0.024))
        font = get_font("georgia.ttf", f_size)
        text_bbox = draw.textbbox((0, 0), caption, font=font)
        tw = text_bbox[2] - text_bbox[0]
        tx = (total_w - tw) // 2
        ty = photo_y + ph + (total_h - border - (photo_y + ph) - (text_bbox[3] - text_bbox[1])) // 2
        draw.text((tx, ty), caption, fill=(60, 60, 65, 230), font=font)
        # Small divider rule
        rule_w = int(tw * 0.7)
        rx = (total_w - rule_w) // 2
        draw.line([rx, ty - 8, rx + rule_w, ty - 8], fill=(190, 185, 180, 200), width=1)
    
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=15, blur_radius=22)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(canvas, (pad, pad), canvas)
        res.info["inner_rect"] = (photo_x + pad, photo_y + pad, pw, ph)
        return res
        
    canvas.info["inner_rect"] = (photo_x, photo_y, pw, ph)
    return canvas


def render_modern_floating(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Minimalist 3D Floating Canvas with realistic ambient occlusion & multi-stage shadow."""
    pw, ph = photo.size
    margin = int(min(pw, ph) * p.get("mat_ratio", 0.10))
    margin = max(30, margin)
    bg_color = hex_to_rgb(p.get("mat_color", "#ECEFF1"))
    
    total_w = pw + margin * 2
    total_h = ph + margin * 2
    
    bg = Image.new("RGBA", (total_w, total_h), (*bg_color, 255))
    
    # Shadow for floating photo
    radius = p.get("corner_radius", 8)
    shadow, pad = create_drop_shadow(pw, ph, offset_y=18, blur_radius=30, shadow_color=(0, 0, 0, 130), corner_radius=radius)
    
    # Combine
    canvas = Image.new("RGBA", (total_w, total_h), (*bg_color, 255))
    
    # Shadow offset position
    sx = margin - pad
    sy = margin - pad + 5
    canvas.paste(shadow, (sx, sy), shadow)
    
    # Rounded photo if radius > 0
    if radius > 0:
        mask = Image.new("L", (pw, ph), 0)
        mdraw = ImageDraw.Draw(mask)
        mdraw.rounded_rectangle([0, 0, pw, ph], radius=radius, fill=255)
        canvas.paste(photo, (margin, margin), mask)
    else:
        canvas.paste(photo, (margin, margin))
        
    canvas.info["inner_rect"] = (margin, margin, pw, ph)
    return canvas


def render_nordic_clean(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Nordic Scandinavian clean light-oak wood frame with rounded corners."""
    pw, ph = photo.size
    border = int(min(pw, ph) * p.get("border_ratio", 0.045))
    border = max(18, border)
    mat = int(min(pw, ph) * p.get("mat_ratio", 0.07))
    mat = max(20, mat)
    
    total_w = pw + (border + mat) * 2
    total_h = ph + (border + mat) * 2
    
    frame_color = hex_to_rgb(p.get("frame_color", "#E6D7C3"))
    mat_color = hex_to_rgb(p.get("mat_color", "#FFFFFF"))
    
    canvas = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    corner_r = 18
    # Outer frame
    draw.rounded_rectangle([0, 0, total_w, total_h], radius=corner_r, fill=(*frame_color, 255))
    # Mat board
    draw.rounded_rectangle([border, border, total_w - border, total_h - border], radius=corner_r - 4, fill=(*mat_color, 255))
    
    # Paste photo
    canvas.paste(photo, (border + mat, border + mat))
    
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=14, blur_radius=20, corner_radius=corner_r)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(canvas, (pad, pad), canvas)
        res.info["inner_rect"] = (border + mat + pad, border + mat + pad, pw, ph)
        return res
        
    canvas.info["inner_rect"] = (border + mat, border + mat, pw, ph)
    return canvas


def render_double_pinstripe(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Luxury double pinstripe framing on archival museum cream paper."""
    pw, ph = photo.size
    mat = int(min(pw, ph) * p.get("mat_ratio", 0.11))
    mat = max(32, mat)
    
    frame_rgb = hex_to_rgb(p.get("frame_color", "#1F1F24"))
    mat_rgb = hex_to_rgb(p.get("mat_color", "#FAF9F6"))
    
    total_w = pw + mat * 2
    total_h = ph + mat * 2
    
    canvas = Image.new("RGBA", (total_w, total_h), (*mat_rgb, 255))
    draw = ImageDraw.Draw(canvas)
    
    # Outer edge line
    draw.rectangle([8, 8, total_w - 9, total_h - 9], outline=(*frame_rgb, 255), width=2)
    # Inner pinstripe line
    stripe_dist = int(mat * 0.45)
    draw.rectangle([stripe_dist, stripe_dist, total_w - stripe_dist, total_h - stripe_dist], outline=(*frame_rgb, 220), width=1)
    
    # Paste photo
    canvas.paste(photo, (mat, mat))
    # Soft inner border around photo
    draw.rectangle([mat - 1, mat - 1, mat + pw, mat + ph], outline=(180, 180, 180, 180), width=1)
    
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=16, blur_radius=24)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(canvas, (pad, pad), canvas)
        res.info["inner_rect"] = (mat + pad, mat + pad, pw, ph)
        return res
        
    canvas.info["inner_rect"] = (mat, mat, pw, ph)
    return canvas


def render_neon_cyberpunk(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Neon Cyberpunk glowing dual-gradient frame with electric aura."""
    pw, ph = photo.size
    margin = int(min(pw, ph) * 0.08)
    margin = max(35, margin)
    
    total_w = pw + margin * 2
    total_h = ph + margin * 2
    
    canvas = Image.new("RGBA", (total_w, total_h), (11, 12, 16, 255))
    
    # Neon Glow layer
    glow_mask = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow_mask)
    
    neon1 = (0, 240, 255)    # Cyan
    neon2 = (255, 0, 128)    # Neon Pink / Magenta
    
    rect_box = [margin - 8, margin - 8, total_w - margin + 8, total_h - margin + 8]
    # Draw multiple glowing outlines
    for blur_step, alpha in [(16, 60), (10, 100), (5, 180), (2, 255)]:
        temp = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
        tdraw = ImageDraw.Draw(temp)
        tdraw.rounded_rectangle(rect_box, radius=12, outline=(*neon1, alpha), width=3)
        temp = temp.filter(ImageFilter.GaussianBlur(blur_step // 2))
        glow_mask = Image.alpha_composite(glow_mask, temp)
        
    canvas = Image.alpha_composite(canvas, glow_mask)
    
    # Paste photo
    canvas.paste(photo, (margin, margin))
    
    # Sharp inner neon border
    cdraw = ImageDraw.Draw(canvas)
    cdraw.rectangle([margin, margin, margin + pw, margin + ph], outline=(*neon2, 220), width=2)
    canvas.info["inner_rect"] = (margin, margin, pw, ph)
    return canvas


def render_polaroid_classic(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Classic Polaroid instant film frame with handwriting caption & texture."""
    pw, ph = photo.size
    side_margin = int(pw * 0.08)
    side_margin = max(24, side_margin)
    top_margin = side_margin
    bottom_margin = int(ph * 0.28)
    bottom_margin = max(70, bottom_margin)
    
    total_w = pw + side_margin * 2
    total_h = ph + top_margin + bottom_margin
    
    # Polaroid paper off-white
    paper_rgb = hex_to_rgb(p.get("mat_color", "#FBFBFA"))
    polaroid = Image.new("RGBA", (total_w, total_h), (*paper_rgb, 255))
    draw = ImageDraw.Draw(polaroid)
    
    # Subtle gloss sheen across paper
    arr = np.array(polaroid, dtype=np.int16)
    noise = np.random.normal(0, 1.2, (total_h, total_w)).astype(np.int16)
    for c in range(3):
        arr[:, :, c] = np.clip(arr[:, :, c] + noise, 0, 255)
    polaroid = Image.fromarray(arr.astype(np.uint8))
    draw = ImageDraw.Draw(polaroid)
    
    # Paste photo
    polaroid.paste(photo, (side_margin, top_margin))
    
    # Slight vignette/border around photo to simulate instant chemical pocket
    draw.rectangle([side_margin - 1, top_margin - 1, side_margin + pw, top_margin + ph], outline=(200, 200, 195, 200), width=1)
    
    # Handwritten caption at bottom
    caption = p.get("caption_text", "Memories • Forever")
    if caption.strip():
        f_size = max(16, int(total_w * 0.045))
        font = get_font("segoesc.ttf", f_size)  # Segoe Script handwriting font
        text_bbox = draw.textbbox((0, 0), caption, font=font)
        tw = text_bbox[2] - text_bbox[0]
        tx = (total_w - tw) // 2
        ty = top_margin + ph + (bottom_margin - (text_bbox[3] - text_bbox[1])) // 2
        draw.text((tx, ty), caption, fill=(45, 45, 50, 220), font=font)
        
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=16, blur_radius=22)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(polaroid, (pad, pad), polaroid)
        res.info["inner_rect"] = (side_margin + pad, top_margin + pad, pw, ph)
        return res
        
    polaroid.info["inner_rect"] = (side_margin, top_margin, pw, ph)
    return polaroid


def render_film_35mm(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """35mm Analog Film Negative frame with sprockets and Kodak/Fuji marks."""
    pw, ph = photo.size
    sprocket_band = int(ph * 0.16)
    sprocket_band = max(36, sprocket_band)
    side_margin = int(pw * 0.05)
    side_margin = max(20, side_margin)
    
    total_w = pw + side_margin * 2
    total_h = ph + sprocket_band * 2
    
    film = Image.new("RGBA", (total_w, total_h), (18, 18, 20, 255))
    draw = ImageDraw.Draw(film)
    
    # Sprocket holes along top and bottom
    sprocket_w = int(sprocket_band * 0.38)
    sprocket_h = int(sprocket_band * 0.48)
    spacing = int(sprocket_w * 1.8)
    
    for y_pos in [int(sprocket_band * 0.25), total_h - int(sprocket_band * 0.75)]:
        x = side_margin // 2
        while x < total_w:
            draw.rounded_rectangle([x, y_pos, x + sprocket_w, y_pos + sprocket_h], radius=4, fill=(0, 0, 0, 255), outline=(50, 50, 55, 180), width=1)
            x += spacing
            
    # Film manufacturer markings (vintage orange / gold text)
    orange_gold = (235, 140, 30, 240)
    mono_font = get_font("consola.ttf", max(11, int(sprocket_band * 0.24)))
    caption = p.get("caption_text", "KODAK GOLD 200  ▶  24A")
    draw.text((side_margin, sprocket_band - int(sprocket_band * 0.28)), caption, fill=orange_gold, font=mono_font)
    draw.text((total_w - side_margin - 120, total_h - int(sprocket_band * 0.26)), "SAFETY FILM 35", fill=orange_gold, font=mono_font)
    
    # Paste photo
    film.paste(photo, (side_margin, sprocket_band))
    film.info["inner_rect"] = (side_margin, sprocket_band, pw, ph)
    return film


def render_vintage_stamp(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Postage Stamp with scalloped perforated edges and cancellation postmark."""
    pw, ph = photo.size
    margin = int(min(pw, ph) * 0.09)
    margin = max(30, margin)
    
    total_w = pw + margin * 2
    total_h = ph + margin * 2
    
    stamp_base = Image.new("RGBA", (total_w, total_h), (250, 246, 238, 255))
    
    # Create scalloped mask for perforated edges
    mask = Image.new("L", (total_w, total_h), 255)
    mdraw = ImageDraw.Draw(mask)
    
    hole_radius = int(margin * 0.18)
    hole_radius = max(5, hole_radius)
    spacing = hole_radius * 3
    
    # Top & Bottom perforations
    for x in range(hole_radius, total_w, spacing):
        mdraw.ellipse([x - hole_radius, -hole_radius, x + hole_radius, hole_radius], fill=0)
        mdraw.ellipse([x - hole_radius, total_h - hole_radius, x + hole_radius, total_h + hole_radius], fill=0)
        
    # Left & Right perforations
    for y in range(hole_radius, total_h, spacing):
        mdraw.ellipse([-hole_radius, y - hole_radius, hole_radius, y + hole_radius], fill=0)
        mdraw.ellipse([total_w - hole_radius, y - hole_radius, total_w + hole_radius, y + hole_radius], fill=0)
        
    stamp_base.putalpha(mask)
    
    # Inner photo
    stamp_base.paste(photo, (margin, margin))
    
    # Decorative inner pinstripe
    draw = ImageDraw.Draw(stamp_base)
    draw.rectangle([margin - 4, margin - 4, margin + pw + 3, margin + ph + 3], outline=(190, 175, 160, 220), width=1)
    
    # Vintage Postal Stamp Mark (Dấu bưu điện tròn)
    stamp_r = int(min(pw, ph) * 0.22)
    scx = margin + pw - stamp_r // 2
    scy = margin + ph - stamp_r // 2
    draw.ellipse([scx - stamp_r, scy - stamp_r, scx + stamp_r, scy + stamp_r], outline=(150, 50, 50, 160), width=2)
    draw.ellipse([scx - stamp_r + 6, scy - stamp_r + 6, scx + stamp_r - 6, scy + stamp_r - 6], outline=(150, 50, 50, 120), width=1)
    
    # Wavy cancel lines
    for i in range(-2, 3):
        wy = scy + i * 10
        draw.line([scx - stamp_r - 30, wy, scx + stamp_r + 30, wy], fill=(150, 50, 50, 130), width=1)
        
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=12, blur_radius=18)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(stamp_base, (pad, pad), stamp_base)
        res.info["inner_rect"] = (margin + pad, margin + pad, pw, ph)
        return res
        
    stamp_base.info["inner_rect"] = (margin, margin, pw, ph)
    return stamp_base


def render_scrapbook_kraft(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Scrapbook with textured craft paper backing & 4 washi tape stickers."""
    pw, ph = photo.size
    margin = int(min(pw, ph) * 0.12)
    margin = max(35, margin)
    
    total_w = pw + margin * 2
    total_h = ph + margin * 2
    
    # Kraft Paper Background (cached noise texture)
    kraft_key = (total_w, total_h)
    if kraft_key in _KRAFT_BASE_CACHE:
        kraft_base = _KRAFT_BASE_CACHE[kraft_key].copy()
    else:
        kraft_base = Image.new("RGBA", (total_w, total_h), (218, 195, 166, 255))
        arr = np.array(kraft_base, dtype=np.int16)
        noise = np.random.normal(0, 4.0, (total_h, total_w)).astype(np.int16)
        for c in range(3):
            arr[:, :, c] = np.clip(arr[:, :, c] + noise, 0, 255)
        kraft_base = Image.fromarray(arr.astype(np.uint8))
        if len(_KRAFT_BASE_CACHE) > 10:
            _KRAFT_BASE_CACHE.pop(next(iter(_KRAFT_BASE_CACHE)))
        _KRAFT_BASE_CACHE[kraft_key] = kraft_base.copy()
    
    # Photo with small drop shadow on scrapbook
    pshadow, ppad = create_drop_shadow(pw, ph, offset_y=8, blur_radius=12, shadow_color=(0, 0, 0, 90))
    kraft_base.paste(pshadow, (margin - ppad, margin - ppad + 2), pshadow)
    kraft_base.paste(photo, (margin, margin))
    
    # 4 Washi Tapes across corners
    draw = ImageDraw.Draw(kraft_base)
    tape_w = int(margin * 0.9)
    tape_h = int(margin * 0.35)
    tape_col = (230, 130, 110, 200) # Soft pastel terracotta tape
    
    # Top-Left tape
    draw.polygon([(margin - 15, margin + 20), (margin + 20, margin - 15), (margin + 35, margin - 5), (margin, margin + 30)], fill=tape_col)
    # Top-Right tape
    draw.polygon([(total_w - margin - 20, margin - 15), (total_w - margin + 15, margin + 20), (total_w - margin, margin + 30), (total_w - margin - 35, margin - 5)], fill=tape_col)
    # Bottom-Left tape
    draw.polygon([(margin - 15, total_h - margin - 20), (margin + 20, total_h - margin + 15), (margin + 5, total_h - margin + 30), (margin - 30, total_h - margin - 5)], fill=tape_col)
    # Bottom-Right tape
    draw.polygon([(total_w - margin + 15, total_h - margin - 20), (total_w - margin - 20, total_h - margin + 15), (total_w - margin - 35, total_h - margin), (total_w - margin, total_h - margin - 35)], fill=tape_col)
    
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=16, blur_radius=22)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(kraft_base, (pad, pad), kraft_base)
        res.info["inner_rect"] = (margin + pad, margin + pad, pw, ph)
        return res
        
    kraft_base.info["inner_rect"] = (margin, margin, pw, ph)
    return kraft_base


def render_magazine_vogue(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """High-Fashion Magazine Cover with editorial typography and barcode."""
    pw, ph = photo.size
    margin = int(pw * 0.04)
    margin = max(16, margin)
    
    total_w = pw + margin * 2
    total_h = ph + margin * 2
    
    canvas = Image.new("RGBA", (total_w, total_h), (255, 255, 255, 255))
    canvas.paste(photo, (margin, margin))
    draw = ImageDraw.Draw(canvas)
    
    # 1. Bold Editorial Header across top: "VOGUE" or custom caption
    header_text = p.get("caption_text", "AESTHETIC")
    if not header_text.strip():
        header_text = "VOGUE"
        
    f_size = max(28, int(total_w * 0.12))
    font = get_font("times.ttf", f_size)
    
    # Draw header with drop shadow for legibility over any photo
    tx = (total_w - int(draw.textlength(header_text, font=font))) // 2
    ty = margin + int(f_size * 0.15)
    draw.text((tx + 2, ty + 2), header_text, fill=(0, 0, 0, 180), font=font)
    draw.text((tx, ty), header_text, fill=(255, 255, 255, 245), font=font)
    
    # 2. Issue subtitle line
    sub_font = get_font("arial.ttf", max(11, int(f_size * 0.2)))
    sub_text = "SPECIAL EDITION • AUTUMN / WINTER"
    stx = (total_w - int(draw.textlength(sub_text, font=sub_font))) // 2
    draw.text((stx + 1, ty + f_size + 4), sub_text, fill=(0, 0, 0, 160), font=sub_font)
    draw.text((stx, ty + f_size + 3), sub_text, fill=(255, 255, 255, 230), font=sub_font)
    
    # 3. Barcode graphic in bottom corner
    bc_w, bc_h = int(total_w * 0.16), int(total_w * 0.08)
    bx0 = total_w - margin - bc_w - 15
    by0 = total_h - margin - bc_h - 15
    draw.rectangle([bx0, by0, bx0 + bc_w, by0 + bc_h], fill=(255, 255, 255, 240))
    # Bar lines
    cur_x = bx0 + 6
    while cur_x < bx0 + bc_w - 6:
        bar_t = np.random.choice([1, 2, 3])
        draw.line([cur_x, by0 + 4, cur_x, by0 + bc_h - 10], fill=(0, 0, 0, 230), width=bar_t)
        cur_x += bar_t + np.random.choice([1, 2, 4])
        
    # Thin outer framing border
    draw.rectangle([margin // 2, margin // 2, total_w - margin // 2, total_h - margin // 2], outline=(255, 255, 255, 200), width=2)
    canvas.info["inner_rect"] = (margin, margin, pw, ph)
    return canvas


def render_wedding_botanical(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Romantic Wedding & Botanical frame with gold/olive leaves & champagne mat."""
    pw, ph = photo.size
    mat = int(min(pw, ph) * 0.10)
    mat = max(32, mat)
    
    total_w = pw + mat * 2
    total_h = ph + mat * 2
    
    canvas = Image.new("RGBA", (total_w, total_h), (253, 251, 247, 255))
    draw = ImageDraw.Draw(canvas)
    
    # Inner gold border
    gold_rgb = hex_to_rgb(p.get("frame_color", "#C5A059"))
    draw.rectangle([mat - 8, mat - 8, total_w - mat + 7, total_h - mat + 7], outline=(*gold_rgb, 200), width=1)
    draw.rectangle([mat - 14, mat - 14, total_w - mat + 13, total_h - mat + 13], outline=(*gold_rgb, 120), width=1)
    
    # Paste photo
    canvas.paste(photo, (mat, mat))
    
    # Botanical laurel leaf ornaments at 4 corners
    leaf_color = (130, 150, 110, 220)
    c_rad = int(mat * 0.7)
    for cx, cy in [(mat, mat), (total_w - mat, mat), (mat, total_h - mat), (total_w - mat, total_h - mat)]:
        # Draw delicate floral arc
        draw.arc([cx - c_rad, cy - c_rad, cx + c_rad, cy + c_rad], 0, 360, fill=leaf_color, width=2)
        draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(*gold_rgb, 255))
        
    caption = p.get("caption_text", "Save The Date")
    if caption.strip():
        f_size = max(14, int(total_w * 0.03))
        font = get_font("georgia.ttf", f_size)
        tw = int(draw.textlength(caption, font=font))
        tx = (total_w - tw) // 2
        ty = total_h - mat + (mat - f_size) // 2
        draw.text((tx, ty), caption, fill=(90, 80, 70, 230), font=font)
        
    if p.get("has_shadow", True):
        shadow, pad = create_drop_shadow(total_w, total_h, offset_y=16, blur_radius=22)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(canvas, (pad, pad), canvas)
        res.info["inner_rect"] = (mat + pad, mat + pad, pw, ph)
        return res
        
    canvas.info["inner_rect"] = (mat, mat, pw, ph)
    return canvas


def render_minimal_clean(photo: Image.Image, p: Dict[str, Any]) -> Image.Image:
    """Clean borderless presentation with optional soft drop shadow."""
    pw, ph = photo.size
    if p.get("has_shadow", False):
        shadow, pad = create_drop_shadow(pw, ph, offset_y=12, blur_radius=18)
        res = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
        res.paste(shadow, (0, 0), shadow)
        res.paste(photo, (pad, pad), photo if photo.mode == "RGBA" else None)
        res.info["inner_rect"] = (pad, pad, pw, ph)
        return res
    photo.info["inner_rect"] = (0, 0, pw, ph)
    return photo


# Template dispatch map
RENDER_DISPATCH = {
    "minimal_clean": render_minimal_clean,
    "gold_baroque": render_gold_baroque,
    "dark_walnut": render_dark_walnut,
    "antique_bronze": render_gold_baroque, # specialized with bronze tone
    "museum_gallery": render_museum_gallery,
    "modern_floating": render_modern_floating,
    "nordic_clean": render_nordic_clean,
    "double_pinstripe": render_double_pinstripe,
    "neon_cyberpunk": render_neon_cyberpunk,
    "polaroid_classic": render_polaroid_classic,
    "film_35mm": render_film_35mm,
    "vintage_stamp": render_vintage_stamp,
    "scrapbook_kraft": render_scrapbook_kraft,
    "magazine_vogue": render_magazine_vogue,
    "wedding_botanical": render_wedding_botanical,
}


def render_framed_photo(
    image: Image.Image,
    template_id: str,
    params: Dict[str, Any],
    max_dimension: Optional[int] = None
) -> Image.Image:
    """
    Main entry point for rendering.
    Takes a raw PIL Image, applies transformations and template framing,
    and returns the final composite PIL Image.
    """
    tmpl = TEMPLATES.get(template_id, TEMPLATES["gold_baroque"])
    
    # Merge template defaults with user params
    merged_params = {
        "border_ratio": params.get("border_ratio", tmpl.default_border_ratio),
        "mat_ratio": params.get("mat_ratio", tmpl.default_mat_ratio),
        "frame_color": params.get("frame_color", tmpl.default_frame_color),
        "mat_color": params.get("mat_color", tmpl.default_mat_color),
        "has_shadow": params.get("has_shadow", tmpl.has_shadow),
        "caption_text": params.get("caption_text", tmpl.default_caption),
        "corner_radius": params.get("corner_radius", 0),
    }
    
    aspect_preset = params.get("aspect_preset", tmpl.aspect_preset)

    slot_transforms = params.get("slot_transforms", {})
    slot_0 = slot_transforms.get(0, {}) if slot_transforms else {}

    zoom = params.get("zoom", slot_0.get("zoom", 1.0))
    pan_x = params.get("pan_x", slot_0.get("pan_x", 0.0))
    pan_y = params.get("pan_y", slot_0.get("pan_y", 0.0))
    rotation = params.get("rotation", slot_0.get("rotation", 0))
    flip_h = params.get("flip_h", slot_0.get("flip_h", False))
    flip_v = params.get("flip_v", slot_0.get("flip_v", False))
    filter_name = params.get("filter_name", "original")

    # If downscaling for preview
    work_img = image
    if max_dimension is not None:
        w, h = work_img.size
        scale = max_dimension / max(w, h)
        if scale < 1.0:
            new_w = max(10, int(w * scale))
            new_h = max(10, int(h * scale))
            work_img = work_img.resize((new_w, new_h), Image.Resampling.BILINEAR)

    # Process source photo
    is_preview_render = params.get("is_preview", False)
    processed = process_source_photo(
        work_img,
        aspect_preset=aspect_preset,
        zoom=zoom,
        pan_x=pan_x,
        pan_y=pan_y,
        rotation=rotation,
        flip_h=flip_h,
        flip_v=flip_v,
        filter_name=filter_name,
        is_preview=is_preview_render
    )

    # Render template
    renderer = RENDER_DISPATCH.get(template_id, render_gold_baroque)
    result = renderer(processed, merged_params)

    # Compute normalized slot rect if not already set by collage
    if "slot_rects" not in result.info:
        inner_x, inner_y, ipw, iph = result.info.get("inner_rect", (0, 0, result.size[0], result.size[1]))
        fw, fh = result.size
        result.info["slot_rects"] = [(inner_x / fw, inner_y / fh, (inner_x + ipw) / fw, (inner_y + iph) / fh)]

    return result


def render_collage_board(
    images: List[Image.Image],
    layout_id: str,
    params: Dict[str, Any],
    max_dimension: Optional[int] = 1200
) -> Image.Image:
    """
    Renders a composite collage grid board from a list of images according to a CollageLayout.
    """
    from core.collage_layouts import COLLAGE_LAYOUTS
    layout = COLLAGE_LAYOUTS.get(layout_id, list(COLLAGE_LAYOUTS.values())[0])

    asp_preset = params.get("aspect_preset", layout.aspect_preset)
    if asp_preset == "16:9":
        aspect_w, aspect_h = 16, 9
    elif asp_preset == "4:5":
        aspect_w, aspect_h = 4, 5
    elif asp_preset == "9:16":
        aspect_w, aspect_h = 9, 16
    elif asp_preset == "3:4":
        aspect_w, aspect_h = 3, 4
    elif asp_preset == "3:2":
        aspect_w, aspect_h = 3, 2
    else:  # "1:1"
        aspect_w, aspect_h = 1, 1

    max_dim = max_dimension or 2400
    if aspect_w >= aspect_h:
        bw = max_dim
        bh = max(10, int(max_dim * aspect_h / aspect_w))
    else:
        bh = max_dim
        bw = max(10, int(max_dim * aspect_w / aspect_h))

    bg_color_hex = params.get("grid_bg_color", params.get("mat_color", "#FFFFFF"))
    bg_rgb = hex_to_rgb(bg_color_hex)
    board = Image.new("RGBA", (bw, bh), (*bg_rgb, 255))

    gap_base = params.get("gap_size", 8)
    gap_px = int(gap_base * (max(bw, bh) / 1000.0))
    cell_radius = int(params.get("cell_corner_radius", 0) * (max(bw, bh) / 1000.0))
    filter_name = params.get("filter_name", "original")

    if not images:
        return board

    slot_transforms = params.get("slot_transforms", {})
    board_slots = []

    for i, (x, y, w, h) in enumerate(layout.slots):
        img = images[i % len(images)]

        sx0 = int(x * bw) + (gap_px // 2 if x > 0.001 else 0)
        sy0 = int(y * bh) + (gap_px // 2 if y > 0.001 else 0)
        sx1 = int((x + w) * bw) - (gap_px // 2 if (x + w) < 0.999 else 0)
        sy1 = int((y + h) * bh) - (gap_px // 2 if (y + h) < 0.999 else 0)

        slot_w = max(10, sx1 - sx0)
        slot_h = max(10, sy1 - sy0)

        board_slots.append((sx0 / bw, sy0 / bh, sx1 / bw, sy1 / bh))

        is_preview_render = params.get("is_preview", False)

        # Get transform specific to this slot
        s_trans = slot_transforms.get(i, {}) if slot_transforms else {}
        s_zoom = s_trans.get("zoom", 1.0)
        s_pan_x = s_trans.get("pan_x", 0.0)
        s_pan_y = s_trans.get("pan_y", 0.0)
        s_rot = s_trans.get("rotation", 0)
        s_fliph = s_trans.get("flip_h", False)
        s_flipv = s_trans.get("flip_v", False)

        # Cache lookup for non-changing slots during pan/zoom
        slot_cache_key = (
            id(img),
            slot_w, slot_h,
            round(s_zoom, 3), round(s_pan_x, 3), round(s_pan_y, 3),
            s_rot, s_fliph, s_flipv,
            filter_name, is_preview_render
        )

        if is_preview_render and slot_cache_key in _SLOT_IMAGE_CACHE:
            processed = _SLOT_IMAGE_CACHE[slot_cache_key]
        else:
            processed = process_source_photo(
                img,
                aspect_preset="original",
                zoom=s_zoom,
                pan_x=s_pan_x,
                pan_y=s_pan_y,
                rotation=s_rot,
                flip_h=s_fliph,
                flip_v=s_flipv,
                filter_name=filter_name,
                target_dim=(slot_w, slot_h),
                is_preview=is_preview_render
            )
            if is_preview_render:
                if len(_SLOT_IMAGE_CACHE) > 30:
                    _SLOT_IMAGE_CACHE.pop(next(iter(_SLOT_IMAGE_CACHE)))
                _SLOT_IMAGE_CACHE[slot_cache_key] = processed

        if cell_radius > 0:
            mask = Image.new("L", (slot_w, slot_h), 0)
            mdraw = ImageDraw.Draw(mask)
            mdraw.rounded_rectangle([0, 0, slot_w, slot_h], radius=cell_radius, fill=255)
            board.paste(processed, (sx0, sy0), mask)
        else:
            board.paste(processed, (sx0, sy0))

    board.info["board_slots"] = board_slots
    return board


def render_framed_collage(
    images: List[Image.Image],
    layout_id: str,
    template_id: str,
    params: Dict[str, Any],
    max_dimension: Optional[int] = None
) -> Image.Image:
    """
    Composites images into a collage board, then wraps in chosen frame template.
    """
    board_max = max_dimension or 2400
    board = render_collage_board(images, layout_id, params, max_dimension=board_max)
    board_slots = board.info.get("board_slots", [])

    # Outer frame params should not zoom or pan the collage board itself
    outer_params = dict(params)
    outer_params["zoom"] = 1.0
    outer_params["pan_x"] = 0.0
    outer_params["pan_y"] = 0.0
    outer_params["rotation"] = 0
    outer_params["flip_h"] = False
    outer_params["flip_v"] = False
    outer_params["filter_name"] = "original"

    result = render_framed_photo(board, template_id, outer_params, max_dimension=max_dimension)

    inner_x, inner_y, ipw, iph = result.info.get("inner_rect", (0, 0, result.size[0], result.size[1]))
    fw, fh = result.size

    # Map each board_slot to the final framed image coordinates
    final_slots = []
    for (bsx0, bsy0, bsx1, bsy1) in board_slots:
        fx0 = (inner_x + bsx0 * ipw) / fw
        fy0 = (inner_y + bsy0 * iph) / fh
        fx1 = (inner_x + bsx1 * ipw) / fw
        fy1 = (inner_y + bsy1 * iph) / fh
        final_slots.append((fx0, fy0, fx1, fy1))

    result.info["slot_rects"] = final_slots
    return result

