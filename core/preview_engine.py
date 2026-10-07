"""
PhotoFrameFancy - Async Preview Engine & In-Memory Photo Cache
Renders previews on a background thread with request coalescing,
zero disk I/O during slider adjustments, and zero UI thread blocking.
"""

import os
import threading
import time
from typing import Dict, Any, List, Optional, Callable
from PIL import Image, ImageOps

from core.frame_engine import render_framed_photo, render_framed_collage


class PhotoCache:
    """Thread-safe in-memory cache for pre-decoded, downscaled preview images."""
    def __init__(self, max_preview_dimension: int = 800):
        self.max_preview_dimension = max_preview_dimension
        self._cache: Dict[str, Image.Image] = {}
        self._lock = threading.Lock()

    def get(self, filepath: str) -> Optional[Image.Image]:
        if not filepath or not os.path.exists(filepath):
            return None

        with self._lock:
            if filepath in self._cache:
                return self._cache[filepath]

        # Decode & downscale once
        try:
            with Image.open(filepath) as raw:
                img = ImageOps.exif_transpose(raw)
                if img.mode != "RGB":
                    img = img.convert("RGB")
                
                w, h = img.size
                scale = self.max_preview_dimension / max(w, h)
                if scale < 1.0:
                    new_w = max(10, int(w * scale))
                    new_h = max(10, int(h * scale))
                    img = img.resize((new_w, new_h), Image.Resampling.BILINEAR)

            with self._lock:
                self._cache[filepath] = img
            return img
        except Exception as e:
            print(f"Error caching preview for {filepath}: {e}")
            return None

    def remove(self, filepath: str):
        with self._lock:
            self._cache.pop(filepath, None)

    def clear(self):
        with self._lock:
            self._cache.clear()


class AsyncPreviewEngine:
    """
    Renders previews in a dedicated background worker thread with request coalescing.
    Ensures the Tkinter UI event loop stays at 60fps at all times.
    """
    def __init__(self, on_result_callback: Callable[[Image.Image], None]):
        self.on_result_callback = on_result_callback
        self.cache = PhotoCache(max_preview_dimension=800)

        self._lock = threading.Lock()
        self._event = threading.Event()
        self._running = True

        self._pending_request: Optional[Dict[str, Any]] = None
        self._request_counter = 0
        self._latest_handled = 0

        self._worker_thread = threading.Thread(target=self._worker_loop, daemon=True)
        self._worker_thread.start()

    def request_render(
        self,
        mode: str,
        image_paths: List[str],
        layout_id: str,
        template_id: str,
        params: Dict[str, Any],
        max_dimension: int = 700
    ):
        """Submit a new render request. Drops any previous unprocessed request instantly."""
        with self._lock:
            self._request_counter += 1
            self._pending_request = {
                "id": self._request_counter,
                "mode": mode,
                "image_paths": list(image_paths),
                "layout_id": layout_id,
                "template_id": template_id,
                "params": dict(params),
                "max_dimension": max_dimension,
            }
            self._event.set()

    def _worker_loop(self):
        while self._running:
            self._event.wait()
            self._event.clear()

            with self._lock:
                req = self._pending_request
                self._pending_request = None

            if req is None or not self._running:
                continue

            req_id = req["id"]
            mode = req["mode"]
            image_paths = req["image_paths"]
            layout_id = req["layout_id"]
            template_id = req["template_id"]
            params = req["params"]
            max_dim = req["max_dimension"]

            # Load images from in-memory cache (0ms disk I/O!)
            pil_images = []
            for path in image_paths:
                cached = self.cache.get(path)
                if cached:
                    pil_images.append(cached)

            if not pil_images:
                continue

            try:
                # Mark as preview render for fast bilinear resampling
                params["is_preview"] = True

                if mode == "single":
                    preview = render_framed_photo(
                        image=pil_images[0],
                        template_id=template_id,
                        params=params,
                        max_dimension=max_dim
                    )
                else:
                    preview = render_framed_collage(
                        images=pil_images,
                        layout_id=layout_id,
                        template_id=template_id,
                        params=params,
                        max_dimension=max_dim
                    )

                # Check if a newer request arrived while rendering this frame
                with self._lock:
                    if self._pending_request is not None and self._pending_request["id"] > req_id:
                        # Newer request waiting, discard this stale frame and process next immediately!
                        continue
                    self._latest_handled = req_id

                # Post back to Tkinter UI thread
                self.on_result_callback(preview)

            except Exception as e:
                print(f"Async render error: {e}")

    def shutdown(self):
        self._running = False
        self._event.set()
