# PhotoFrameFancy - Phiên Bản Mobile (Flutter & Dart)

Ứng dụng **PhotoFrameFancy Mobile** được xây dựng bằng **Flutter 3 (Dart)**, kế thừa 100% tính năng nghệ thuật từ phiên bản Desktop và tối ưu hóa toàn diện cho màn hình cảm ứng di động.

---

## 🌟 Tính Năng Nổi Bật Trên Mobile

1. **Cảm Ứng Đa Điểm Siêu Mượt (120 FPS Impeller/Skia):**
   - **Chạm đúp (Double-Tap):** Kích hoạt chế độ chỉnh sửa ô ảnh được chọn (hiển thị viền tím Indigo, 4 góc ngàm và badge trạng thái).
   - **Chụm 2 ngón (Pinch-to-zoom):** Phóng to / thu nhỏ ảnh từ 100% đến 300% trực quan và mượt mà.
   - **Vuốt 1 ngón (Drag/Pan):** Di chuyển vị trí bức ảnh bên trong ô khung viền.
   - **Thanh công cụ nổi (Floating Bar):** Nút xoay 90°, lật ngang, đặt lại và nút `✓ Xong`.
2. **Khung Ảnh Nghệ Thuật & Lưới Ghép Đa Dạng:**
   - Hỗ trợ ảnh đơn và lưới ghép từ **1 đến 6 ảnh**.
   - Các mẫu khung: *Hoàng Gia Baroque, Gỗ Óc Chó, Triển Lãm Bảo Tàng, Nổi 3D, Polaroid, Sổ Dán Kraft, Neon Cyberpunk...*
3. **Bộ Lọc Màu GPU Shader:**
   - Áp dụng các bộ lọc màu nghệ thuật (*Warm Film, Sepia, B&W Classic, Cool Cine, Vivid, Muted, Noir*) xử lý trực tiếp trên GPU chip điện thoại.
4. **Xuất Ảnh 4K & Chia Sẻ Nhanh:**
   - Dựng ảnh chất lượng cao 2400x2400 bằng `ui.PictureRecorder` chạy nền.
   - Tự động lưu vào Album ảnh của máy (`Gal`).
   - Hỗ trợ nút **Chia Sẻ** trực tiếp sang Zalo, Facebook, Instagram, Messenger (`share_plus`).

---

## 🚀 Cách Khởi Chạy Ứng Dụng

Nhấp đúp chuột vào file:
```
g:\Users\ACER\Downloads\PhotoFrameFancy\mobile\run_mobile.bat
```
Hoặc dùng lệnh terminal trong thư mục `mobile`:

### 1. Xem trước trên Trình duyệt (Edge/Chrome)
```bash
flutter run -d edge
```

### 2. Chạy trên Điện thoại Android (Cắm cáp USB bật USB Debugging) hoặc Máy ảo
```bash
flutter run
```

### 3. Đóng gói file APK cài đặt lên điện thoại
```bash
flutter build apk --release
```
File APK xuất ra sẽ nằm tại: `mobile/build/app/outputs/flutter-apk/app-release.apk`.
Bạn chỉ cần chép file này sang điện thoại Android là cài đặt và sử dụng được ngay!
