"""
PhotoFrameFancy - Left Sidebar (Image Library & Batch List)
Handles photo importing, thumbnail list, selection, slot badges for collage,
and batch management.
"""

import os
from typing import List, Optional, Callable, Dict
import customtkinter as ctk
from PIL import Image, ImageTk


class ImageItemFrame(ctk.CTkFrame):
    """Single item row in the photo library."""
    def __init__(
        self,
        parent,
        filepath: str,
        is_selected: bool,
        slot_index: Optional[int],  # 1-based index if in collage mode, None if not
        on_select: Callable[[str], None],
        on_delete: Callable[[str], None]
    ):
        super().__init__(
            parent,
            fg_color="#312E81" if is_selected else "#27272A",
            corner_radius=8,
            height=64
        )
        self.filepath = filepath
        self.on_select = on_select
        self.on_delete = on_delete

        self.bind("<Button-1>", lambda e: self.on_select(self.filepath))

        # Thumbnail
        self.thumb_lbl = ctk.CTkLabel(self, text="", width=48, height=48)
        self.thumb_lbl.pack(side="left", padx=6, pady=6)
        self.thumb_lbl.bind("<Button-1>", lambda e: self.on_select(self.filepath))

        self._load_thumb()

        # Slot Badge (if in collage mode)
        if slot_index is not None:
            badge_lbl = ctk.CTkLabel(
                self,
                text=f"#{slot_index}",
                font=ctk.CTkFont(size=11, weight="bold"),
                fg_color="#4F46E5",
                corner_radius=4,
                width=24,
                height=22
            )
            badge_lbl.pack(side="left", padx=(0, 4))
            badge_lbl.bind("<Button-1>", lambda e: self.on_select(self.filepath))

        # Text info
        filename = os.path.basename(filepath)
        if len(filename) > 16:
            display_name = filename[:13] + "..."
        else:
            display_name = filename

        self.info_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.info_frame.pack(side="left", fill="both", expand=True, padx=4, pady=6)
        self.info_frame.bind("<Button-1>", lambda e: self.on_select(self.filepath))

        self.name_lbl = ctk.CTkLabel(
            self.info_frame,
            text=display_name,
            font=ctk.CTkFont(size=12, weight="bold"),
            anchor="w"
        )
        self.name_lbl.pack(fill="x")
        self.name_lbl.bind("<Button-1>", lambda e: self.on_select(self.filepath))

        self.sub_lbl = ctk.CTkLabel(
            self.info_frame,
            text=f"{os.path.splitext(filename)[1].upper().replace('.', '')} Image",
            font=ctk.CTkFont(size=10),
            text_color="gray60",
            anchor="w"
        )
        self.sub_lbl.pack(fill="x")
        self.sub_lbl.bind("<Button-1>", lambda e: self.on_select(self.filepath))

        # Delete button
        self.del_btn = ctk.CTkButton(
            self,
            text="✕",
            width=22,
            height=22,
            fg_color="transparent",
            hover_color="#EF4444",
            text_color="gray70",
            command=lambda: self.on_delete(self.filepath)
        )
        self.del_btn.pack(side="right", padx=6)

    def _load_thumb(self):
        try:
            with Image.open(self.filepath) as img:
                img.thumbnail((44, 44), Image.Resampling.BILINEAR)
                ctk_img = ctk.CTkImage(light_image=img, dark_image=img, size=(44, 44))
                self.thumb_lbl.configure(image=ctk_img)
        except Exception:
            self.thumb_lbl.configure(text="🖼️")


class SidebarLeft(ctk.CTkFrame):
    def __init__(
        self,
        parent,
        on_photo_selected: Callable[[str], None],
        on_collage_photos_changed: Callable[[], None],
        on_pick_files: Callable[[], None],
        on_pick_folder: Callable[[], None],
        on_load_demo: Callable[[], None],
        on_batch_export_trigger: Callable[[], None]
    ):
        super().__init__(parent, width=285, fg_color="#18181B", corner_radius=12)
        self.pack_propagate(False)

        self.on_photo_selected = on_photo_selected
        self.on_collage_photos_changed = on_collage_photos_changed
        self.on_pick_files = on_pick_files
        self.on_pick_folder = on_pick_folder
        self.on_load_demo = on_load_demo
        self.on_batch_export_trigger = on_batch_export_trigger

        self.image_paths: List[str] = []
        self.selected_path: Optional[str] = None
        
        # Mode
        self.mode = "single"  # "single" or "collage"
        self.collage_required_count = 2

        self._build_ui()

    def _build_ui(self):
        # 1. Header / Logo
        header = ctk.CTkFrame(self, fg_color="transparent")
        header.pack(fill="x", padx=14, pady=(16, 8))

        title_lbl = ctk.CTkLabel(
            header,
            text="✨ PhotoFrameFancy",
            font=ctk.CTkFont(size=17, weight="bold"),
            text_color="#F4F4F5"
        )
        title_lbl.pack(anchor="w")

        sub_lbl = ctk.CTkLabel(
            header,
            text="Khung Ảnh & Lưới Ghép Nghệ Thuật",
            font=ctk.CTkFont(size=11),
            text_color="#A1A1AA"
        )
        sub_lbl.pack(anchor="w")

        # 2. Action Buttons Frame
        btn_grid = ctk.CTkFrame(self, fg_color="transparent")
        btn_grid.pack(fill="x", padx=12, pady=(2, 6))

        self.btn_add_files = ctk.CTkButton(
            btn_grid,
            text="➕ Thêm Ảnh...",
            font=ctk.CTkFont(size=12, weight="bold"),
            fg_color="#4F46E5",
            hover_color="#4338CA",
            height=32,
            command=self.on_pick_files
        )
        self.btn_add_files.pack(fill="x", pady=2)

        row2 = ctk.CTkFrame(btn_grid, fg_color="transparent")
        row2.pack(fill="x", pady=2)

        self.btn_add_folder = ctk.CTkButton(
            row2,
            text="📁 Cả Thư Mục",
            font=ctk.CTkFont(size=11),
            fg_color="#27272A",
            hover_color="#3F3F46",
            height=28,
            command=self.on_pick_folder
        )
        self.btn_add_folder.pack(side="left", fill="x", expand=True, padx=(0, 2))

        self.btn_demo = ctk.CTkButton(
            row2,
            text="🌟 6 Ảnh Mẫu",
            font=ctk.CTkFont(size=11),
            fg_color="#27272A",
            hover_color="#3F3F46",
            height=28,
            command=self.on_load_demo
        )
        self.btn_demo.pack(side="right", fill="x", expand=True, padx=(2, 0))

        # Reorder / Shuffle button for Collage mode
        self.btn_shuffle = ctk.CTkButton(
            btn_grid,
            text="🔀 Đổi Vị Trí Ảnh Ghép",
            font=ctk.CTkFont(size=11),
            fg_color="#374151",
            hover_color="#4B5563",
            height=26,
            command=self.rotate_images
        )
        # Will show/hide dynamically

        # 3. Photo List Scroll Area
        list_header = ctk.CTkFrame(self, fg_color="transparent")
        list_header.pack(fill="x", padx=14, pady=(4, 2))

        self.count_lbl = ctk.CTkLabel(
            list_header,
            text="Danh Sách Ảnh (0)",
            font=ctk.CTkFont(size=12, weight="bold"),
            text_color="#E4E4E7"
        )
        self.count_lbl.pack(side="left")

        self.clear_btn = ctk.CTkButton(
            list_header,
            text="Xóa hết",
            width=50,
            height=20,
            font=ctk.CTkFont(size=10),
            fg_color="transparent",
            hover_color="#3F3F46",
            text_color="#F87171",
            command=self.clear_all
        )
        self.clear_btn.pack(side="right")

        self.scroll_list = ctk.CTkScrollableFrame(
            self,
            fg_color="#0F0F12",
            corner_radius=8
        )
        self.scroll_list.pack(fill="both", expand=True, padx=12, pady=(4, 8))

        # 4. Bottom Batch Export CTA
        bottom_bar = ctk.CTkFrame(self, fg_color="transparent")
        bottom_bar.pack(fill="x", padx=12, pady=(0, 12))

        self.btn_batch = ctk.CTkButton(
            bottom_bar,
            text="⚡ Xuất Toàn Bộ Hàng Loạt",
            font=ctk.CTkFont(size=12, weight="bold"),
            fg_color="#059669",
            hover_color="#047857",
            height=36,
            command=self.on_batch_export_trigger
        )
        self.btn_batch.pack(fill="x")

    def set_mode(self, mode: str, count: int = 2):
        self.mode = mode
        self.collage_required_count = count
        if self.mode == "collage":
            self.btn_shuffle.pack(fill="x", pady=(2, 2))
        else:
            self.btn_shuffle.pack_forget()
        self.refresh_list()

    def set_images(self, filepaths: List[str]):
        """Set new list of images, preserving unique ones."""
        for p in filepaths:
            if p not in self.image_paths and os.path.exists(p):
                self.image_paths.append(p)
        self.refresh_list()

    def add_image(self, filepath: str):
        if filepath not in self.image_paths and os.path.exists(filepath):
            self.image_paths.append(filepath)
            self.refresh_list()

    def remove_image(self, filepath: str):
        if filepath in self.image_paths:
            idx = self.image_paths.index(filepath)
            self.image_paths.remove(filepath)
            if self.selected_path == filepath:
                if self.image_paths:
                    new_idx = min(idx, len(self.image_paths) - 1)
                    self.select_photo(self.image_paths[new_idx])
                else:
                    self.selected_path = None
                    self.on_photo_selected("")
            self.refresh_list()
            if self.mode == "collage":
                self.on_collage_photos_changed()

    def clear_all(self):
        self.image_paths.clear()
        self.selected_path = None
        self.on_photo_selected("")
        self.refresh_list()
        if self.mode == "collage":
            self.on_collage_photos_changed()

    def select_photo(self, filepath: str, trigger_callback: bool = True):
        self.selected_path = filepath
        self.refresh_list()
        if trigger_callback:
            self.on_photo_selected(filepath)

    def rotate_images(self):
        """Rotate images queue so slot order shifts by 1."""
        if len(self.image_paths) >= 2:
            first = self.image_paths.pop(0)
            self.image_paths.append(first)
            self.selected_path = self.image_paths[0]
            self.refresh_list()
            self.on_collage_photos_changed()

    def get_collage_images(self, count: int) -> List[str]:
        """Returns `count` image paths, cycling if fewer are available."""
        if not self.image_paths:
            return []
        res = []
        for i in range(count):
            res.append(self.image_paths[i % len(self.image_paths)])
        return res

    def refresh_list(self):
        total = len(self.image_paths)
        if self.mode == "collage":
            self.count_lbl.configure(text=f"Khung {self.collage_required_count} Ô (Có {total} ảnh)")
        else:
            self.count_lbl.configure(text=f"Danh Sách Ảnh ({total})")

        for widget in self.scroll_list.winfo_children():
            widget.destroy()

        for i, p in enumerate(self.image_paths):
            is_sel = (p == self.selected_path)
            slot_num = (i + 1) if (self.mode == "collage" and i < self.collage_required_count) else None
            
            item = ImageItemFrame(
                self.scroll_list,
                filepath=p,
                is_selected=is_sel,
                slot_index=slot_num,
                on_select=self.select_photo,
                on_delete=self.remove_image
            )
            item.pack(fill="x", pady=3)
