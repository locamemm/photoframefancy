"""
PhotoFrameFancy - Filters Engine
Provides high-performance artistic color grading & aesthetic filters.
"""

from PIL import Image, ImageEnhance, ImageOps
import numpy as np


def apply_filter(image: Image.Image, filter_name: str) -> Image.Image:
    """Apply an artistic filter to a PIL Image."""
    if not filter_name or filter_name == "original":
        return image.copy()

    img = image.convert("RGB")

    if filter_name == "sepia":
        # Classic Sepia Toning
        arr = np.array(img, dtype=np.float32)
        r = arr[:, :, 0] * 0.393 + arr[:, :, 1] * 0.769 + arr[:, :, 2] * 0.189
        g = arr[:, :, 0] * 0.349 + arr[:, :, 1] * 0.686 + arr[:, :, 2] * 0.168
        b = arr[:, :, 0] * 0.272 + arr[:, :, 1] * 0.534 + arr[:, :, 2] * 0.131
        sepia_arr = np.stack([r, g, b], axis=-1)
        sepia_arr = np.clip(sepia_arr, 0, 255).astype(np.uint8)
        res = Image.fromarray(sepia_arr)
        # Slight warmth contrast
        res = ImageEnhance.Contrast(res).enhance(1.1)
        return res

    elif filter_name == "bw_classic":
        # Rich B&W with high tonal range
        gray = ImageOps.grayscale(img)
        gray = ImageEnhance.Contrast(gray).enhance(1.25)
        gray = ImageEnhance.Brightness(gray).enhance(0.98)
        return gray.convert("RGB")

    elif filter_name == "warm_film":
        # Kodak Gold film warmth: warm highlights, slightly lifted blacks
        arr = np.array(img, dtype=np.float32)
        arr[:, :, 0] = arr[:, :, 0] * 1.1 + 10  # Red boost
        arr[:, :, 1] = arr[:, :, 1] * 1.03 + 5  # Green slight boost
        arr[:, :, 2] = arr[:, :, 2] * 0.92 - 5  # Blue reduction
        arr = np.clip(arr, 0, 255).astype(np.uint8)
        res = Image.fromarray(arr)
        res = ImageEnhance.Color(res).enhance(1.15)
        res = ImageEnhance.Contrast(res).enhance(1.08)
        return res

    elif filter_name == "cool_cinematic":
        # Teal & Orange Cinematic
        arr = np.array(img, dtype=np.float32)
        arr[:, :, 0] = arr[:, :, 0] * 1.05 + 5   # Red
        arr[:, :, 1] = arr[:, :, 1] * 0.98       # Green
        arr[:, :, 2] = arr[:, :, 2] * 1.15 + 12  # Blue cool tone
        arr = np.clip(arr, 0, 255).astype(np.uint8)
        res = Image.fromarray(arr)
        res = ImageEnhance.Contrast(res).enhance(1.18)
        return res

    elif filter_name == "vivid":
        # Vibrant colors and crisp micro-contrast
        res = ImageEnhance.Color(img).enhance(1.4)
        res = ImageEnhance.Contrast(res).enhance(1.15)
        res = ImageEnhance.Sharpness(res).enhance(1.2)
        return res

    elif filter_name == "muted_pastel":
        # Soft pastel Instagram aesthetic
        res = ImageEnhance.Color(img).enhance(0.75)
        res = ImageEnhance.Brightness(res).enhance(1.06)
        res = ImageEnhance.Contrast(res).enhance(0.92)
        return res

    elif filter_name == "noir_dramatic":
        # Moody dark film noir
        gray = ImageOps.grayscale(img)
        gray = ImageEnhance.Contrast(gray).enhance(1.45)
        gray = ImageEnhance.Brightness(gray).enhance(0.9)
        return gray.convert("RGB")

    return img.copy()


FILTER_LIST = [
    ("original", "Gốc (Original)"),
    ("warm_film", "Phim Ấm (Warm Film)"),
    ("sepia", "Cổ Điển (Sepia)"),
    ("bw_classic", "Đen Trắng (B&W Fine Art)"),
    ("cool_cinematic", "Điện Ảnh (Cool Cine)"),
    ("vivid", "Rực Rỡ (Vivid Pop)"),
    ("muted_pastel", "Pastel Nhẹ Nhàng (Muted)"),
    ("noir_dramatic", "Kịch Tính (Noir Drama)"),
]
