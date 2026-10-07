# 🖼️ PhotoFrameFancy - Phần Mềm Lồng Khung Ảnh & Ghép Lưới Nghệ Thuật Cao Cấp

Phần mềm Python chuyên nghiệp, siêu mượt (60 FPS), tích hợp **2 Tab List trực quan riêng biệt** để chọn **Mẫu Khung Ảnh Lưới (1 - 6 ảnh)** và **Kiểu Khung Viền Bọc Ngoài Nghệ Thuật (15 mẫu viền)**.

---

## 🌟 Điểm Nổi Bật

### 1. 🎨 Danh Sách Bộ Lọc Màu Trực Quan (1-Click Chọn Ngay)
- Hiển thị trực tiếp danh sách 8 bộ lọc màu nghệ thuật (không cần click mở menu thả xuống):
  - 🌈 **Gốc (Original)**: Giữ nguyên màu sắc trung thực ban đầu.
  - 🌅 **Phim Ấm (Warm Film)**: Tông ấm vàng phong cách film Kodak Gold.
  - 📜 **Cổ Điển (Sepia)**: Tông màu nâu hoài cổ thế kỷ 20.
  - 🔳 **Đen Trắng (B&W Fine Art)**: Độ tương phản cao, dải sáng tối sắc nét.
  - 🎬 **Điện Ảnh (Cool Cine)**: Tông lạnh mát Teal & Orange phong cách phim Hollywood.
  - 🎨 **Rực Rỡ (Vivid Pop)**: Đẩy bão hòa và độ sắc nét cho phong cảnh / du lịch.
  - 🌸 **Pastel Nhẹ Nhàng (Muted)**: Dịu mắt, phong cách ảnh Hàn Quốc / Pinterest.
  - 🌑 **Kịch Tính (Noir Drama)**: Đen trắng sâu thẳm, bóng tối bí ẩn.

### 2. ✍️ Chữ Ký / Tiêu Đề Thông Minh (Tự Động & Có Sẵn Mẫu Chữ)
- **Tự động nhận diện khung dùng chữ**:
  - Chỉ hiển thị ô nhập chữ khi mẫu khung có thiết kế hỗ trợ chữ ký/tiêu đề:
    - 📸 **Ảnh Polaroid Lấy Liền**: Ghi sẵn `"Memories • Forever"` (font chữ ký viết tay).
    - 🎞️ **Cuộn Phim 35mm**: Ghi sẵn `"KODAK GOLD 200  ▶  24A"` (font kỹ thuật điện ảnh).
    - 📰 **Bìa Tạp Chí Vogue**: Ghi sẵn `"AESTHETIC • ISSUE NO. 10"` (font serif thời trang).
    - 🏛️ **Khung Triển Lãm Nghệ Thuật**: Ghi sẵn `"Art Gallery Collection"`.
    - ✉️ **Tem Thư Bưu Chính**: Ghi sẵn `"POSTE AERIENNE • SPECIAL"`.
    - 🌿 **Hoa Cỏ & Cưới Hỏi**: Ghi sẵn `"Save The Date • Sweet Love"`.
  - Đối với các khung không dùng chữ (như Khung Vàng Hoàng Gia, Gỗ Óc Chó, Tối Giản...), phần mềm sẽ tự động ẩn đi và hiện thông báo gợi ý rõ ràng, giúp giao diện gọn gàng sạch sẽ.
- **Cập nhật tức thì khi gõ phím**: Bạn gõ chữ đến đâu, ảnh trên canvas tự động cập nhật đến đó trong thời gian thực.
- Có nút `↺ Khôi Phục Chữ Mẫu` và `✕ Xóa Chữ` tiện lợi.

### 3. ▦ 2 Tab List Trực Quan Riêng Biệt
- **Tab List 1: `▦ Mẫu Khung Lưới`**: 37+ bố cục lưới từ 1 đến 6 ảnh (chia nhóm 1-click `[1][2][3][4][5][6] Ảnh`).
- **Tab List 2: `🖼️ Viền Bọc Ngoài`**: 15 mẫu khung viền nghệ thuật cao cấp (Vàng kim, Gỗ óc chó, Tối giản không viền, Nổi 3D, Polaroid, v.v.).

### 4. ⚡ Hiệu Năng Vượt Trội (Siêu Mượt 60 FPS)
- Render ngầm bất đồng bộ (`AsyncPreviewEngine`), không bao giờ đơ hay lag chuột.
- Bộ nhớ đệm RAM (`PhotoCache`) nạp ảnh tức thì < 0.1ms.
- Tự động bỏ qua các khung hình thừa khi kéo chuột nhanh.

---

## 🚀 Hướng Dẫn Khởi Động

- **Cách 1**: Nhấp đúp chuột vào file **`run.bat`** trong thư mục dự án.
- **Cách 2**: Chạy lệnh qua terminal:
  ```bash
  python main.py
  ```
