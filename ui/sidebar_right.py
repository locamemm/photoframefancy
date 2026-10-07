"""
PhotoFrameFancy - Right Sidebar (Dual Tab Lists: Collage Grids & Outer Frame Borders)
Provides 2 dedicated visual tab lists:
  1. '▦ Mẫu Khung Lưới': 37+ Grid layouts for 1, 2, 3, 4, 5, 6 photos.
  2. '🖼️ Viền Bọc Ngoài': 15 Luxury outer frame borders (Wood, Gold, Museum, Neon, Polaroid, etc.).
Plus Customize, Filters, and Export tabs.
"""

import os
from typing import Dict, Any, Callable, Optional, List
import customtkinter as ctk
from PIL import Image

from core.templates import TEMPLATES, FrameTemplate, get_categories, get_templates_by_category
from core.collage_layouts import (
    COLLAGE_LAYOUTS,
    CollageLayout,
    get_collage_categories,
    get_layouts_by_photo_count,
    get_layouts_by_category,
)
from core.filters import FILTER_LIST
from core.exporter import EXPORT_PRESETS
from ui.dialogs import pick_color


class TemplateCard(ctk.CTkFrame):
    """Visual card for an Outer Frame Border template."""
    def __init__(
        self,
        parent,
        template: FrameTemplate,
        is_selected: bool,
        on_select: Callable[[str], None]
    ):
        super().__init__(
            parent,
            fg_color="#312E81" if is_selected else "#27272A",
            corner_radius=8,
            height=68
        )
        self.template = template
        self.on_select = on_select

        self.bind("<Button-1>", lambda e: self.on_select(self.template.id))

        self.thumb_lbl = ctk.CTkLabel(self, text="", width=52, height=52)
        self.thumb_lbl.pack(side="left", padx=8, pady=6)
        self.thumb_lbl.bind("<Button-1>", lambda e: self.on_select(self.template.id))
        self._load_thumb()

        info = ctk.CTkFrame(self, fg_color="transparent")
        info.pack(side="left", fill="both", expand=True, padx=4, pady=6)
        info.bind("<Button-1>", lambda e: self.on_select(self.template.id))

        name_lbl = ctk.CTkLabel(
            info,
            text=f"{self.template.icon_symbol} {self.template.name}",
            font=ctk.CTkFont(size=12, weight="bold"),
            anchor="w"
        )
        name_lbl.pack(fill="x")
        name_lbl.bind("<Button-1>", lambda e: self.on_select(self.template.id))

        cat_lbl = ctk.CTkLabel(
            info,
            text=self.template.category,
            font=ctk.CTkFont(size=10),
            text_color="#93C5FD" if is_selected else "gray60",
            anchor="w"
        )
        cat_lbl.pack(fill="x")
        cat_lbl.bind("<Button-1>", lambda e: self.on_select(self.template.id))

    def _load_thumb(self):
        thumb_path = f"assets/thumbnails/{self.template.id}.png"
        if os.path.exists(thumb_path):
            try:
                img = Image.open(thumb_path)
                ctk_img = ctk.CTkImage(light_image=img, dark_image=img, size=(48, 48))
                self.thumb_lbl.configure(image=ctk_img)
                return
            except Exception:
                pass
        self.thumb_lbl.configure(text=self.template.icon_symbol, font=("Segoe UI Emoji", 18))


class CollageCard(ctk.CTkFrame):
    """Visual card for a Collage / Grid Layout template."""
    def __init__(
        self,
        parent,
        layout: CollageLayout,
        is_selected: bool,
        on_select: Callable[[str], None]
    ):
        super().__init__(
            parent,
            fg_color="#1E3A8A" if is_selected else "#27272A",
            corner_radius=8,
            height=68
        )
        self.layout = layout
        self.on_select = on_select

        self.bind("<Button-1>", lambda e: self.on_select(self.layout.id))

        # Thumbnail Diagram
        self.thumb_lbl = ctk.CTkLabel(self, text="", width=52, height=52)
        self.thumb_lbl.pack(side="left", padx=8, pady=6)
        self.thumb_lbl.bind("<Button-1>", lambda e: self.on_select(self.layout.id))
        self._load_thumb()

        info = ctk.CTkFrame(self, fg_color="transparent")
        info.pack(side="left", fill="both", expand=True, padx=4, pady=6)
        info.bind("<Button-1>", lambda e: self.on_select(self.layout.id))

        name_lbl = ctk.CTkLabel(
            info,
            text=f"{self.layout.name}",
            font=ctk.CTkFont(size=12, weight="bold"),
            anchor="w"
        )
        name_lbl.pack(fill="x")
        name_lbl.bind("<Button-1>", lambda e: self.on_select(self.layout.id))

        sub_lbl = ctk.CTkLabel(
            info,
            text=f"Tỉ lệ {self.layout.aspect_preset} • {self.layout.photo_count} ảnh",
            font=ctk.CTkFont(size=10),
            text_color="#60A5FA" if is_selected else "gray60",
            anchor="w"
        )
        sub_lbl.pack(fill="x")
        sub_lbl.bind("<Button-1>", lambda e: self.on_select(self.layout.id))

    def _load_thumb(self):
        thumb_path = f"assets/thumbnails/collages/{self.layout.id}.png"
        if os.path.exists(thumb_path):
            try:
                img = Image.open(thumb_path)
                ctk_img = ctk.CTkImage(light_image=img, dark_image=img, size=(48, 48))
                self.thumb_lbl.configure(image=ctk_img)
                return
            except Exception:
                pass
        self.thumb_lbl.configure(text=self.layout.icon_symbol, font=("Segoe UI Emoji", 18))


class SidebarRight(ctk.CTkFrame):
    def __init__(
        self,
        parent,
        on_param_change: Callable[[Dict[str, Any]], None],
        on_template_change: Callable[[str], None],
        on_collage_layout_change: Callable[[str], None],
        on_mode_change: Callable[[str], None],
        on_save_single: Callable[[], None],
        on_batch_export: Callable[[], None]
    ):
        super().__init__(parent, width=355, fg_color="#18181B", corner_radius=12)
        self.pack_propagate(False)

        self.on_param_change = on_param_change
        self.on_template_change = on_template_change
        self.on_collage_layout_change = on_collage_layout_change
        self.on_mode_change = on_mode_change
        self.on_save_single = on_save_single
        self.on_batch_export = on_batch_export

        # Active state
        self.current_photo_count = 1
        self.current_collage_layout_id = "grid_1_original"
        self.current_template_id = "gold_baroque"
        self.current_outer_category = "Tất cả"

        tmpl = TEMPLATES[self.current_template_id]
        self.params: Dict[str, Any] = {
            # Outer Frame properties
            "border_ratio": tmpl.default_border_ratio,
            "mat_ratio": tmpl.default_mat_ratio,
            "frame_color": tmpl.default_frame_color,
            "mat_color": tmpl.default_mat_color,
            "has_shadow": tmpl.has_shadow,
            "corner_radius": 0,
            "aspect_preset": tmpl.aspect_preset,
            # Grid properties
            "gap_size": 10,
            "cell_corner_radius": 4,
            "grid_bg_color": "#FFFFFF",
            # Shared
            "filter_name": "original",
            "caption_text": tmpl.default_caption,
            "export_res": "original",
            "export_format": "PNG",
            "jpeg_quality": 95,
        }

        self._build_ui()

    def _build_ui(self):
        # Master Tabview with 2 dedicated visual tab lists
        self.tabview = ctk.CTkTabview(
            self,
            fg_color="#18181B",
            segmented_button_fg_color="#27272A",
            segmented_button_selected_color="#4F46E5",
            segmented_button_selected_hover_color="#4338CA"
        )
        self.tabview.pack(fill="both", expand=True, padx=6, pady=4)

        # 2 Dedicated Tab Lists requested by user
        self.tab_grid_layouts = self.tabview.add("▦ Mẫu Khung Lưới")
        self.tab_outer_frames = self.tabview.add("🖼️ Viền Bọc Ngoài")
        self.tab_customize = self.tabview.add("🎨 Tùy Chỉnh")
        self.tab_filters = self.tabview.add("✨ Bộ Lọc & Chữ")
        self.tab_export = self.tabview.add("💾 Xuất Ảnh")

        self._build_tab_grid_layouts()
        self._build_tab_outer_frames()
        self._build_tab_customize()
        self._build_tab_filters()
        self._build_tab_export()

    # =============================================================
    # TAB LIST 1: MẪU KHUNG ẢNH LƯỚI (COLLAGE & GRID LAYOUTS)
    # =============================================================
    def _build_tab_grid_layouts(self):
        # 1. Photo Count Selector: [ 1 Ảnh ] [ 2 Ảnh ] [ 3 Ảnh ] [ 4 Ảnh ] [ 5 Ảnh ] [ 6 Ảnh ]
        top_frame = ctk.CTkFrame(self.tab_grid_layouts, fg_color="transparent")
        top_frame.pack(fill="x", pady=(2, 6))

        ctk.CTkLabel(
            top_frame,
            text="Chọn số lượng ảnh trong khung lưới:",
            font=ctk.CTkFont(size=11, weight="bold"),
            text_color="#93C5FD"
        ).pack(anchor="w", pady=(0, 2))

        self.count_segmented = ctk.CTkSegmentedButton(
            top_frame,
            values=["1 Ảnh", "2 Ảnh", "3 Ảnh", "4 Ảnh", "5 Ảnh", "6 Ảnh"],
            font=ctk.CTkFont(size=11, weight="bold"),
            selected_color="#2563EB",
            command=self._on_photo_count_changed
        )
        self.count_segmented.set("1 Ảnh")
        self.count_segmented.pack(fill="x")

        # 2. Scrollable List of Layout Cards
        self.grid_cards_scroll = ctk.CTkScrollableFrame(
            self.tab_grid_layouts,
            fg_color="#0F0F12",
            corner_radius=8
        )
        self.grid_cards_scroll.pack(fill="both", expand=True, pady=(2, 2))

        self._refresh_grid_layout_cards()

    def _on_photo_count_changed(self, val: str):
        count = int(val.split()[0])
        self.current_photo_count = count

        # Pick default layout for this count
        layouts = get_layouts_by_photo_count(count)
        if layouts:
            self.current_collage_layout_id = layouts[0].id
            self.params["aspect_preset"] = layouts[0].aspect_preset

        mode = "single" if count == 1 else "collage"
        self.on_mode_change(mode)
        self.on_collage_layout_change(self.current_collage_layout_id)

        self._refresh_grid_layout_cards()
        self._sync_customize_controls()

    def _refresh_grid_layout_cards(self):
        for w in self.grid_cards_scroll.winfo_children():
            w.destroy()

        layouts = get_layouts_by_photo_count(self.current_photo_count)
        for layout in layouts:
            card = CollageCard(
                self.grid_cards_scroll,
                layout=layout,
                is_selected=(layout.id == self.current_collage_layout_id),
                on_select=self.select_grid_layout
            )
            card.pack(fill="x", pady=3)

    def select_grid_layout(self, layout_id: str):
        self.current_collage_layout_id = layout_id
        layout = COLLAGE_LAYOUTS[layout_id]
        self.params["aspect_preset"] = layout.aspect_preset

        mode = "single" if layout.photo_count == 1 else "collage"
        self.on_mode_change(mode)
        self.on_collage_layout_change(layout_id)

        self._refresh_grid_layout_cards()
        self._sync_customize_controls()

    # =============================================================
    # TAB LIST 2: KIỂU KHUNG VIỀN BỌC NGOÀI (OUTER FRAME BORDERS)
    # =============================================================
    def _build_tab_outer_frames(self):
        # Category Selector
        cat_frame = ctk.CTkFrame(self.tab_outer_frames, fg_color="transparent")
        cat_frame.pack(fill="x", pady=(2, 6))

        ctk.CTkLabel(
            cat_frame,
            text="Danh mục khung viền nghệ thuật:",
            font=ctk.CTkFont(size=11, weight="bold"),
            text_color="#C084FC"
        ).pack(anchor="w", pady=(0, 2))

        cats = ["Tất cả", "Cổ Điển & Sang Trọng", "Hiện Đại & Tinh Tế", "Hoài Niệm & Nghệ Thuật", "Tạp Chí & Thời Trang"]
        self.outer_cat_menu = ctk.CTkOptionMenu(
            cat_frame,
            values=cats,
            fg_color="#27272A",
            button_color="#3F3F46",
            command=self._on_outer_category_changed
        )
        self.outer_cat_menu.set(self.current_outer_category)
        self.outer_cat_menu.pack(fill="x")

        # Scrollable Frame Cards
        self.outer_frames_scroll = ctk.CTkScrollableFrame(
            self.tab_outer_frames,
            fg_color="#0F0F12",
            corner_radius=8
        )
        self.outer_frames_scroll.pack(fill="both", expand=True, pady=(2, 2))

        self._refresh_outer_frame_cards()

    def _on_outer_category_changed(self, cat: str):
        self.current_outer_category = cat
        self._refresh_outer_frame_cards()

    def _refresh_outer_frame_cards(self):
        for w in self.outer_frames_scroll.winfo_children():
            w.destroy()

        for tid, tmpl in TEMPLATES.items():
            if self.current_outer_category != "Tất cả" and tmpl.category != self.current_outer_category:
                continue

            card = TemplateCard(
                self.outer_frames_scroll,
                template=tmpl,
                is_selected=(tid == self.current_template_id),
                on_select=self.select_outer_frame
            )
            card.pack(fill="x", pady=3)

    def select_outer_frame(self, template_id: str):
        self.current_template_id = template_id
        tmpl = TEMPLATES[template_id]

        self.params["border_ratio"] = tmpl.default_border_ratio
        self.params["mat_ratio"] = tmpl.default_mat_ratio
        self.params["frame_color"] = tmpl.default_frame_color
        self.params["mat_color"] = tmpl.default_mat_color
        self.params["has_shadow"] = tmpl.has_shadow
        self.params["caption_text"] = tmpl.default_caption

        self._refresh_outer_frame_cards()
        self._sync_customize_controls()
        self._update_caption_ui()

        self.on_template_change(template_id)
        self._notify_param_change()

    # =============================================================
    # TAB 3: TÙY CHỈNH (CUSTOMIZE)
    # =============================================================
    def _build_tab_customize(self):
        self.cust_scroll = ctk.CTkScrollableFrame(self.tab_customize, fg_color="transparent")
        self.cust_scroll.pack(fill="both", expand=True, pady=4)
        self._sync_customize_controls()

    def _sync_customize_controls(self):
        for w in self.cust_scroll.winfo_children():
            w.destroy()

        scroll = self.cust_scroll

        # 1. COLLAGE GRID CONTROLS (when > 1 photo)
        if self.current_photo_count > 1:
            ctk.CTkLabel(scroll, text="📐 THIẾT LẬP KHE ẢNH LƯỚI", font=ctk.CTkFont(size=12, weight="bold"), text_color="#60A5FA").pack(anchor="w", pady=(2, 6))

            # Gap Size Slider
            ctk.CTkLabel(scroll, text="Khoảng cách giữa các ảnh (Grid Gap):", font=ctk.CTkFont(size=11, weight="bold")).pack(anchor="w", pady=(2, 2))
            self.gap_slider = ctk.CTkSlider(
                scroll, from_=0, to=30, number_of_steps=30,
                command=lambda v: self._update_param("gap_size", int(v))
            )
            self.gap_slider.set(self.params.get("gap_size", 10))
            self.gap_slider.pack(fill="x", pady=(0, 10))

            # Cell Corner Radius Slider
            ctk.CTkLabel(scroll, text="Bo tròn góc từng ô ảnh trong lưới:", font=ctk.CTkFont(size=11, weight="bold")).pack(anchor="w", pady=(2, 2))
            self.cell_corner_slider = ctk.CTkSlider(
                scroll, from_=0, to=35, number_of_steps=35,
                command=lambda v: self._update_param("cell_corner_radius", int(v))
            )
            self.cell_corner_slider.set(self.params.get("cell_corner_radius", 4))
            self.cell_corner_slider.pack(fill="x", pady=(0, 10))

            # Grid Background Color Picker Row
            bgcol_row = ctk.CTkFrame(scroll, fg_color="transparent")
            bgcol_row.pack(fill="x", pady=(0, 12))
            ctk.CTkLabel(bgcol_row, text="Màu nền khe:", width=90, anchor="w").pack(side="left")
            self.grid_bg_indicator = ctk.CTkButton(
                bgcol_row, text="", width=32, height=24, corner_radius=6,
                fg_color=self.params.get("grid_bg_color", "#FFFFFF"), command=self._pick_grid_bg_color
            )
            self.grid_bg_indicator.pack(side="left", padx=6)
            btn_bgcol = ctk.CTkButton(
                bgcol_row, text="Chọn màu khe...", width=110, height=24,
                fg_color="#27272A", hover_color="#3F3F46", command=self._pick_grid_bg_color
            )
            btn_bgcol.pack(side="left", padx=4)

            # Divider
            div = ctk.CTkFrame(scroll, height=2, fg_color="#3F3F46")
            div.pack(fill="x", pady=(2, 10))

        # 2. OUTER FRAME CONTROLS
        header_text = "🖼️ THIẾT LẬP KHUNG VIỀN BỌC NGOÀI"
        ctk.CTkLabel(scroll, text=header_text, font=ctk.CTkFont(size=12, weight="bold"), text_color="#A78BFA").pack(anchor="w", pady=(2, 6))

        # Aspect Ratio
        ctk.CTkLabel(scroll, text="Tỉ lệ khung hình (Aspect Ratio):", font=ctk.CTkFont(size=11, weight="bold")).pack(anchor="w", pady=(2, 2))
        self.aspect_menu = ctk.CTkSegmentedButton(
            scroll,
            values=["Gốc", "1:1", "4:5", "3:4", "9:16", "16:9"],
            command=self._on_aspect_change
        )
        rev_aspect = {"original": "Gốc", "1:1": "1:1", "4:5": "4:5", "3:4": "3:4", "9:16": "9:16", "16:9": "16:9"}
        self.aspect_menu.set(rev_aspect.get(self.params.get("aspect_preset", "original"), "Gốc"))
        self.aspect_menu.pack(fill="x", pady=(0, 10))

        # Border Width Slider
        ctk.CTkLabel(scroll, text="Độ dày viền ngoài (Border Width):", font=ctk.CTkFont(size=11, weight="bold")).pack(anchor="w", pady=(2, 2))
        self.border_slider = ctk.CTkSlider(
            scroll, from_=0.0, to=0.15, number_of_steps=30,
            command=lambda v: self._update_param("border_ratio", round(v, 3))
        )
        self.border_slider.set(self.params["border_ratio"])
        self.border_slider.pack(fill="x", pady=(0, 10))

        # Mat Padding Slider
        ctk.CTkLabel(scroll, text="Khoảng cách lót viền (Matte Margin):", font=ctk.CTkFont(size=11, weight="bold")).pack(anchor="w", pady=(2, 2))
        self.mat_slider = ctk.CTkSlider(
            scroll, from_=0.0, to=0.22, number_of_steps=40,
            command=lambda v: self._update_param("mat_ratio", round(v, 3))
        )
        self.mat_slider.set(self.params["mat_ratio"])
        self.mat_slider.pack(fill="x", pady=(0, 10))

        # Drop Shadow Switch
        self.shadow_switch = ctk.CTkSwitch(
            scroll, text="Hiệu ứng đổ bóng 3D (Drop Shadow)",
            command=lambda: self._update_param("has_shadow", bool(self.shadow_switch.get()))
        )
        if self.params["has_shadow"]:
            self.shadow_switch.select()
        else:
            self.shadow_switch.deselect()
        self.shadow_switch.pack(anchor="w", pady=(6, 12))

        # Colors Section
        ctk.CTkLabel(scroll, text="Màu sắc Khung & Đệm Viền:", font=ctk.CTkFont(size=11, weight="bold")).pack(anchor="w", pady=(2, 4))
        
        # Frame Color Picker Row
        fcol_row = ctk.CTkFrame(scroll, fg_color="transparent")
        fcol_row.pack(fill="x", pady=3)
        ctk.CTkLabel(fcol_row, text="Màu Khung:", width=80, anchor="w").pack(side="left")
        self.fcol_indicator = ctk.CTkButton(
            fcol_row, text="", width=32, height=24, corner_radius=6,
            fg_color=self.params["frame_color"], command=self._pick_frame_color
        )
        self.fcol_indicator.pack(side="left", padx=6)
        btn_fcol = ctk.CTkButton(
            fcol_row, text="Chọn màu...", width=90, height=24,
            fg_color="#27272A", hover_color="#3F3F46", command=self._pick_frame_color
        )
        btn_fcol.pack(side="left", padx=4)

        # Mat Color Picker Row
        mcol_row = ctk.CTkFrame(scroll, fg_color="transparent")
        mcol_row.pack(fill="x", pady=3)
        ctk.CTkLabel(mcol_row, text="Màu Lót:", width=80, anchor="w").pack(side="left")
        self.mcol_indicator = ctk.CTkButton(
            mcol_row, text="", width=32, height=24, corner_radius=6,
            fg_color=self.params["mat_color"], command=self._pick_mat_color
        )
        self.mcol_indicator.pack(side="left", padx=6)
        btn_mcol = ctk.CTkButton(
            mcol_row, text="Chọn màu...", width=90, height=24,
            fg_color="#27272A", hover_color="#3F3F46", command=self._pick_mat_color
        )
        btn_mcol.pack(side="left", padx=4)

    def _on_aspect_change(self, val: str):
        mapping = {"Gốc": "original", "1:1": "1:1", "4:5": "4:5", "3:4": "3:4", "9:16": "9:16", "16:9": "16:9"}
        self._update_param("aspect_preset", mapping.get(val, "original"))

    def _pick_grid_bg_color(self):
        col = pick_color(self, self.params.get("grid_bg_color", "#FFFFFF"))
        if col:
            self.params["grid_bg_color"] = col
            self.grid_bg_indicator.configure(fg_color=col)
            self._notify_param_change()

    def _pick_frame_color(self):
        col = pick_color(self, self.params["frame_color"])
        if col:
            self.params["frame_color"] = col
            self.fcol_indicator.configure(fg_color=col)
            self._notify_param_change()

    def _pick_mat_color(self):
        col = pick_color(self, self.params["mat_color"])
        if col:
            self.params["mat_color"] = col
            self.mcol_indicator.configure(fg_color=col)
            self._notify_param_change()

    # =============================================================
    # TAB 4: BỘ LỌC & CHỮ (FILTERS & TEXT)
    # =============================================================
    def _build_tab_filters(self):
        self.filters_scroll = ctk.CTkScrollableFrame(self.tab_filters, fg_color="transparent")
        self.filters_scroll.pack(fill="both", expand=True, pady=4)

        # 1. VISIBLE FILTER LIST
        ctk.CTkLabel(
            self.filters_scroll,
            text="🎨 BỘ LỌC MÀU NGHỆ THUẬT (PHOTO FILTERS):",
            font=ctk.CTkFont(size=12, weight="bold"),
            text_color="#A78BFA"
        ).pack(anchor="w", pady=(2, 6))

        self.filter_buttons = {}
        filter_icons = {
            "original": "🌈",
            "warm_film": "🌅",
            "sepia": "📜",
            "bw_classic": "🔳",
            "cool_cinematic": "🎬",
            "vivid": "🎨",
            "muted_pastel": "🌸",
            "noir_dramatic": "🌑"
        }

        for fid, name in FILTER_LIST:
            icon = filter_icons.get(fid, "✨")
            is_active = (fid == self.params.get("filter_name", "original"))
            btn = ctk.CTkButton(
                self.filters_scroll,
                text=f"{icon}  {name}" + ("   ✓" if is_active else ""),
                font=ctk.CTkFont(size=12, weight="bold" if is_active else "normal"),
                fg_color="#4F46E5" if is_active else "#27272A",
                hover_color="#4338CA" if is_active else "#3F3F46",
                anchor="w",
                height=34,
                corner_radius=6,
                command=lambda f=fid: self._on_filter_clicked(f)
            )
            btn.pack(fill="x", pady=2)
            self.filter_buttons[fid] = btn

        # Divider
        div = ctk.CTkFrame(self.filters_scroll, height=2, fg_color="#3F3F46")
        div.pack(fill="x", pady=(14, 12))

        # 2. CAPTION CONTAINER (SMART & CONDITIONAL)
        self.caption_container = ctk.CTkFrame(self.filters_scroll, fg_color="transparent")
        self.caption_container.pack(fill="x")
        self._update_caption_ui()

    def _on_filter_clicked(self, filter_id: str):
        self.params["filter_name"] = filter_id
        filter_icons = {
            "original": "🌈",
            "warm_film": "🌅",
            "sepia": "📜",
            "bw_classic": "🔳",
            "cool_cinematic": "🎬",
            "vivid": "🎨",
            "muted_pastel": "🌸",
            "noir_dramatic": "🌑"
        }
        for fid, btn in self.filter_buttons.items():
            icon = filter_icons.get(fid, "✨")
            name = next((n for f, n in FILTER_LIST if f == fid), fid)
            is_active = (fid == filter_id)
            btn.configure(
                text=f"{icon}  {name}" + ("   ✓" if is_active else ""),
                fg_color="#4F46E5" if is_active else "#27272A",
                hover_color="#4338CA" if is_active else "#3F3F46",
                font=ctk.CTkFont(size=12, weight="bold" if is_active else "normal")
            )
        self._notify_param_change()

    def _update_caption_ui(self):
        if not hasattr(self, "caption_container"):
            return

        for w in self.caption_container.winfo_children():
            w.destroy()

        tmpl = TEMPLATES.get(self.current_template_id, TEMPLATES["gold_baroque"])

        if tmpl.supports_caption:
            # FRAME SUPPORTS CAPTION
            ctk.CTkLabel(
                self.caption_container,
                text=f"✍️ CHỮ KÝ / TIÊU ĐỀ ({tmpl.name}):",
                font=ctk.CTkFont(size=12, weight="bold"),
                text_color="#60A5FA"
            ).pack(anchor="w", pady=(0, 2))

            ctk.CTkLabel(
                self.caption_container,
                text="Khung này hỗ trợ ghi tiêu đề. Bạn có thể sửa ngay bên dưới:",
                font=ctk.CTkFont(size=11),
                text_color="gray65"
            ).pack(anchor="w", pady=(0, 6))

            # Auto pre-fill with template's signature default caption
            cur_caption = self.params.get("caption_text", "")
            if not cur_caption:
                cur_caption = tmpl.default_caption
                self.params["caption_text"] = cur_caption

            self.caption_entry = ctk.CTkEntry(
                self.caption_container,
                placeholder_text="Nhập tiêu đề hoặc chữ ký...",
                height=36,
                font=ctk.CTkFont(size=12)
            )
            self.caption_entry.insert(0, cur_caption)
            self.caption_entry.pack(fill="x", pady=(0, 6))

            # Real-time typing key release binding
            self.caption_entry.bind("<KeyRelease>", self._on_caption_key_release)

            # Actions row
            act_row = ctk.CTkFrame(self.caption_container, fg_color="transparent")
            act_row.pack(fill="x", pady=(2, 4))

            btn_reset = ctk.CTkButton(
                act_row,
                text="↺ Khôi Phục Chữ Mẫu",
                width=135,
                height=26,
                font=ctk.CTkFont(size=11),
                fg_color="#374151",
                hover_color="#4B5563",
                command=self._reset_default_caption
            )
            btn_reset.pack(side="left", padx=(0, 4))

            btn_clear = ctk.CTkButton(
                act_row,
                text="✕ Xóa Chữ",
                width=80,
                height=26,
                font=ctk.CTkFont(size=11),
                fg_color="#27272A",
                hover_color="#EF4444",
                command=self._clear_caption
            )
            btn_clear.pack(side="left", padx=4)

        else:
            # FRAME DOES NOT SUPPORT CAPTION
            info_box = ctk.CTkFrame(self.caption_container, fg_color="#27272A", corner_radius=8)
            info_box.pack(fill="x", pady=(0, 4))

            ctk.CTkLabel(
                info_box,
                text=f"ℹ️ Khung viền \"{tmpl.name}\" không sử dụng chữ.",
                font=ctk.CTkFont(size=11, weight="bold"),
                text_color="#A1A1AA"
            ).pack(anchor="w", padx=10, pady=(8, 2))

            ctk.CTkLabel(
                info_box,
                text="💡 Gợi ý: Chọn các mẫu như Polaroid, Bìa Tạp Chí Vogue,\nKhung Triển Lãm, Cuộn Phim 35mm, Tem Thư để thêm chữ.",
                font=ctk.CTkFont(size=10),
                text_color="gray60",
                justify="left"
            ).pack(anchor="w", padx=10, pady=(0, 8))

    def _on_caption_key_release(self, event=None):
        if hasattr(self, "caption_entry"):
            text = self.caption_entry.get()
            self.params["caption_text"] = text
            self._notify_param_change()

    def _reset_default_caption(self):
        tmpl = TEMPLATES.get(self.current_template_id)
        if tmpl and hasattr(self, "caption_entry"):
            self.caption_entry.delete(0, "end")
            self.caption_entry.insert(0, tmpl.default_caption)
            self.params["caption_text"] = tmpl.default_caption
            self._notify_param_change()

    def _clear_caption(self):
        if hasattr(self, "caption_entry"):
            self.caption_entry.delete(0, "end")
            self.params["caption_text"] = ""
            self._notify_param_change()

    # =============================================================
    # TAB 5: XUẤT ẢNH (EXPORT)
    # =============================================================
    def _build_tab_export(self):
        scroll = ctk.CTkScrollableFrame(self.tab_export, fg_color="transparent")
        scroll.pack(fill="both", expand=True, pady=4)

        ctk.CTkLabel(scroll, text="Độ phân giải xuất ảnh:", font=ctk.CTkFont(size=12, weight="bold")).pack(anchor="w", pady=(4, 2))
        res_names = [label for key, (label, val) in EXPORT_PRESETS.items()]
        self.res_menu = ctk.CTkOptionMenu(
            scroll,
            values=res_names,
            command=self._on_res_changed,
            fg_color="#27272A",
            button_color="#3F3F46"
        )
        self.res_menu.set(res_names[0])
        self.res_menu.pack(fill="x", pady=(0, 12))

        ctk.CTkLabel(scroll, text="Định dạng xuất:", font=ctk.CTkFont(size=12, weight="bold")).pack(anchor="w", pady=(4, 2))
        self.format_menu = ctk.CTkSegmentedButton(
            scroll,
            values=["PNG", "JPG", "WEBP"],
            command=lambda f: self._update_param("export_format", f)
        )
        self.format_menu.set("PNG")
        self.format_menu.pack(fill="x", pady=(0, 12))

        ctk.CTkLabel(scroll, text="Chất lượng nén (Quality):", font=ctk.CTkFont(size=12, weight="bold")).pack(anchor="w", pady=(4, 2))
        self.qual_slider = ctk.CTkSlider(
            scroll, from_=75, to=100, number_of_steps=25,
            command=lambda v: self._update_param("jpeg_quality", int(v))
        )
        self.qual_slider.set(95)
        self.qual_slider.pack(fill="x", pady=(0, 16))

        self.btn_save_single = ctk.CTkButton(
            scroll,
            text="💾 Lưu Tác Phẩm Này (Save As)",
            font=ctk.CTkFont(size=13, weight="bold"),
            fg_color="#2563EB",
            hover_color="#1D4ED8",
            height=40,
            command=self.on_save_single
        )
        self.btn_save_single.pack(fill="x", pady=(6, 8))

        self.btn_batch = ctk.CTkButton(
            scroll,
            text="🚀 Xuất Toàn Bộ Hàng Loạt",
            font=ctk.CTkFont(size=13, weight="bold"),
            fg_color="#059669",
            hover_color="#047857",
            height=40,
            command=self.on_batch_export
        )
        self.btn_batch.pack(fill="x", pady=(0, 10))

    def _on_res_changed(self, display_label: str):
        for key, (label, val) in EXPORT_PRESETS.items():
            if label == display_label:
                self._update_param("export_res", key)
                break

    # =============================================================
    # Helpers
    # =============================================================
    def _update_param(self, key: str, value: Any):
        self.params[key] = value
        self._notify_param_change()

    def _notify_param_change(self):
        if self.on_param_change:
            self.on_param_change(self.params)
