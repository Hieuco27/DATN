# 📖 Hướng Dẫn Sử Dụng Chức Năng Highlight trong Ebook Reader

## ✨ Tổng quan các tính năng mới

### 1. **Tạo Highlight** ✏️
- Đánh dấu văn bản quan trọng với 4 màu sắc khác nhau
- Thêm ghi chú cho mỗi highlight
- Hỗ trợ cả PDF và EPUB

### 2. **Chỉnh sửa Highlight** 🔧
- Thay đổi màu highlight
- Chỉnh sửa ghi chú
- Cập nhật thông tin đã lưu

### 3. **Export Highlights** 📤
- Export ra file Text (.txt)
- Export ra file JSON (.json)
- Chia sẻ qua email, drive, message,...

### 4. **Hiển thị màu highlight** 🎨
- Màu highlight được hiển thị trực tiếp trên nội dung EPUB
- Màu sắc tùy chỉnh với 4 lựa chọn
- Visual feedback khi tạo highlight thành công

---

## 📱 Cách Sử Dụng

### **Đối với file PDF:**

#### Tạo Highlight:
1. **Chọn văn bản** trong PDF bằng cách kéo chuột/ngón tay
2. Một dialog sẽ tự động xuất hiện
3. **Chọn màu highlight** (Vàng, Xanh lá, Xanh dương, Hồng)
4. **Thêm ghi chú** (tùy chọn) - có thể mô tả lý do highlight
5. Nhấn nút **"Lưu đánh dấu"**

✅ Bạn sẽ thấy snackbar xác nhận với màu highlight đã chọn!

#### Xem và Quản lý:
- Nhấn nút **Highlights** (màu cam) ở góc dưới bên phải
- Chọn tab **"Highlights"** để xem danh sách
- Mỗi highlight hiển thị:
  - 🎨 Màu sắc
  - 📝 Văn bản đã đánh dấu
  - 💬 Ghi chú (nếu có)
  - 📄 Số trang

### **Đối với file EPUB:**

#### Tạo Highlight:
1. **Long press** (giữ lâu) vào trang EPUB
2. Một dialog nhập text sẽ xuất hiện
3. **Nhập hoặc paste** đoạn văn bạn muốn đánh dấu
   - Tip: Copy văn bản từ chỗ khác và paste vào
4. Nhấn **"Tiếp tục"**
5. **Chọn màu highlight**
6. **Thêm ghi chú** (tùy chọn)
7. Nhấn **"Lưu đánh dấu"**

✅ Màu highlight sẽ hiển thị trực tiếp trên nội dung EPUB!

#### Xem màu highlight:
- Khi bạn chuyển trang, các highlight được lưu sẽ tự động hiển thị với màu tương ứng
- Văn bản được highlight sẽ có background màu

---

## 🎨 Các màu Highlight

| Màu | Hex Code | Dùng cho |
|-----|----------|----------|
| 🟨 **Vàng** | #FFF59D | Ý tưởng chính, điểm quan trọng |
| 🟩 **Xanh lá** | #C5E1A5 | Định nghĩa, thuật ngữ |
| 🟦 **Xanh dương** | #AEDFF7 | Ví dụ, minh họa |
| 🟥 **Hồng** | #F8BBD0 | Cảnh báo, lưu ý đặc biệt |

---

## ✏️ Chỉnh Sửa Highlight

1. Mở **menu Highlights** (nút màu cam)
2. Chọn tab **"Highlights"**
3. Tìm highlight muốn sửa
4. Nhấn icon **✏️ Edit** bên cạnh highlight
5. Thay đổi:
   - **Màu sắc** - chọn màu mới
   - **Ghi chú** - sửa hoặc thêm ghi chú
6. Nhấn **"Lưu thay đổi"**

✅ Highlight sẽ được cập nhật ngay lập tức!

---

## 📤 Export Highlights

### Bước 1: Mở Export Dialog
1. Mở **menu Highlights**
2. Nhấn icon **↗️ Share** ở góc trên bên phải
3. Chọn định dạng file:
   - **Text (.txt)** - dễ đọc, định dạng văn bản
   - **JSON (.json)** - dữ liệu cấu trúc, dễ import lại

### Bước 2: Chia sẻ
- File sẽ được tự động tạo và mở share sheet
- Bạn có thể:
  - 📧 Gửi qua Email
  - ☁️ Lưu vào Google Drive/OneDrive
  - 💬 Chia sẻ qua Message/WhatsApp
  - 📱 Lưu vào Files app

### Format Text Export:
```
═══════════════════════════════════════
HIGHLIGHTS EXPORT
Book: Tên sách
Date: 2025-11-20 09:42:15
Total: 5 highlights
═══════════════════════════════════════

1. [Page 10] - #FFF59D
   "Văn bản được đánh dấu ở đây..."
   Note: Ghi chú của tôi
   Created: 2025-11-20 08:30:00

2. [Page 15] - #C5E1A5
   "Văn bản khác..."
   Created: 2025-11-20 09:15:00
```

### Format JSON Export:
```json
{
  "bookId": "Tên sách",
  "exportDate": "2025-11-20T09:42:15.000Z",
  "totalHighlights": 5,
  "highlights": [
    {
      "id": "1732115400000",
      "text": "Văn bản được đánh dấu ở đây...",
      "pageNumber": 10,
      "note": "Ghi chú của tôi",
      "createdAt": "2025-11-20T08:30:00.000Z",
      "color": "#FFF59D"
    }
  ]
}
```

---

## 🗑️ Xóa Highlight

1. Mở **menu Highlights**
2. Tìm highlight muốn xóa
3. Nhấn icon **🗑️ Delete**
4. Highlight sẽ bị xóa vĩnh viễn

⚠️ **Lưu ý:** Không thể khôi phục sau khi xóa!

---

## 💡 Tips & Tricks

### 📌 Best Practices:
1. **Đặt tên ghi chú rõ ràng** - giúp bạn nhớ lại lý do highlight
2. **Sử dụng màu có hệ thống** - mỗi màu cho một mục đích
3. **Export thường xuyên** - backup highlights quan trọng
4. **Review highlights** - đọc lại định kỳ để nhớ lại kiến thức

### 🚀 Workflow Hiệu Quả:
1. Đọc và highlight ngay khi gặp ý quan trọng
2. Thêm ghi chú ngắn gọn (2-3 từ)
3. Cuối tuần export highlights để review
4. Share với bạn bè/nhóm học

### ⚡ Shortcuts:
- **PDF**: Chọn text → Dialog tự động hiện
- **EPUB**: Long press → Nhập text → Done
- **Xem nhanh**: Nút Highlights → Tab "Highlights"
- **Export nhanh**: Icon Share ở header

---

## 🐛 Troubleshooting

### Vấn đề: Không chọn được văn bản trong EPUB
**Giải pháp:**
- Sử dụng Long Press để mở dialog nhập text
- Copy văn bản từ nơi khác và paste vào
- Đảm bảo văn bản tồn tại trong chapter hiện tại

### Vấn đề: Màu highlight không hiển thị
**Giải pháp:**
- Đảm bảo highlight đã được lưu thành công
- Chuyển sang trang khác rồi quay lại
- Kiểm tra highlight có đúng pageNumber không

### Vấn đề: Export không hoạt động trên Web
**Giải pháp:**
- Export hiện tại chỉ hỗ trợ Mobile và Desktop
- Trên Web, sử dụng ứng dụng mobile thay thế

### Vấn đề: Highlight bị mất
**Giải pháp:**
- Highlights được lưu local với SharedPreferences
- Không xóa cache/data ứng dụng
- Export thường xuyên để backup

---

## 📊 Thống Kê & Giới Hạn

- ✅ **Không giới hạn** số lượng highlights
- ✅ **4 màu** highlight để lựa chọn
- ✅ **Tự động lưu** mỗi khi tạo/sửa
- ✅ **Riêng biệt** cho từng sách
- ✅ **Export** không giới hạn số lần

---

## 🔄 Updates và Cải Tiến Tương Lai

### Có thể thêm:
- [ ] Sync highlights lên cloud (Firebase)
- [ ] Tìm kiếm trong highlights
- [ ] Filter highlights theo màu
- [ ] Sort highlights theo thời gian/trang
- [ ] Hiển thị highlight trực tiếp trên PDF
- [ ] Import highlights từ file JSON
- [ ] Share highlights lên mạng xã hội
- [ ] Thống kê highlight (số lượng, phân bố màu)

---

## 📞 Hỗ Trợ

Nếu gặp vấn đề hoặc có câu hỏi:
1. Kiểm tra phần Troubleshooting ở trên
2. Xem lại hướng dẫn từng bước
3. Liên hệ developer để được hỗ trợ

---

## 📝 Changelog

### Version 1.0 (Current)
- ✅ Tạo highlight với 4 màu
- ✅ Thêm ghi chú
- ✅ Chỉnh sửa highlight
- ✅ Xóa highlight
- ✅ Export Text/JSON
- ✅ Hiển thị màu trên EPUB
- ✅ Hướng dẫn sử dụng trong app

---

**Happy Reading! 📚✨**
