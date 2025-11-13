# Hướng Dẫn: Kết Hợp Custom HTML và epub_view

## ✅ Giải Pháp: Combined EPUB Reader

Bạn có thể **dùng cả 2** bằng cách:

- **epub_view**: Chỉ dùng cho **mục lục tự động** (EpubViewTableOfContents)
- **Custom HTML**: Dùng để **render content** (giữ font customization hoàn hảo)

---

## 🎯 Cách Hoạt Động

### 1. **Load EPUB**

```dart
// Load EPUB bằng EpubController (để có mục lục)
final epubController = EpubController(
  document: EpubDocument.openFile(File(epubFilePath)),
);

// Load chapters bằng EbookReaderService (để có content với font customization)
final chapters = await EbookReaderService.loadEpubChaptersFromFile(
  epubFilePath,
  settings: settings,
);
```

### 2. **Render Content**

```dart
// Dùng CombinedEpubReader
CombinedEpubReader(
  epubController: epubController, // Dùng cho mục lục
  settings: settings,
  epubFilePath: epubFilePath,
  chapters: chapters, // Content đã load với font customization
  bookId: bookTitle, // ID của sách để lưu highlights
)
```

### 3. **Hiển Thị Mục Lục**

```dart
// Mục lục tự động từ epub_view
await combinedReader.showTableOfContents(context);
// Hoặc dùng EpubViewTableOfContents trực tiếp
```

---

## 📊 So Sánh 3 Cách

| Tính năng       | Custom HTML | epub_view       | **Combined (Khuyến nghị)**  |
| --------------- | ----------- | --------------- | --------------------------- |
| **Font Family** | ✅ Hoàn hảo | ⚠️ Cần CSS      | ✅ **Hoàn hảo**             |
| **Font Size**   | ✅ Hoàn hảo | ⚠️ Cần CSS      | ✅ **Hoàn hảo**             |
| **Line Height** | ✅ Hoàn hảo | ⚠️ Cần CSS      | ✅ **Hoàn hảo**             |
| **Theme**       | ✅ Có       | ✅ Có           | ✅ **Có**                   |
| **Eye Comfort** | ✅ Có       | ✅ Có (wrapper) | ✅ **Có**                   |
| **Mục lục**     | ⚠️ Custom   | ✅ Tự động      | ✅ **Tự động**              |
| **Lật trang**   | ❌ Không    | ✅ Có           | ✅ **Có (swipe + buttons)** |
| **Navigation**  | ⚠️ Manual   | ✅ Tốt          | ✅ **Tốt**                  |
| **Highlight**   | ❌ Không    | ❌ Không        | ✅ **Có**                   |

---

## 🔧 Implementation

### File đã tạo: `combined_epub_reader.dart`

**Cách sử dụng trong `universal_ebook_reader.dart`:**

```dart
// Trong _buildEpubReader()
Widget _buildEpubReader() {
  // Nếu có EpubController (để lấy mục lục)
  if (_epubController != null) {
    return CombinedEpubReader(
      epubController: _epubController,
      settings: _settings,
      epubFilePath: _localFilePath!,
      chapters: _chapters, // Đã load từ EbookReaderService
      bookId: widget.title, // ID của sách để lưu highlights
    );
  }

  // Fallback: dùng custom HTML như hiện tại
  return _buildCustomHtmlReader();
}
```

### Khởi tạo EpubController (nếu chưa có):

```dart
// Trong _loadEbookContent() hoặc _initializeReader()
if (_detectedFormat == EbookFormat.epub && _localFilePath != null) {
  // Load chapters (như hiện tại)
  _chapters = await EbookReaderService.loadEpubChaptersFromFile(
    _localFilePath!,
  );

  // Tạo EpubController để có mục lục tự động
  try {
    _epubController = EpubController(
      document: EpubDocument.openFile(File(_localFilePath!)),
    );
  } catch (e) {
    print('Error creating EpubController: $e');
    // Fallback: không dùng epub_view, chỉ dùng custom HTML
  }
}
```

---

## ✅ Lợi Ích

### **Ưu điểm của Combined approach:**

1. ✅ **Font customization hoàn hảo**

   - Không cần CSS injection
   - Font family, size, line height hoạt động 100%

2. ✅ **Mục lục tự động**

   - Dùng `EpubViewTableOfContents` từ epub_view
   - Navigation tốt hơn

3. ✅ **Eye comfort giữ nguyên**

   - Overlay filters hoạt động như hiện tại

4. ✅ **Không phức tạp**
   - Không cần sync giữa 2 systems
   - Chỉ dùng epub_view cho mục lục, còn lại dùng custom HTML

---

## ⚠️ Lưu Ý

### **Lật trang:**

- **Combined approach**: Có lật trang giữa các chapters (next/previous chapter)
- **Không có**: Lật trang mượt mà trong cùng 1 chapter (như epub_view)
- **Giải pháp**: Có thể thêm PageScrollPhysics cho scroll trong chapter

### **Highlight:**

- ✅ **Đã implement**: Có highlight functionality
  - Tạo highlight thủ công qua nút "+"
  - Xem danh sách highlights qua nút highlight
  - Highlights được hiển thị trên nội dung với màu sắc
  - Lưu/tải highlights qua EbookSettingsService

---

## 🎯 Kết Luận

**Combined approach là tốt nhất** vì:

- ✅ Giữ được font customization hoàn hảo
- ✅ Có mục lục tự động từ epub_view
- ✅ Eye comfort hoạt động tốt
- ✅ Không cần CSS injection phức tạp
- ✅ Code đơn giản, dễ maintain

**Khuyến nghị**: Dùng `CombinedEpubReader` thay vì chỉ dùng 1 trong 2 cách.

---

## 🔗 Files

- `lib/features/auth/presentations/widgets/ebook/combined_epub_reader.dart`
- `lib/features/auth/presentations/widgets/ebook/epub_customized_wrapper.dart`
- `lib/features/auth/presentations/widgets/ebook/epub_reader_mode.dart`
