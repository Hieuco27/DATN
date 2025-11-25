# Logic Trạng thái Mượn Sách & Cập nhật Số lượng

## 🔄 Flow Trạng Thái

```
┌─────────────────────────────────────────────────────────────┐
│  1. User đăng ký mượn sách (Add to Cart → Checkout)        │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
          ┌────────────────────────┐
          │  PENDING (Chờ duyệt)   │
          │  🟠 Màu cam            │
          │  📌 Icon: pending      │
          └───────────┬────────────┘
                      │
                      │ Thủ thư duyệt
                      ↓
     ┌──────────────────────────────────┐
     │  WAITING_FOR_PICKUP / APPROVED   │
     │  🟣 Màu tím                      │
     │  ✅ Icon: task_alt               │
     │  📚 SÁCH ĐÃ GIỮ CHO USER        │
     └──────────────┬───────────────────┘
                    │
                    │ ⚠️ Tại đây số lượng sách thay đổi:
                    │ • availableCopies GIẢM (-)
                    │ • borrowedCopies TĂNG (+)
                    │
                    │ User đến lấy sách
                    ↓
          ┌────────────────────────┐
          │  BORROWING (Đang mượn) │
          │  🔵 Màu xanh dương     │
          │  📖 Icon: book         │
          └───────────┬────────────┘
                      │
                      │ User trả sách
                      ↓
          ┌────────────────────────┐
          │  RETURNED (Đã trả)     │
          │  🟢 Màu xanh lá        │
          │  ✔️ Icon: check_circle │
          └────────────────────────┘
                      │
                      │ ⚠️ Tại đây số lượng phục hồi:
                      │ • availableCopies TĂNG (+)
                      │ • borrowedCopies GIẢM (-)

     Nếu quá hạn:
          ┌────────────────────────┐
          │  OVERDUE (Quá hạn)     │
          │  🔴 Màu đỏ             │
          │  ⚠️ Icon: warning      │
          └────────────────────────┘
```

---

## 📊 Bảng Trạng Thái Chi Tiết

| Trạng thái | Tên hiển thị | Màu sắc | Icon | Ảnh hưởng số lượng |
|------------|--------------|---------|------|-------------------|
| `PENDING` | Chờ duyệt | 🟠 Orange | `pending_outlined` | ❌ Không |
| `WAITING_FOR_PICKUP` / `APPROVED` | Chờ lấy sách | 🟣 Purple | `task_alt_outlined` | ✅ **GIẢM available, TĂNG borrowed** |
| `BORROWING` | Đang mượn | 🔵 Blue | `book_outlined` | ✅ Tiếp tục giữ (đã giảm ở bước trước) |
| `RETURNED` | Đã trả | 🟢 Green | `check_circle_outline` | ✅ **TĂNG available, GIẢM borrowed** |
| `OVERDUE` | Quá hạn | 🔴 Red | `warning_amber_rounded` | ✅ Vẫn giữ (chưa trả) |

---

## 🔢 Logic Cập nhật Số lượng

### **Khi chuyển sang WAITING_FOR_PICKUP:**
```dart
// Backend API nên xử lý
POST /api/loans/{loanId}/approve
Response: {
  "status": "WAITING_FOR_PICKUP",
  "document": {
    "availableCopies": previousValue - quantity,  // ⬇️ GIẢM
    "totalCopies": unchanged
  }
}

// Frontend nên reload document detail để cập nhật:
- Hiện có: 10 → 9 (giảm 1)
- Cho mượn: 2 → 3 (tăng 1)
```

### **Khi chuyển sang RETURNED:**
```dart
// Backend API nên xử lý
POST /api/loans/{loanId}/return
Response: {
  "status": "RETURNED",
  "document": {
    "availableCopies": previousValue + quantity,  // ⬆️ TĂNG
    "totalCopies": unchanged
  }
}

// Frontend nên reload document detail để cập nhật:
- Hiện có: 9 → 10 (tăng 1)
- Cho mượn: 3 → 2 (giảm 1)
```

---

## 🎯 Yêu cầu Implementation

### **1. Frontend - Document Detail Page**
File: `document_detail_page.dart`

**Cần cập nhật realtime khi:**
- User thêm sách vào giỏ và checkout thành công
- Trạng thái loan chuyển sang WAITING_FOR_PICKUP (thủ thư duyệt)
- Trạng thái loan chuyển sang RETURNED (user trả sách)

**Giải pháp:**
```dart
// Option 1: Listen to cart/loan changes (Recommended)
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Listen to loan status changes
  final loanProvider = Provider.of<LoanProvider>(context, listen: false);
  loanProvider.addListener(_onLoanChanged);
}

void _onLoanChanged() {
  // Reload document detail khi loan thay đổi
  _loadDocumentDetail();
}

// Option 2: Reload sau mỗi action
void _addToCart() async {
  // ... existing code ...
  await _loadDocumentDetail();  // Reload
}
```

### **2. Frontend - Borrow History Page**
File: `borrow_history_page.dart` ✅ **ĐÃ CẬP NHẬT**

Đã thêm:
- ✅ Trạng thái `WAITING_FOR_PICKUP` / `APPROVED`
- ✅ Màu tím (Purple)
- ✅ Icon `task_alt_outlined`
- ✅ Label "Chờ lấy sách"

### **3. Backend Requirements**
Cần đảm bảo API backend:
- ✅ Trả về trạng thái `WAITING_FOR_PICKUP` hoặc `APPROVED` sau khi thủ thư duyệt
- ✅ Cập nhật `availableCopies` trong DB khi chuyển trạng thái
- ✅ API `/documents/{id}` trả về số lượng chính xác realtime
- ✅ Có endpoint để check trạng thái loan theo documentId

---

## 📱 UI/UX Flow User

### **Từ góc nhìn User:**
```
1. Tôi chọn sách → Thêm vào giỏ
   Status: Chưa mượn
   Hiển thị: "Hiện có: 10 quyển"

2. Tôi checkout giỏ sách
   Status: PENDING (Chờ duyệt)
   Hiển thị: "Hiện có: 10 quyển" (vẫn chưa đổi)

3. Thủ thư duyệt đơn
   Status: WAITING_FOR_PICKUP (Chờ lấy sách) 🟣
   Hiển thị: "Hiện có: 9 quyển" ⬇️ (đã giảm)
   Thông báo: "Đơn mượn đã được duyệt. Vui lòng đến thư viện lấy sách"

4. Tôi đến lấy sách
   Status: BORROWING (Đang mượn) 🔵
   Hiển thị: "Hiện có: 9 quyển" (vẫn giảm)

5. Tôi trả sách
   Status: RETURNED (Đã trả) 🟢
   Hiển thị: "Hiện có: 10 quyển" ⬆️ (phục hồi)
```

---

## 🔔 Notifications Flow

Nên có thông báo realtime khi:
1. **Thủ thư duyệt** → Push notification: "Đơn mượn #{id} đã được duyệt"
2. **Sách sẵn sàng** → "Sách của bạn đã sẵn sàng. Vui lòng đến lấy"
3. **Gần đến hạn** → "Sách #{title} sẽ đến hạn trả trong 2 ngày"
4. **Quá hạn** → "Bạn đã quá hạn trả sách #{title}"

---

## ⚠️ Edge Cases

### **1. User checkout nhưng hết sách:**
- Backend kiểm tra `availableCopies > 0` trước khi tạo loan
- Nếu hết: Trả lỗi "Sách đã hết"

### **2. Multiple users checkout cùng lúc:**
- Backend dùng transaction + lock để đảm bảo atomic
- Chỉ approve số lượng đủ, phần còn lại reject

### **3. User không đến lấy sách:**
- Sau N ngày, tự động chuyển về CANCELLED
- Phục hồi `availableCopies`

### **4. Sách bị mất/hư:**
- Trạng thái: LOST / DAMAGED
- Không phục hồi `availableCopies` (trừ `totalCopies`)

---

## ✅ Checklist

### Frontend:
- [x] Thêm trạng thái WAITING_FOR_PICKUP vào borrow_history_page
- [ ] Implement realtime update trong document_detail_page
- [ ] Listen to loan status changes
- [ ] Reload document khi status chuyển đổi
- [ ] Show notification khi status change

### Backend:
- [ ] API approve loan → trả về WAITING_FOR_PICKUP
- [ ] Giảm availableCopies khi approve
- [ ] API return loan → tăng availableCopies
- [ ] WebSocket/Push notification cho status changes
- [ ] Transaction handling cho concurrent requests

---

## 📝 Notes

- **CRITICAL**: Số lượng sách phải được update **NGAY KHI THỦ THƯ DUYỆT** (WAITING_FOR_PICKUP), không phải khi user lấy sách
- Frontend nên có loading state khi đang reload document detail
- Cân nhắc cache invalidation strategy
- Test kỹ concurrent scenarios

---

**Last Updated:** Nov 20, 2025
**Status:** ✅ Frontend Updated | ⏳ Backend Pending | ⏳ Realtime Update Pending
