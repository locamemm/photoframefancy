"""
PhotoFrameFancy - UI Dialogs
Progress modal for batch export and notification dialogs.
"""

import os
import subprocess
import customtkinter as ctk
from tkinter import messagebox, colorchooser
from typing import Optional, Callable


class BatchExportDialog(ctk.CTkToplevel):
    def __init__(
        self,
        parent,
        total_count: int,
        on_cancel: Optional[Callable[[], None]] = None
    ):
        super().__init__(parent)
        self.title("Đang Xuất Ảnh Hàng Loạt")
        self.geometry("450x260")
        self.resizable(False, False)
        self.transient(parent)
        self.grab_set()

        self.total_count = total_count
        self.on_cancel_callback = on_cancel
        self.is_done = False
        self.output_dir = ""

        # Center on parent
        self.update_idletasks()
        px = parent.winfo_x() + (parent.winfo_width() - 450) // 2
        py = parent.winfo_y() + (parent.winfo_height() - 260) // 2
        self.geometry(f"+{max(0, px)}+{max(0, py)}")

        # Widgets
        self.title_lbl = ctk.CTkLabel(
            self,
            text="🚀 Đang xử lý khung ảnh nghệ thuật...",
            font=ctk.CTkFont(size=16, weight="bold")
        )
        self.title_lbl.pack(pady=(22, 10))

        self.status_lbl = ctk.CTkLabel(
            self,
            text=f"Tiến độ: 0 / {total_count} ảnh",
            font=ctk.CTkFont(size=13)
        )
        self.status_lbl.pack(pady=(0, 6))

        self.current_file_lbl = ctk.CTkLabel(
            self,
            text="Đang chuẩn bị...",
            font=ctk.CTkFont(size=12, slant="italic"),
            text_color="gray70"
        )
        self.current_file_lbl.pack(pady=(0, 15))

        self.progress_bar = ctk.CTkProgressBar(self, width=380, height=14)
        self.progress_bar.set(0)
        self.progress_bar.pack(pady=(0, 20))

        self.btn_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.btn_frame.pack(fill="x", padx=30)

        self.action_btn = ctk.CTkButton(
            self.btn_frame,
            text="Hủy Bỏ",
            fg_color="#D9534F",
            hover_color="#C9302C",
            command=self._on_cancel_click
        )
        self.action_btn.pack(side="right", padx=5)

        self.open_folder_btn = ctk.CTkButton(
            self.btn_frame,
            text="📂 Mở Thư Mục",
            fg_color="#2B5B84",
            hover_color="#1E4364",
            command=self._open_folder
        )
        # Hidden until done

    def update_progress(self, current: int, total: int, current_file: str):
        progress = current / max(1, total)
        self.progress_bar.set(progress)
        self.status_lbl.configure(text=f"Tiến độ: {current} / {total} ảnh ({int(progress * 100)}%)")
        self.current_file_lbl.configure(text=f"Đang xử lý: {current_file}")

    def mark_completed(self, success_count: int, failed_count: int, output_dir: str):
        self.is_done = True
        self.output_dir = output_dir
        self.progress_bar.set(1.0)
        self.title_lbl.configure(text="🎉 Xuất Ảnh Hoàn Tất Thành Công!")
        self.status_lbl.configure(
            text=f"Thành công: {success_count} ảnh" + (f" | Lỗi: {failed_count}" if failed_count > 0 else "")
        )
        self.current_file_lbl.configure(text=f"Lưu tại: {os.path.basename(output_dir)}")
        
        self.action_btn.configure(
            text="Đóng",
            fg_color="#2E7D32",
            hover_color="#1B5E20",
            command=self.destroy
        )
        self.open_folder_btn.pack(side="left", padx=5)

    def _on_cancel_click(self):
        if self.is_done:
            self.destroy()
        else:
            if messagebox.askyesno("Xác nhận", "Bạn có chắc chắn muốn hủy quá trình xuất ảnh?"):
                if self.on_cancel_callback:
                    self.on_cancel_callback()
                self.destroy()

    def _open_folder(self):
        if self.output_dir and os.path.exists(self.output_dir):
            if os.name == "nt":
                os.startfile(self.output_dir)
            else:
                subprocess.Popen(["xdg-open", self.output_dir])


def pick_color(parent, initial_color: str = "#FFFFFF") -> Optional[str]:
    """Helper to open standard color chooser."""
    rgb, hex_col = colorchooser.askcolor(color=initial_color, parent=parent, title="Chọn Màu Khung / Màu Lót")
    return hex_col
