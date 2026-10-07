"""
PhotoFrameFancy - High-Resolution Export Engine & Batch Processor
Handles crisp rendering and export for individual photos and bulk queues.
"""

import os
import threading
from typing import List, Dict, Any, Callable, Optional
from PIL import Image

from core.frame_engine import render_framed_photo, render_framed_collage


EXPORT_PRESETS = {
    "original": ("Giữ nguyên gốc (Original High-Res)", None),
    "4k": ("4K Ultra HD (3840px)", 3840),
    "2k": ("2K Quad HD (2048px)", 2048),
    "fhd": ("Full HD (1920px)", 1920),
    "instagram": ("Instagram Chuẩn (1080px)", 1080),
}


def export_single_image(
    source_path_or_img: Any,
    output_path: str,
    template_id: str,
    params: Dict[str, Any],
    resolution_preset: str = "original",
    jpeg_quality: int = 95
) -> bool:
    """
    Renders and saves a single photo at high resolution.
    """
    if isinstance(source_path_or_img, str):
        img = Image.open(source_path_or_img)
    else:
        img = source_path_or_img

    target_dim = EXPORT_PRESETS.get(resolution_preset, ("Original", None))[1]
    
    # Render at requested target dimension (None = original full size)
    rendered = render_framed_photo(img, template_id, params, max_dimension=target_dim)

    # Prepare format
    ext = os.path.splitext(output_path)[1].lower()
    
    if ext in [".jpg", ".jpeg"]:
        # JPEG does not support alpha, composite onto white or mat color
        if rendered.mode == "RGBA":
            bg = Image.new("RGB", rendered.size, (255, 255, 255))
            bg.paste(rendered, (0, 0), rendered)
            rendered = bg
        elif rendered.mode != "RGB":
            rendered = rendered.convert("RGB")
        rendered.save(output_path, "JPEG", quality=jpeg_quality, optimize=True)
    elif ext == ".webp":
        rendered.save(output_path, "WEBP", quality=jpeg_quality)
    else:  # PNG or default
        rendered.save(output_path, "PNG", optimize=True)

    return True


def export_collage_image(
    source_images: List[Any],
    output_path: str,
    layout_id: str,
    template_id: str,
    params: Dict[str, Any],
    resolution_preset: str = "original",
    jpeg_quality: int = 95
) -> bool:
    """
    Renders and saves a composite grid/collage photo at high resolution.
    """
    pil_images = []
    for item in source_images:
        if isinstance(item, str):
            pil_images.append(Image.open(item))
        else:
            pil_images.append(item)

    target_dim = EXPORT_PRESETS.get(resolution_preset, ("Original", 2400))[1]
    if target_dim is None:
        target_dim = 2800  # Default crisp 2.8K for collage when original

    rendered = render_framed_collage(
        images=pil_images,
        layout_id=layout_id,
        template_id=template_id,
        params=params,
        max_dimension=target_dim
    )

    ext = os.path.splitext(output_path)[1].lower()
    if ext in [".jpg", ".jpeg"]:
        if rendered.mode == "RGBA":
            bg = Image.new("RGB", rendered.size, (255, 255, 255))
            bg.paste(rendered, (0, 0), rendered)
            rendered = bg
        elif rendered.mode != "RGB":
            rendered = rendered.convert("RGB")
        rendered.save(output_path, "JPEG", quality=jpeg_quality, optimize=True)
    elif ext == ".webp":
        rendered.save(output_path, "WEBP", quality=jpeg_quality)
    else:
        rendered.save(output_path, "PNG", optimize=True)

    return True


class BatchExportWorker:
    """
    Runs batch export in a background thread with progress updates.
    """
    def __init__(
        self,
        image_paths: List[str],
        output_dir: str,
        template_id: str,
        params: Dict[str, Any],
        format_ext: str = ".png",
        resolution_preset: str = "original",
        jpeg_quality: int = 95,
        on_progress: Optional[Callable[[int, int, str], None]] = None,
        on_complete: Optional[Callable[[int, int], None]] = None
    ):
        self.image_paths = image_paths
        self.output_dir = output_dir
        self.template_id = template_id
        self.params = params
        self.format_ext = format_ext
        self.resolution_preset = resolution_preset
        self.jpeg_quality = jpeg_quality
        self.on_progress = on_progress
        self.on_complete = on_complete
        
        self.is_cancelled = False
        self._thread: Optional[threading.Thread] = None

    def start(self):
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def cancel(self):
        self.is_cancelled = True

    def _run(self):
        total = len(self.image_paths)
        successful = 0
        failed = 0

        os.makedirs(self.output_dir, exist_ok=True)

        for i, img_path in enumerate(self.image_paths):
            if self.is_cancelled:
                break

            base_name = os.path.splitext(os.path.basename(img_path))[0]
            out_filename = f"{base_name}_fancy{self.format_ext}"
            out_path = os.path.join(self.output_dir, out_filename)

            # Prevent overwriting unintentionally
            count = 1
            while os.path.exists(out_path):
                out_path = os.path.join(self.output_dir, f"{base_name}_fancy_{count}{self.format_ext}")
                count += 1

            if self.on_progress:
                self.on_progress(i + 1, total, os.path.basename(img_path))

            try:
                export_single_image(
                    source_path_or_img=img_path,
                    output_path=out_path,
                    template_id=self.template_id,
                    params=self.params,
                    resolution_preset=self.resolution_preset,
                    jpeg_quality=self.jpeg_quality
                )
                successful += 1
            except Exception as e:
                print(f"Export error for {img_path}: {e}")
                failed += 1

        if self.on_complete:
            self.on_complete(successful, failed)
