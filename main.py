"""
PhotoFrameFancy - Main Application
A sleek, lightning-fast Python desktop application for framing photos with luxurious templates
and multi-photo grid collages (2, 3, 4, 5, 6 photos).
"""

import os
import sys
import threading
from typing import List, Optional, Dict, Any
from tkinter import filedialog, messagebox

import customtkinter as ctk
from PIL import Image

try:
    from tkinterdnd2 import TkinterDnD, DND_FILES
    HAS_DND = True
except ImportError:
    HAS_DND = False

from core.templates import TEMPLATES
from core.collage_layouts import COLLAGE_LAYOUTS
from core.frame_engine import render_framed_photo, render_framed_collage
from core.exporter import export_single_image, export_collage_image, BatchExportWorker
from core.preview_engine import AsyncPreviewEngine
from ui.sidebar_left import SidebarLeft
from ui.sidebar_right import SidebarRight
from ui.canvas_view import CanvasView
from ui.dialogs import BatchExportDialog


# Base class with DnD wrapper
if HAS_DND:
    class BaseWindow(ctk.CTk, TkinterDnD.DnDWrapper):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self.TkdndVersion = TkinterDnD._require(self)
else:
    class BaseWindow(ctk.CTk):
        pass


class PhotoFrameFancyApp(BaseWindow):
    def __init__(self):
        super().__init__()

        # Appearance & Window Config
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("blue")

        self.title("PhotoFrameFancy - Khung Ảnh & Lưới Ghép Nghệ Thuật Cao Cấp")
        self.geometry("1280x850")
        self.minsize(1020, 680)

        # Set Window icon if available
        icon_path = os.path.join(os.path.dirname(__file__), "assets", "thumbnails", "gold_baroque.png")
        if os.path.exists(icon_path):
            try:
                self.iconphoto(False, ctk.CTkImage(Image.open(icon_path))._dark_image)
            except Exception:
                pass

        # State
        self.mode = "single"  # "single" or "collage"
        self.current_template_id: str = "gold_baroque"
        self.current_collage_layout_id: str = "grid_2_split_v"
        self.current_collage_count: int = 2

        self.current_image_path: Optional[str] = None
        self.current_raw_image: Optional[Image.Image] = None

        # Debounce timer for smooth slider updates
        self._render_timer: Optional[str] = None
        self._latest_preview_img: Optional[Image.Image] = None
        self._ui_update_scheduled: bool = False

        # High-Speed Background Async Preview Engine
        self.preview_engine = AsyncPreviewEngine(on_result_callback=self._on_preview_rendered)

        self._build_layout()
        self._setup_drag_and_drop()

        # Load initial demo photos
        self.after(150, self._load_initial_demos)

    def _build_layout(self):
        self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=0)  # Left sidebar
        self.grid_columnconfigure(1, weight=1)  # Canvas
        self.grid_columnconfigure(2, weight=0)  # Right sidebar

        # 1. Left Sidebar
        self.sidebar_left = SidebarLeft(
            self,
            on_photo_selected=self.on_photo_selected,
            on_collage_photos_changed=self.on_collage_photos_changed,
            on_pick_files=self.pick_files,
            on_pick_folder=self.pick_folder,
            on_load_demo=self.load_all_demo_photos,
            on_batch_export_trigger=self.trigger_batch_export
        )
        self.sidebar_left.grid(row=0, column=0, sticky="nsew", padx=(10, 5), pady=10)

        # 2. Center Canvas View
        self.canvas_view = CanvasView(
            self,
            on_transform_change=self.on_transform_change,
            on_slot_selected=self.on_slot_selected_from_canvas,
            on_pick_file=self.pick_files,
            on_load_demo=self.load_all_demo_photos
        )
        self.canvas_view.grid(row=0, column=1, sticky="nsew", padx=5, pady=10)

        # 3. Right Sidebar
        self.sidebar_right = SidebarRight(
            self,
            on_param_change=self.on_param_change,
            on_template_change=self.on_template_change,
            on_collage_layout_change=self.on_collage_layout_change,
            on_mode_change=self.on_mode_change,
            on_save_single=self.save_current_artwork,
            on_batch_export=self.trigger_batch_export
        )
        self.sidebar_right.grid(row=0, column=2, sticky="nsew", padx=(5, 10), pady=10)

    def _setup_drag_and_drop(self):
        if not HAS_DND:
            return

        try:
            self.drop_target_register(DND_FILES)
            self.dnd_bind("<<Drop>>", self._on_drop_files)
        except Exception as e:
            print(f"DnD registration notice: {e}")

    def _on_drop_files(self, event):
        files_str = event.data
        paths = []
        if files_str.startswith("{") and files_str.endswith("}"):
            import re
            paths = re.findall(r"\{([^}]+)\}|(\S+)", files_str)
            paths = [p[0] or p[1] for p in paths]
        else:
            paths = files_str.split()

        valid_exts = (".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tiff")
        image_files = [p for p in paths if p.lower().endswith(valid_exts) and os.path.exists(p)]

        if image_files:
            self.sidebar_left.set_images(image_files)
            self.sidebar_left.select_photo(image_files[0])

    def _load_initial_demos(self):
        self.load_all_demo_photos()

    def load_all_demo_photos(self):
        demo_dir = os.path.join(os.path.dirname(__file__), "assets", "demo")
        demos = []
        for name in ["portrait.jpg", "landscape.jpg", "coffee.jpg", "flowers.jpg", "architecture.jpg", "beach.jpg"]:
            path = os.path.join(demo_dir, name)
            if os.path.exists(path):
                demos.append(os.path.abspath(path))

        if demos:
            self.sidebar_left.set_images(demos)
            self.sidebar_left.select_photo(demos[0])

    def pick_files(self):
        filetypes = [
            ("Hình ảnh (All Images)", "*.jpg;*.jpeg;*.png;*.webp;*.bmp;*.tiff"),
            ("JPEG files", "*.jpg;*.jpeg"),
            ("PNG files", "*.png"),
            ("WEBP files", "*.webp"),
            ("Tất cả tập tin", "*.*")
        ]
        files = filedialog.askopenfilenames(
            title="Chọn một hoặc nhiều hình ảnh để lồng khung / ghép lưới",
            filetypes=filetypes
        )
        if files:
            self.sidebar_left.set_images(list(files))
            self.sidebar_left.select_photo(files[0])

    def pick_folder(self):
        folder = filedialog.askdirectory(title="Chọn thư mục chứa hình ảnh")
        if folder:
            valid_exts = (".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tiff")
            found = []
            for root, _, files in os.walk(folder):
                for f in files:
                    if f.lower().endswith(valid_exts):
                        found.append(os.path.join(root, f))
            if found:
                self.sidebar_left.set_images(found)
                self.sidebar_left.select_photo(found[0])
            else:
                messagebox.showinfo("Thông báo", "Không tìm thấy file hình ảnh hợp lệ trong thư mục này.")

    # -------------------------------------------------------------
    # Event Handlers
    # -------------------------------------------------------------
    def on_mode_change(self, mode: str):
        self.mode = mode
        self.sidebar_left.set_mode(mode, self.current_collage_count)
        self.schedule_preview_render(immediate=True)

    def on_photo_selected(self, filepath: str):
        if not filepath or not os.path.exists(filepath):
            self.current_image_path = None
            self.current_raw_image = None
            if self.mode == "single":
                self.canvas_view.set_rendered_image(None)
            return

        self.current_image_path = filepath
        if self.mode == "collage":
            collage_imgs = self.sidebar_left.get_collage_images(self.current_collage_count)
            if filepath in collage_imgs:
                slot_idx = collage_imgs.index(filepath)
                self.canvas_view.set_selected_slot(slot_idx)
        try:
            self.current_raw_image = Image.open(filepath)
            self.schedule_preview_render(immediate=True)
        except Exception as e:
            messagebox.showerror("Lỗi", f"Không thể mở ảnh: {e}")

    def on_slot_selected_from_canvas(self, slot_idx: int):
        if self.mode == "collage":
            collage_imgs = self.sidebar_left.get_collage_images(self.current_collage_count)
            if 0 <= slot_idx < len(collage_imgs):
                path = collage_imgs[slot_idx]
                self.sidebar_left.select_photo(path, trigger_callback=False)

    def on_collage_layout_change(self, layout_id: str):
        self.current_collage_layout_id = layout_id
        layout = COLLAGE_LAYOUTS.get(layout_id)
        if layout:
            self.current_collage_count = layout.photo_count
            self.mode = "single" if layout.photo_count == 1 else "collage"
            self.sidebar_left.set_mode(self.mode, self.current_collage_count)
            self.canvas_view.set_selected_slot(0)
        self.schedule_preview_render(immediate=True)

    def on_collage_photos_changed(self):
        if self.mode == "collage":
            self.schedule_preview_render(immediate=True)

    def on_template_change(self, template_id: str):
        self.current_template_id = template_id
        self.schedule_preview_render(immediate=True)

    def on_param_change(self, params: Dict[str, Any]):
        self.schedule_preview_render(immediate=False)

    def on_transform_change(self, transform_params: Dict[str, Any]):
        self.schedule_preview_render(immediate=False)

    # -------------------------------------------------------------
    # High-Speed Async Preview Rendering
    # -------------------------------------------------------------
    def _on_preview_rendered(self, preview_img):
        """Called from background worker thread when frame is ready."""
        self._latest_preview_img = preview_img
        if not self._ui_update_scheduled:
            self._ui_update_scheduled = True
            try:
                self.after_idle(self._apply_latest_preview)
            except Exception:
                pass

    def _apply_latest_preview(self):
        self._ui_update_scheduled = False
        img = self._latest_preview_img
        if img is not None:
            self._latest_preview_img = None
            self.canvas_view.set_rendered_image(img)

    def schedule_preview_render(self, immediate: bool = False):
        """Submits render task to background thread without blocking the UI."""
        merged_params = {}
        merged_params.update(self.sidebar_right.params)
        merged_params.update(self.canvas_view.get_transform_params())

        if self.mode == "single":
            if not self.current_image_path:
                self.canvas_view.set_rendered_image(None)
                return
            image_paths = [self.current_image_path]
        else:
            image_paths = self.sidebar_left.get_collage_images(self.current_collage_count)
            if not image_paths:
                self.canvas_view.set_rendered_image(None)
                return

        # Adaptive resolution:
        # During interactive mouse dragging/zooming, render at 520px for 50+ FPS real-time smoothness
        # When released or idle, render at full 720px for crystal-clear fidelity
        is_dragging = getattr(self.canvas_view, "_is_dragging", False)
        max_dim = 520 if is_dragging else 720

        # Hand off to background worker thread immediately!
        self.preview_engine.request_render(
            mode=self.mode,
            image_paths=image_paths,
            layout_id=self.current_collage_layout_id,
            template_id=self.current_template_id,
            params=merged_params,
            max_dimension=max_dim
        )

    # -------------------------------------------------------------
    # Export Actions
    # -------------------------------------------------------------
    def save_current_artwork(self):
        ext_choice = self.sidebar_right.params.get("export_format", "PNG").lower()
        if ext_choice == "jpg":
            def_ext = ".jpg"
            filetypes = [("JPEG Image", "*.jpg"), ("PNG Image", "*.png"), ("WEBP Image", "*.webp")]
        elif ext_choice == "webp":
            def_ext = ".webp"
            filetypes = [("WEBP Image", "*.webp"), ("PNG Image", "*.png"), ("JPEG Image", "*.jpg")]
        else:
            def_ext = ".png"
            filetypes = [("PNG Image", "*.png"), ("JPEG Image", "*.jpg"), ("WEBP Image", "*.webp")]

        if self.mode == "single":
            if not self.current_image_path or not self.current_raw_image:
                messagebox.showwarning("Thông báo", "Vui lòng chọn hoặc nạp một hình ảnh trước khi lưu!")
                return
            base_name = os.path.splitext(os.path.basename(self.current_image_path))[0]
            initial_file = f"{base_name}_fancy{def_ext}"
        else:
            initial_file = f"collage_{self.current_collage_count}photos_{self.current_collage_layout_id}{def_ext}"

        out_path = filedialog.asksaveasfilename(
            title="Lưu Tác Phẩm Đã Lồng Khung",
            initialfile=initial_file,
            defaultextension=def_ext,
            filetypes=filetypes
        )
        if not out_path:
            return

        merged_params = {}
        merged_params.update(self.sidebar_right.params)
        merged_params.update(self.canvas_view.get_transform_params())

        try:
            if self.mode == "single":
                export_single_image(
                    source_path_or_img=self.current_raw_image,
                    output_path=out_path,
                    template_id=self.current_template_id,
                    params=merged_params,
                    resolution_preset=self.sidebar_right.params.get("export_res", "original"),
                    jpeg_quality=self.sidebar_right.params.get("jpeg_quality", 95)
                )
            else:
                image_paths = self.sidebar_left.get_collage_images(self.current_collage_count)
                export_collage_image(
                    source_images=image_paths,
                    output_path=out_path,
                    layout_id=self.current_collage_layout_id,
                    template_id=self.current_template_id,
                    params=merged_params,
                    resolution_preset=self.sidebar_right.params.get("export_res", "original"),
                    jpeg_quality=self.sidebar_right.params.get("jpeg_quality", 95)
                )

            messagebox.showinfo("Thành công", f"Đã lưu tác phẩm thành công tại:\n{out_path}")
        except Exception as e:
            messagebox.showerror("Lỗi khi lưu ảnh", f"Đã có lỗi xảy ra: {e}")

    def trigger_batch_export(self):
        images = self.sidebar_left.image_paths
        if not images:
            messagebox.showwarning("Thông báo", "Danh sách ảnh đang trống! Vui lòng thêm ảnh trước khi xuất hàng loạt.")
            return

        out_dir = filedialog.askdirectory(title=f"Chọn thư mục lưu {len(images)} ảnh đã lồng khung")
        if not out_dir:
            return

        merged_params = {}
        merged_params.update(self.sidebar_right.params)
        merged_params.update(self.canvas_view.get_transform_params())

        fmt = self.sidebar_right.params.get("export_format", "PNG").lower()
        ext = f".{fmt}" if not fmt.startswith(".") else fmt

        dialog = BatchExportDialog(self, total_count=len(images))

        worker = BatchExportWorker(
            image_paths=images,
            output_dir=out_dir,
            template_id=self.current_template_id,
            params=merged_params,
            format_ext=ext,
            resolution_preset=self.sidebar_right.params.get("export_res", "original"),
            jpeg_quality=self.sidebar_right.params.get("jpeg_quality", 95),
            on_progress=lambda cur, tot, name: self.after(0, lambda: dialog.update_progress(cur, tot, name)),
            on_complete=lambda succ, fail: self.after(0, lambda: dialog.mark_completed(succ, fail, out_dir))
        )

        dialog.on_cancel_callback = worker.cancel
        worker.start()


    def destroy(self):
        try:
            self.preview_engine.shutdown()
        except Exception:
            pass
        super().destroy()


def main():
    app = PhotoFrameFancyApp()
    app.mainloop()


if __name__ == "__main__":
    main()
