"""
PhotoFrameFancy - Interactive Canvas View
Clean artwork preview by default. Only activates Zoom & Pan/Move editing mode
when the user DOUBLE-CLICKS on a specific photo slot.
"""

import tkinter as tk
import customtkinter as ctk
from PIL import Image, ImageTk
from typing import Optional, Callable, Dict, Any, List, Tuple


class CanvasView(ctk.CTkFrame):
    def __init__(
        self,
        parent,
        on_transform_change: Optional[Callable[[Dict[str, Any]], None]] = None,
        on_slot_selected: Optional[Callable[[int], None]] = None,
        on_pick_file: Optional[Callable[[], None]] = None,
        on_load_demo: Optional[Callable[[], None]] = None
    ):
        super().__init__(parent, fg_color="#18181B", corner_radius=12)
        
        self.on_transform_change = on_transform_change
        self.on_slot_selected = on_slot_selected
        self.on_pick_file = on_pick_file
        self.on_load_demo = on_load_demo

        self.current_preview_image: Optional[Image.Image] = None
        self.tk_photo: Optional[ImageTk.PhotoImage] = None

        # Slot state & geometry
        self.selected_slot: int = 0
        self.is_slot_editing: bool = False
        self.slot_rects: List[Tuple[float, float, float, float]] = []
        self.slot_transforms: Dict[int, Dict[str, Any]] = {}

        self._drag_start_x = 0
        self._drag_start_y = 0
        self._is_dragging = False
        self._throttle_timer: Optional[str] = None
        self._wheel_release_timer: Optional[str] = None

        self._build_ui()

    def _build_ui(self):
        # 1. Top floating action toolbar
        self.toolbar = ctk.CTkFrame(self, fg_color="#27272A", height=42, corner_radius=8)
        self.toolbar.pack(fill="x", padx=14, pady=(12, 6))

        # Slot Indicator / Mode Badge
        self.slot_indicator_lbl = ctk.CTkLabel(
            self.toolbar,
            text="💡 Nhấp đúp (Double-click) vào ảnh để Zoom/Dời",
            font=ctk.CTkFont(size=11),
            text_color="#A1A1AA",
            fg_color="transparent",
            corner_radius=6,
            padx=8,
            pady=2
        )
        self.slot_indicator_lbl.pack(side="left", padx=(8, 4), pady=6)

        # Rotate buttons
        self.btn_rot_left = ctk.CTkButton(
            self.toolbar, text="↺ Xoay", width=65, height=28,
            fg_color="#3F3F46", hover_color="#52525B", command=self._rotate_left
        )
        self.btn_rot_left.pack(side="left", padx=2, pady=6)

        self.btn_rot_right = ctk.CTkButton(
            self.toolbar, text="↻ Xoay", width=65, height=28,
            fg_color="#3F3F46", hover_color="#52525B", command=self._rotate_right
        )
        self.btn_rot_right.pack(side="left", padx=2, pady=6)

        # Flip buttons
        self.btn_flip_h = ctk.CTkButton(
            self.toolbar, text="⇄ Ngang", width=70, height=28,
            fg_color="#3F3F46", hover_color="#52525B", command=self._toggle_flip_h
        )
        self.btn_flip_h.pack(side="left", padx=2, pady=6)

        self.btn_flip_v = ctk.CTkButton(
            self.toolbar, text="⇅ Dọc", width=65, height=28,
            fg_color="#3F3F46", hover_color="#52525B", command=self._toggle_flip_v
        )
        self.btn_flip_v.pack(side="left", padx=2, pady=6)

        # Separator
        self.toolbar_sep = ctk.CTkLabel(self.toolbar, text="|", text_color="gray50")
        self.toolbar_sep.pack(side="left", padx=4)

        # Zoom controls
        self.zoom_lbl = ctk.CTkLabel(self.toolbar, text="Zoom: 100%", font=ctk.CTkFont(size=12))
        self.zoom_lbl.pack(side="left", padx=4)

        self.btn_zoom_out = ctk.CTkButton(
            self.toolbar, text="−", width=30, height=28,
            fg_color="#3F3F46", hover_color="#52525B", command=self._zoom_out
        )
        self.btn_zoom_out.pack(side="left", padx=2)

        self.btn_zoom_in = ctk.CTkButton(
            self.toolbar, text="+", width=30, height=28,
            fg_color="#3F3F46", hover_color="#52525B", command=self._zoom_in
        )
        self.btn_zoom_in.pack(side="left", padx=2)

        # Done button (appears only when editing a slot)
        self.btn_done = ctk.CTkButton(
            self.toolbar, text="✓ Hoàn Tất", width=85, height=28,
            fg_color="#059669", hover_color="#047857", text_color="#FFFFFF",
            font=ctk.CTkFont(size=12, weight="bold"),
            command=self.exit_slot_editing
        )
        # Hidden by default until double-click
        
        # Reset button
        self.btn_reset = ctk.CTkButton(
            self.toolbar, text="🎯 Đặt Lại", width=75, height=28,
            fg_color="#4F46E5", hover_color="#4338CA", command=self._reset_transform
        )
        self.btn_reset.pack(side="right", padx=8, pady=6)

        # 2. Main Canvas area
        self.canvas_container = ctk.CTkFrame(self, fg_color="#0F0F12", corner_radius=10)
        self.canvas_container.pack(fill="both", expand=True, padx=14, pady=(0, 12))

        self.tk_canvas = tk.Canvas(
            self.canvas_container,
            bg="#0F0F12",
            highlightthickness=0,
            cursor="arrow"
        )
        self.tk_canvas.pack(fill="both", expand=True)

        # Event bindings
        self.tk_canvas.bind("<Configure>", self._on_canvas_resize)
        self.tk_canvas.bind("<Double-Button-1>", self._on_canvas_double_click)
        self.tk_canvas.bind("<ButtonPress-1>", self._on_canvas_press)
        self.tk_canvas.bind("<B1-Motion>", self._on_canvas_drag)
        self.tk_canvas.bind("<ButtonRelease-1>", self._on_canvas_release)
        self.tk_canvas.bind("<MouseWheel>", self._on_mouse_wheel)
        self.tk_canvas.bind("<Motion>", self._on_mouse_move)

        # Press Escape on canvas to exit edit mode
        self.tk_canvas.bind("<Escape>", lambda e: self.exit_slot_editing())
        self.after(500, self._setup_escape_binding)

        # 3. Placeholder
        self._show_empty_placeholder()

    def _show_empty_placeholder(self):
        self.tk_canvas.delete("all")
        cw = self.tk_canvas.winfo_width() or 600
        ch = self.tk_canvas.winfo_height() or 500

        self.tk_canvas.create_text(
            cw // 2, ch // 2 - 50,
            text="🖼️",
            font=("Segoe UI Emoji", 48),
            fill="#52525B",
            tags="placeholder"
        )
        self.tk_canvas.create_text(
            cw // 2, ch // 2 + 10,
            text="Kéo & Thả ảnh vào đây, hoặc chọn ảnh để bắt đầu lồng khung",
            font=("Segoe UI", 13, "bold"),
            fill="#A1A1AA",
            tags="placeholder"
        )
        self.tk_canvas.create_text(
            cw // 2, ch // 2 + 38,
            text="Mẹo: Nhấp đúp (Double-click) vào ảnh bất kỳ để tùy chỉnh Zoom & Di chuyển (Move/Pan)",
            font=("Segoe UI", 11),
            fill="#71717A",
            tags="placeholder"
        )

    # -------------------------------------------------------------
    # Image & Slot Geometry Management
    # -------------------------------------------------------------
    def set_rendered_image(self, img: Optional[Image.Image]):
        self.current_preview_image = img
        if img is not None:
            if "slot_rects" in img.info:
                self.slot_rects = img.info["slot_rects"]
            elif not self.slot_rects:
                self.slot_rects = [(0.0, 0.0, 1.0, 1.0)]
            if self.slot_rects:
                self.selected_slot = min(self.selected_slot, len(self.slot_rects) - 1)
        else:
            self.slot_rects = []
            self.is_slot_editing = False

        self._render_to_canvas()
        self._update_toolbar_slot_info()

    def get_slot_transform(self, slot_idx: int) -> Dict[str, Any]:
        if slot_idx not in self.slot_transforms:
            self.slot_transforms[slot_idx] = {
                "zoom": 1.0,
                "pan_x": 0.0,
                "pan_y": 0.0,
                "rotation": 0,
                "flip_h": False,
                "flip_v": False,
            }
        return self.slot_transforms[slot_idx]

    def reset_all_transforms(self):
        self.slot_transforms.clear()
        self.selected_slot = 0
        self.is_slot_editing = False
        self._update_toolbar_slot_info()
        self._render_to_canvas()
        self._notify_transform()

    def _get_display_geometry(self) -> Tuple[int, int, int, int]:
        """Returns (img_x0, img_y0, disp_w, disp_h) for current canvas size."""
        if self.current_preview_image is None:
            return 0, 0, 0, 0
        cw = self.tk_canvas.winfo_width()
        ch = self.tk_canvas.winfo_height()
        iw, ih = self.current_preview_image.size
        pad = 28
        scale = min(max(10, cw - pad * 2) / iw, max(10, ch - pad * 2) / ih)
        disp_w = max(1, int(iw * scale))
        disp_h = max(1, int(ih * scale))
        img_x0 = (cw - disp_w) // 2
        img_y0 = (ch - disp_h) // 2
        return img_x0, img_y0, disp_w, disp_h

    def _find_slot_at(self, nx: float, ny: float) -> Optional[int]:
        """Finds which slot index contains normalized coordinate (nx, ny)."""
        if not self.slot_rects:
            return None
        for idx, (sx0, sy0, sx1, sy1) in enumerate(self.slot_rects):
            if sx0 <= nx <= sx1 and sy0 <= ny <= sy1:
                return idx

        # Slight tolerance for grid gaps
        min_dist = float("inf")
        closest = None
        for idx, (sx0, sy0, sx1, sy1) in enumerate(self.slot_rects):
            cx = (sx0 + sx1) / 2
            cy = (sy0 + sy1) / 2
            d = (nx - cx) ** 2 + (ny - cy) ** 2
            if d < min_dist:
                min_dist = d
                closest = idx
        if min_dist < 0.25:
            return closest
        return None

    # -------------------------------------------------------------
    # Edit Mode Entry & Exit
    # -------------------------------------------------------------
    def enter_slot_editing(self, slot_idx: int):
        """Activates interactive Zoom & Move/Pan for the specified slot."""
        if self.slot_rects:
            self.selected_slot = max(0, min(slot_idx, len(self.slot_rects) - 1))
        else:
            self.selected_slot = max(0, slot_idx)

        self.is_slot_editing = True
        self._update_toolbar_slot_info()
        self._draw_selection_overlay()

    def exit_slot_editing(self):
        """Exits slot editing mode, returning to pristine clean preview."""
        if not self.is_slot_editing:
            return
        if self._throttle_timer is not None:
            self.after_cancel(self._throttle_timer)
            self._throttle_timer = None
        if self._wheel_release_timer is not None:
            self.after_cancel(self._wheel_release_timer)
            self._wheel_release_timer = None
        self.is_slot_editing = False
        self._is_dragging = False
        self.tk_canvas.delete("selection_overlay")
        self.tk_canvas.configure(cursor="arrow")
        self._update_toolbar_slot_info()

    def _setup_escape_binding(self):
        try:
            top = self.winfo_toplevel()
            if top:
                top.bind("<Escape>", lambda e: self.exit_slot_editing(), add="+")
        except Exception:
            pass

    def set_selected_slot(self, slot_idx: int):
        """Sets the selected slot without forcing edit mode."""
        if self.slot_rects:
            self.selected_slot = max(0, min(slot_idx, len(self.slot_rects) - 1))
        else:
            self.selected_slot = max(0, slot_idx)

        self._update_toolbar_slot_info()
        if self.is_slot_editing:
            self._draw_selection_overlay()

    # -------------------------------------------------------------
    # Canvas Rendering & Overlay
    # -------------------------------------------------------------
    def _render_to_canvas(self):
        if self.current_preview_image is None:
            self._show_empty_placeholder()
            return

        cw = self.tk_canvas.winfo_width()
        ch = self.tk_canvas.winfo_height()
        if cw < 50 or ch < 50:
            return

        img_x0, img_y0, disp_w, disp_h = self._get_display_geometry()
        disp_img = self.current_preview_image.resize((disp_w, disp_h), Image.Resampling.BILINEAR)
        self.tk_photo = ImageTk.PhotoImage(disp_img)

        cx = cw // 2
        cy = ch // 2
        art_items = self.tk_canvas.find_withtag("preview_art")
        if art_items:
            self.tk_canvas.itemconfigure("preview_art", image=self.tk_photo)
            self.tk_canvas.coords("preview_art", cx, cy)
        else:
            self.tk_canvas.delete("placeholder")
            self.tk_canvas.create_image(cx, cy, image=self.tk_photo, anchor="center", tags="preview_art")

        # ONLY draw selection overlay when currently in slot editing mode!
        if self.is_slot_editing:
            self._draw_selection_overlay()
        else:
            self.tk_canvas.delete("selection_overlay")

    def _draw_selection_overlay(self):
        self.tk_canvas.delete("selection_overlay")
        if not self.is_slot_editing or self.current_preview_image is None or not self.slot_rects:
            return
        if not (0 <= self.selected_slot < len(self.slot_rects)):
            return

        img_x0, img_y0, disp_w, disp_h = self._get_display_geometry()
        sx0, sy0, sx1, sy1 = self.slot_rects[self.selected_slot]
        x0 = int(img_x0 + sx0 * disp_w)
        y0 = int(img_y0 + sy0 * disp_h)
        x1 = int(img_x0 + sx1 * disp_w)
        y1 = int(img_y0 + sy1 * disp_h)

        outline_color = "#6366F1"  # Indigo-500
        glow_color = "#818CF8"     # Indigo-400
        
        # Outer subtle glow
        self.tk_canvas.create_rectangle(
            x0 - 1, y0 - 1, x1 + 1, y1 + 1,
            outline=glow_color, width=1, tags="selection_overlay"
        )
        # Main vibrant selection border
        self.tk_canvas.create_rectangle(
            x0, y0, x1, y1,
            outline=outline_color, width=2, tags="selection_overlay"
        )

        # 4 Corner Accent Brackets
        bracket_len = min(18, max(8, (x1 - x0) // 5))
        bw = 3
        # Top-Left
        self.tk_canvas.create_line(x0 - 1, y0, x0 + bracket_len, y0, fill="#FFFFFF", width=bw, tags="selection_overlay")
        self.tk_canvas.create_line(x0, y0 - 1, x0, y0 + bracket_len, fill="#FFFFFF", width=bw, tags="selection_overlay")
        # Top-Right
        self.tk_canvas.create_line(x1 - bracket_len, y0, x1 + 1, y0, fill="#FFFFFF", width=bw, tags="selection_overlay")
        self.tk_canvas.create_line(x1, y0 - 1, x1, y0 + bracket_len, fill="#FFFFFF", width=bw, tags="selection_overlay")
        # Bottom-Left
        self.tk_canvas.create_line(x0 - 1, y1, x0 + bracket_len, y1, fill="#FFFFFF", width=bw, tags="selection_overlay")
        self.tk_canvas.create_line(x0, y1 - bracket_len, x0, y1 + 1, fill="#FFFFFF", width=bw, tags="selection_overlay")
        # Bottom-Right
        self.tk_canvas.create_line(x1 - bracket_len, y1, x1 + 1, y1, fill="#FFFFFF", width=bw, tags="selection_overlay")
        self.tk_canvas.create_line(x1, y1 - bracket_len, x1, y1 + 1, fill="#FFFFFF", width=bw, tags="selection_overlay")

        # Floating Active Edit Badge
        trans = self.get_slot_transform(self.selected_slot)
        zoom_pct = int(trans.get("zoom", 1.0) * 100)
        pan_x = trans.get("pan_x", 0.0)
        pan_y = trans.get("pan_y", 0.0)
        has_pan = (abs(pan_x) > 0.02 or abs(pan_y) > 0.02)

        if len(self.slot_rects) > 1:
            badge_text = f"✦ Đang sửa Ô #{self.selected_slot + 1} • Zoom {zoom_pct}%"
        else:
            badge_text = f"✦ Đang sửa ảnh • Zoom {zoom_pct}%"
        if has_pan:
            badge_text += " • Đã dời vị trí"

        bx0 = x0 + 10
        by0 = y0 + 10
        text_w = len(badge_text) * 7 + 16
        self.tk_canvas.create_rectangle(
            bx0, by0, bx0 + text_w, by0 + 24,
            fill="#1E1B4B", outline="#4F46E5", width=1, tags="selection_overlay"
        )
        self.tk_canvas.create_text(
            bx0 + 8, by0 + 12,
            text=badge_text,
            anchor="w",
            font=("Segoe UI", 9, "bold"),
            fill="#E0E7FF",
            tags="selection_overlay"
        )
        self.tk_canvas.tag_raise("selection_overlay")

    def _schedule_throttled_notify(self, delay_ms: int = 25):
        if self._throttle_timer is not None:
            return
        self._throttle_timer = self.after(delay_ms, self._fire_throttled_notify)

    def _fire_throttled_notify(self):
        self._throttle_timer = None
        self._notify_transform()

    # -------------------------------------------------------------
    # Mouse & Event Handlers
    # -------------------------------------------------------------
    def _on_canvas_resize(self, event):
        self._render_to_canvas()

    def _on_canvas_double_click(self, event):
        """DOUBLE CLICK: Only trigger that enters per-photo Zoom & Move/Pan edit mode!"""
        if self.current_preview_image is None or not self.slot_rects:
            return

        img_x0, img_y0, disp_w, disp_h = self._get_display_geometry()
        nx = (event.x - img_x0) / disp_w
        ny = (event.y - img_y0) / disp_h

        clicked_slot = self._find_slot_at(nx, ny)
        if clicked_slot is not None:
            self.enter_slot_editing(clicked_slot)
            if self.on_slot_selected:
                self.on_slot_selected(clicked_slot)

    def _on_canvas_press(self, event):
        if self.current_preview_image is None or not self.slot_rects:
            return

        img_x0, img_y0, disp_w, disp_h = self._get_display_geometry()
        # If click is outside displayed image on canvas background
        if not (img_x0 <= event.x <= img_x0 + disp_w and img_y0 <= event.y <= img_y0 + disp_h):
            if self.is_slot_editing:
                self.exit_slot_editing()
            return

        nx = (event.x - img_x0) / disp_w
        ny = (event.y - img_y0) / disp_h
        clicked_slot = self._find_slot_at(nx, ny)

        # IF NOT IN EDITING MODE: Keep pristine, do not drag or pan!
        if not self.is_slot_editing:
            return

        # IF ALREADY IN EDITING MODE:
        if clicked_slot is not None:
            if clicked_slot != self.selected_slot:
                self.enter_slot_editing(clicked_slot)
                if self.on_slot_selected:
                    self.on_slot_selected(clicked_slot)
            self._drag_start_x = event.x
            self._drag_start_y = event.y
            self._is_dragging = True
        else:
            # Clicked outside slots on outer frame border -> exit editing
            self.exit_slot_editing()

    def _on_canvas_drag(self, event):
        # Dragging ONLY moves photo when in active slot editing mode!
        if not self.is_slot_editing or not self._is_dragging:
            return
        if self.current_preview_image is None or not self.slot_rects:
            return

        img_x0, img_y0, disp_w, disp_h = self._get_display_geometry()
        if 0 <= self.selected_slot < len(self.slot_rects):
            sx0, sy0, sx1, sy1 = self.slot_rects[self.selected_slot]
            slot_w_px = max(60, (sx1 - sx0) * disp_w)
            slot_h_px = max(60, (sy1 - sy0) * disp_h)
        else:
            slot_w_px = max(60, disp_w)
            slot_h_px = max(60, disp_h)

        dx = event.x - self._drag_start_x
        dy = event.y - self._drag_start_y

        trans = self.get_slot_transform(self.selected_slot)
        sensitivity = 1.6
        trans["pan_x"] = max(-1.0, min(1.0, trans["pan_x"] - (dx / slot_w_px) * sensitivity))
        trans["pan_y"] = max(-1.0, min(1.0, trans["pan_y"] - (dy / slot_h_px) * sensitivity))

        self._drag_start_x = event.x
        self._drag_start_y = event.y

        self._draw_selection_overlay()
        self._schedule_throttled_notify(delay_ms=25)

    def _on_canvas_release(self, event):
        if self._throttle_timer is not None:
            self.after_cancel(self._throttle_timer)
            self._throttle_timer = None
        self._is_dragging = False
        # Immediate notification upon release renders at crisp full resolution
        self._notify_transform()

    def _on_mouse_wheel(self, event):
        # Mouse wheel ONLY zooms when in active slot editing mode!
        if not self.is_slot_editing:
            return

        self._is_dragging = True
        delta = 0.08 if event.delta > 0 else -0.08
        trans = self.get_slot_transform(self.selected_slot)
        trans["zoom"] = max(1.0, min(3.0, round(trans["zoom"] + delta, 2)))
        self._update_toolbar_slot_info()
        self._draw_selection_overlay()
        self._schedule_throttled_notify(delay_ms=25)

        if self._wheel_release_timer is not None:
            self.after_cancel(self._wheel_release_timer)
        self._wheel_release_timer = self.after(180, self._on_wheel_settled)

    def _on_wheel_settled(self):
        self._wheel_release_timer = None
        self._is_dragging = False
        self._notify_transform()

    def _on_mouse_move(self, event):
        if self.current_preview_image is None or not self.slot_rects:
            self.tk_canvas.configure(cursor="arrow")
            return

        img_x0, img_y0, disp_w, disp_h = self._get_display_geometry()
        nx = (event.x - img_x0) / disp_w
        ny = (event.y - img_y0) / disp_h
        slot_under_cursor = self._find_slot_at(nx, ny)

        if self.is_slot_editing:
            if slot_under_cursor == self.selected_slot:
                self.tk_canvas.configure(cursor="fleur")
            elif slot_under_cursor is not None:
                self.tk_canvas.configure(cursor="hand2")
            else:
                self.tk_canvas.configure(cursor="arrow")
        else:
            # When not editing, show hand2 over slots to indicate they can be double-clicked
            if slot_under_cursor is not None:
                self.tk_canvas.configure(cursor="hand2")
            else:
                self.tk_canvas.configure(cursor="arrow")

    # -------------------------------------------------------------
    # Toolbar Quick Controls
    # -------------------------------------------------------------
    def _zoom_in(self):
        trans = self.get_slot_transform(self.selected_slot)
        trans["zoom"] = min(3.0, round(trans["zoom"] + 0.1, 2))
        self._update_toolbar_slot_info()
        if self.is_slot_editing:
            self._draw_selection_overlay()
        self._notify_transform()

    def _zoom_out(self):
        trans = self.get_slot_transform(self.selected_slot)
        trans["zoom"] = max(1.0, round(trans["zoom"] - 0.1, 2))
        self._update_toolbar_slot_info()
        if self.is_slot_editing:
            self._draw_selection_overlay()
        self._notify_transform()

    def _rotate_left(self):
        trans = self.get_slot_transform(self.selected_slot)
        trans["rotation"] = (trans["rotation"] - 90) % 360
        self._notify_transform()

    def _rotate_right(self):
        trans = self.get_slot_transform(self.selected_slot)
        trans["rotation"] = (trans["rotation"] + 90) % 360
        self._notify_transform()

    def _toggle_flip_h(self):
        trans = self.get_slot_transform(self.selected_slot)
        trans["flip_h"] = not trans["flip_h"]
        self._notify_transform()

    def _toggle_flip_v(self):
        trans = self.get_slot_transform(self.selected_slot)
        trans["flip_v"] = not trans["flip_v"]
        self._notify_transform()

    def _reset_transform(self):
        trans = self.get_slot_transform(self.selected_slot)
        trans["zoom"] = 1.0
        trans["pan_x"] = 0.0
        trans["pan_y"] = 0.0
        trans["rotation"] = 0
        trans["flip_h"] = False
        trans["flip_v"] = False
        self._update_toolbar_slot_info()
        if self.is_slot_editing:
            self._draw_selection_overlay()
        self._notify_transform()

    def _update_toolbar_slot_info(self):
        trans = self.get_slot_transform(self.selected_slot)
        zoom_pct = int(trans.get("zoom", 1.0) * 100)
        self.zoom_lbl.configure(text=f"Zoom: {zoom_pct}%")

        if self.is_slot_editing:
            if len(self.slot_rects) > 1:
                self.slot_indicator_lbl.configure(
                    text=f"✦ Đang sửa: Ô #{self.selected_slot + 1}",
                    text_color="#C7D2FE",
                    fg_color="#312E81"
                )
            else:
                self.slot_indicator_lbl.configure(
                    text="✦ Đang sửa ảnh",
                    text_color="#C7D2FE",
                    fg_color="#312E81"
                )
            # Show Done button on toolbar
            self.btn_done.pack(side="right", padx=(4, 8), pady=6)
        else:
            self.slot_indicator_lbl.configure(
                text="💡 Nhấp đúp (Double-click) vào ảnh để Zoom/Dời",
                text_color="#A1A1AA",
                fg_color="transparent"
            )
            # Hide Done button when not editing
            self.btn_done.pack_forget()

    def get_transform_params(self) -> Dict[str, Any]:
        curr = self.get_slot_transform(self.selected_slot)
        return {
            "selected_slot": self.selected_slot,
            "slot_transforms": {k: dict(v) for k, v in self.slot_transforms.items()},
            "zoom": curr["zoom"],
            "pan_x": curr["pan_x"],
            "pan_y": curr["pan_y"],
            "rotation": curr["rotation"],
            "flip_h": curr["flip_h"],
            "flip_v": curr["flip_v"],
        }

    def _notify_transform(self):
        if self.on_transform_change:
            self.on_transform_change(self.get_transform_params())
