# Realtime Update Implementation - Document Availability

## 🎯 Mục tiêu

Cập nhật **realtime** số lượng sách "Hiện có" và "Cho mượn" trong trang Document Detail khi:
- User thêm sách vào giỏ và checkout
- Thủ thư duyệt phiếu mượn (WAITING_FOR_PICKUP)
- User trả sách (RETURNED)

---

## ✅ Implementation Completed

### **File: `document_detail_page.dart`**

#### **1. Listen to CartProvider Changes**

```dart
class _DocumentDetailPageState extends State<DocumentDetailPage> {
  CartProvider? _cartProvider;

  @override
  void initState() {
    super.initState();
    // ... existing code ...
    
    // ✅ Listen to cart changes để cập nhật số lượng sách khi checkout
    _cartProvider = Provider.of<CartProvider>(context, listen: false);
    _cartProvider?.addListener(_onCartChanged);
    
    _loadDocumentDetail();
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _cartProvider?.removeListener(_onCartChanged);  // ✅ Cleanup
    super.dispose();
  }
}
```

#### **2. Auto Reload on Cart Changes**

```dart
/// Gọi lại khi cart thay đổi (checkout thành công, loan được approve)
/// 
/// Flow cập nhật số lượng:
/// 1. User checkout giỏ sách → CartProvider thay đổi
/// 2. _onCartChanged() được trigger
/// 3. Reload document detail từ server
/// 4. Backend trả về availableCopies đã cập nhật
/// 5. UI tự động update:
///    - "Hiện có" giảm xuống (khi loan = WAITING_FOR_PICKUP)
///    - "Cho mượn" tăng lên (totalCopies - availableCopies)
void _onCartChanged() {
  if (!mounted) return;
  _loadDocumentDetail();  // ✅ Reload từ server
}
```

#### **3. Pull-to-Refresh**

```dart
body: RefreshIndicator(
  onRefresh: _loadDocumentDetail,  // ✅ User kéo xuống để refresh
  color: _primaryColor,
  child: _buildBody(),
),
```

#### **4. Display Logic**

```dart
Row(
  children: [
    Expanded(child: _buildInfoItem('Tổng', '${_vm.totalCopies}', isSmallScreen)),
    Container(width: 1, height: 38, color: Colors.grey[200]),
    Expanded(child: _buildInfoItem('Hiện có', '${_vm.availableCopies}', isSmallScreen)),
    Container(width: 1, height: 38, color: Colors.grey[200]),
    Expanded(
      child: _buildInfoItem(
        'Cho mượn',
        '${_vm.totalCopies - _vm.availableCopies}',  // ✅ Tự động tính
        isSmallScreen,
      ),
    ),
  ],
)
```

---

## 🔄 Flow hoạt động

### **Scenario 1: User Checkout → Thủ thư duyệt**

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User xem sách trong Document Detail Page                │
│    Hiện có: 10 | Cho mượn: 2                               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. User thêm vào giỏ và Checkout                           │
│    → CartProvider.checkout() gọi API                        │
│    → API tạo loan với status = PENDING                      │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Thủ thư duyệt phiếu mượn (Backend)                      │
│    POST /api/loans/{id}/approve                             │
│    → Loan status: PENDING → WAITING_FOR_PICKUP             │
│    → availableCopies: 10 → 9 (giảm 1)                      │
│    → CartProvider.notifyListeners()                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Frontend nhận thay đổi                                   │
│    → _onCartChanged() được trigger                          │
│    → _loadDocumentDetail() reload từ server                 │
│    → GET /api/documents/{id}                                │
│    → Response: { availableCopies: 9, totalCopies: 12 }     │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. UI tự động update                                        │
│    Hiện có: 10 → 9 ⬇️                                      │
│    Cho mượn: 2 → 3 ⬆️                                      │
└─────────────────────────────────────────────────────────────┘
```

### **Scenario 2: User trả sách**

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User trả sách (Backend)                                  │
│    POST /api/loans/{id}/return                              │
│    → Loan status: BORROWING → RETURNED                      │
│    → availableCopies: 9 → 10 (tăng 1)                       │
│    → CartProvider.notifyListeners()                          │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Frontend nhận thay đổi                                   │
│    → _onCartChanged() trigger                                │
│    → Reload document detail                                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. UI tự động update                                        │
│    Hiện có: 9 → 10 ⬆️                                      │
│    Cho mượn: 3 → 2 ⬇️                                      │
└─────────────────────────────────────────────────────────────┘
```

### **Scenario 3: Manual Refresh**

```
┌─────────────────────────────────────────────────────────────┐
│ User kéo màn hình xuống (Pull to Refresh)                  │
│    → RefreshIndicator trigger                                │
│    → _loadDocumentDetail() gọi                               │
│    → GET /api/documents/{id}                                 │
│    → UI update với data mới                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 Key Points

### **✅ Ưu điểm:**

1. **Realtime:** UI tự động update khi loan status thay đổi
2. **Accurate:** Luôn sync với server, không bị stale data
3. **User-friendly:** Pull-to-refresh cho phép manual update
4. **Clean:** Sử dụng Provider pattern có sẵn, không cần thêm library
5. **Performant:** Chỉ reload khi cần, không poll liên tục

### **⚠️ Lưu ý:**

1. **CartProvider phải notify khi checkout/return:**
   ```dart
   // In CartProvider
   Future<void> checkout() async {
     await _api.checkout(...);
     notifyListeners();  // ⚠️ BẮT BUỘC
   }
   ```

2. **Backend phải cập nhật availableCopies:**
   - Khi approve loan (WAITING_FOR_PICKUP): `availableCopies--`
   - Khi return loan (RETURNED): `availableCopies++`

3. **API response phải chính xác:**
   ```json
   GET /api/documents/{id}
   {
     "documentId": 123,
     "totalCopies": 12,
     "availableCopies": 9,  // ⚠️ Phải là số realtime
     ...
   }
   ```

---

## 🧪 Testing Checklist

### **Frontend:**
- [x] Listen to CartProvider changes
- [x] Auto reload khi cart thay đổi
- [x] Pull-to-refresh hoạt động
- [x] Cleanup listeners trong dispose
- [ ] Test với nhiều documents khác nhau
- [ ] Test khi network chậm/lỗi

### **Backend:**
- [ ] API approve loan giảm availableCopies
- [ ] API return loan tăng availableCopies
- [ ] GET /documents/{id} trả về số chính xác
- [ ] Handle concurrent requests (lock/transaction)
- [ ] Validate availableCopies >= 0

### **Integration:**
- [ ] Test flow: Checkout → Approve → UI update
- [ ] Test flow: Return → UI update
- [ ] Test multiple users cùng lúc
- [ ] Test khi hết sách (availableCopies = 0)
- [ ] Test edge cases (cancel loan, overdue, etc.)

---

## 🚀 Future Enhancements

### **1. WebSocket/Push Notifications (Realtime++)**
```dart
// Listen to WebSocket events
_socket.on('loan_status_changed', (data) {
  if (data['documentId'] == widget.documentId) {
    _loadDocumentDetail();
  }
});
```

### **2. Local Cache + Optimistic Updates**
```dart
void _onCartChanged() {
  // Optimistic update (instant UI)
  setState(() {
    _vm.updateLocal(availableCopies: _vm.availableCopies - 1);
  });
  
  // Then sync with server
  _loadDocumentDetail();
}
```

### **3. Background Polling (Fallback)**
```dart
Timer.periodic(Duration(seconds: 30), (timer) {
  if (mounted) _loadDocumentDetail();
});
```

---

## 📝 Code References

### **Files Modified:**
- ✅ `document_detail_page.dart` (lines 34, 44-45, 51-54, 62-76, 159-163)
- ✅ `borrow_history_page.dart` (added WAITING_FOR_PICKUP status)

### **Related Files:**
- `cart_provider.dart` - Phải notify khi checkout
- `document_detail_view_model.dart` - Load data từ repository
- `document_repository.dart` - Call API get document detail

### **Backend Requirements:**
- `POST /api/loans/{id}/approve` - Update availableCopies
- `POST /api/loans/{id}/return` - Update availableCopies
- `GET /api/documents/{id}` - Return accurate counts

---

## 🎯 Summary

✅ **Đã implement:**
- Listen to CartProvider changes → Auto reload
- Pull-to-refresh để manual update
- Proper cleanup trong dispose
- Comments đầy đủ giải thích flow

⏳ **Cần verify:**
- Backend API có update availableCopies đúng không
- CartProvider có notify sau checkout không
- Test realtime update với multiple scenarios

🎉 **Kết quả:**
User sẽ thấy số lượng "Hiện có" và "Cho mượn" update **tự động** ngay sau khi thủ thư duyệt phiếu mượn, không cần thoát ra/vào lại!

---

**Last Updated:** Nov 20, 2025  
**Status:** ✅ Frontend Completed | ⏳ Backend Verification Needed
