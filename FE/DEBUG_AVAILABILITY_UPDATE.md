# 🐛 Debug: Số lượng sách không cập nhật

## ❌ Vấn đề

Sau khi thủ thư duyệt phiếu mượn (trạng thái → WAITING_FOR_PICKUP), số "Hiện có" và "Cho mượn" **KHÔNG thay đổi**.

---

## ✅ Đã sửa

### **File: `document_detail_page.dart`**

**1. Sử dụng RouteAware để detect khi quay lại page:**

```dart
class _DocumentDetailPageState extends State<DocumentDetailPage> with RouteAware {
  static final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // ✅ Được gọi khi user QUAY LẠI trang này từ trang khác
    // VD: Document Detail → Borrow History → Back → Document Detail
    _loadDocumentDetail();  // Reload data mới!
  }
}
```

**2. Pull-to-refresh vẫn hoạt động:**

```dart
body: RefreshIndicator(
  onRefresh: _loadDocumentDetail,  // Kéo xuống để refresh
  child: _buildBody(),
),
```

---

## 🧪 Cách Test

### **Bước 1: Xem số lượng ban đầu**
```
Document Detail Page:
- Tổng: 12
- Hiện có: 10 ✅
- Cho mượn: 2
```

### **Bước 2: Thêm vào giỏ và Checkout**
```
1. Nhấn "Thêm vào giỏ sách"
2. Đi đến Cart → Checkout
3. Tạo phiếu mượn thành công (status = PENDING)
```

### **Bước 3: Thủ thư duyệt phiếu**
```
Backend: Thủ thư approve loan
→ Loan status: PENDING → WAITING_FOR_PICKUP
→ Backend PHẢI giảm availableCopies: 10 → 9
```

### **Bước 4: Kiểm tra frontend**
```
Option 1: Quay lại Document Detail từ Borrow History
1. Mở Borrow History
2. Thấy phiếu mượn ở trạng thái "Chờ lấy sách" 🟣
3. Nhấn Back về Document Detail
4. ✅ didPopNext() trigger → _loadDocumentDetail()
5. ✅ Số lượng phải update:
   - Hiện có: 10 → 9 ⬇️
   - Cho mượn: 2 → 3 ⬆️

Option 2: Pull to refresh
1. Ở Document Detail, kéo màn hình xuống
2. ✅ RefreshIndicator trigger
3. ✅ Số lượng phải update

Option 3: Thoát và vào lại
1. Back về Home
2. Chọn sách lại để vào Document Detail
3. ✅ initState() → _loadDocumentDetail()
4. ✅ Số lượng phải update
```

---

## 🔍 Debug Steps

### **1. Kiểm tra didPopNext có được gọi không**

Thêm print vào code:

```dart
@override
void didPopNext() {
  print('🔄 [DEBUG] didPopNext called - Reloading document...');
  _loadDocumentDetail();
}

Future<void> _loadDocumentDetail() async {
  print('📡 [DEBUG] Loading document ${widget.documentId}...');
  try {
    // ... existing code ...
    print('✅ [DEBUG] Document loaded: available=${_vm.availableCopies}, total=${_vm.totalCopies}');
  } catch (e) {
    print('❌ [DEBUG] Load failed: $e');
  }
}
```

**Cách kiểm tra:**
1. Mở Flutter DevTools console
2. Navigate: Document Detail → Borrow History → Back
3. Xem console có xuất hiện logs không

**Kết quả mong đợi:**
```
🔄 [DEBUG] didPopNext called - Reloading document...
📡 [DEBUG] Loading document 123...
✅ [DEBUG] Document loaded: available=9, total=12
```

---

### **2. Kiểm tra Backend API response**

Thêm log để xem API response:

```dart
final doc = await repository.getDocumentDetail(
  accessToken: authState.account.accessToken!,
  documentId: widget.documentId,
);
print('📦 [DEBUG] API Response: ${doc.toJson()}');
_document = doc;
```

**Hoặc check network trong DevTools:**
1. Mở Flutter DevTools → Network tab
2. Reload document detail
3. Tìm request: `GET /api/documents/{id}`
4. Xem response body

**Kết quả mong đợi:**
```json
{
  "documentId": 123,
  "title": "...",
  "totalCopies": 12,
  "availableCopies": 9,  // ⚠️ PHẢI GIẢM từ 10 → 9
  ...
}
```

**Nếu `availableCopies` vẫn là 10:**
→ ❌ **Backend chưa cập nhật!** Cần fix backend.

---

### **3. Kiểm tra Backend logic**

**Backend PHẢI làm điều này khi approve loan:**

```python
# hoặc Java/Node.js tùy stack
POST /api/loans/{loan_id}/approve

def approve_loan(loan_id):
    loan = Loan.get(loan_id)
    document = Document.get(loan.document_id)
    
    # ✅ QUAN TRỌNG: Giảm availableCopies
    document.availableCopies -= loan.quantity
    document.save()
    
    # Cập nhật loan status
    loan.status = 'WAITING_FOR_PICKUP'
    loan.save()
    
    return { "success": true }
```

**Kiểm tra database trực tiếp:**
```sql
-- Trước khi approve
SELECT id, title, total_copies, available_copies 
FROM documents WHERE id = 123;
-- Result: 123 | "Book Title" | 12 | 10

-- Approve loan

-- Sau khi approve
SELECT id, title, total_copies, available_copies 
FROM documents WHERE id = 123;
-- Result: 123 | "Book Title" | 12 | 9  ✅ PHẢI GIẢM
```

---

## 🐛 Common Issues

### **Issue 1: didPopNext không được gọi**

**Nguyên nhân:** RouteObserver không được register trong MaterialApp

**Fix:** Thêm vào `main.dart` hoặc app root:

```dart
MaterialApp(
  navigatorObservers: [
    _DocumentDetailPageState._routeObserver,  // ✅ Thêm dòng này
  ],
  // ... rest of app
)
```

---

### **Issue 2: API trả về availableCopies cũ (cached)**

**Nguyên nhân:** Backend cache response hoặc frontend cache

**Fix Backend:**
```python
# Disable cache cho endpoint này
@app.route('/documents/<id>')
@cache.no_cache  # ✅
def get_document(id):
    # ... fetch fresh from DB
```

**Fix Frontend:**
```dart
// Thêm cache busting
await repository.getDocumentDetail(
  accessToken: accessToken,
  documentId: documentId,
  bustCache: DateTime.now().millisecondsSinceEpoch,  // ✅
);
```

---

### **Issue 3: Backend chưa update availableCopies**

**Nguyên nhân:** Logic approve chưa có code giảm số lượng

**Fix:** Xem section "Kiểm tra Backend logic" ở trên

---

### **Issue 4: Race condition - Multiple users**

**Nguyên nhân:** 2 users approve cùng lúc → availableCopies sai

**Fix Backend:**
```python
# Dùng transaction + lock
@transaction.atomic
def approve_loan(loan_id):
    document = Document.objects.select_for_update().get(...)  # ✅ LOCK
    
    if document.availableCopies < loan.quantity:
        raise Exception("Not enough copies")
    
    document.availableCopies -= loan.quantity
    document.save()
```

---

## ✅ Checklist hoàn chỉnh

### **Frontend:**
- [x] Implement RouteAware để reload khi back
- [x] Implement Pull-to-refresh
- [x] Remove sai logic listen CartProvider
- [ ] Add debug logs
- [ ] Test didPopNext có trigger không
- [ ] Test API response có đúng không
- [ ] Verify UI update sau reload

### **Backend:**
- [ ] API `/loans/{id}/approve` có giảm availableCopies không
- [ ] Database có update chính xác không
- [ ] API `/documents/{id}` trả về fresh data (không cache)
- [ ] Handle race condition với transaction/lock
- [ ] Validate availableCopies >= 0

### **Integration:**
- [ ] Test full flow: Checkout → Approve → Back → UI update
- [ ] Test với nhiều users cùng lúc
- [ ] Test khi availableCopies = 0
- [ ] Test pull-to-refresh
- [ ] Test navigation paths khác nhau

---

## 🎯 Expected Behavior

### **Scenario: User quay lại từ Borrow History**

```
📱 User Actions:
1. Document Detail (Hiện có: 10)
2. Add to cart → Checkout
3. Đi đến Borrow History
4. Thủ thư approve (backend)
5. Refresh Borrow History → thấy "Chờ lấy sách" 🟣
6. Back về Document Detail

💻 System Behavior:
6.1. Navigator.pop() → didPopNext() triggered
6.2. _loadDocumentDetail() called
6.3. GET /api/documents/123
6.4. Response: { availableCopies: 9 }
6.5. setState() → UI rebuild
6.6. Display: Hiện có: 9 ✅

✅ Result: Số lượng đã cập nhật!
```

---

## 🔧 Quick Test Commands

```bash
# 1. Run app với verbose logs
flutter run --verbose

# 2. Mở DevTools
flutter pub global activate devtools
flutter pub global run devtools

# 3. Check network calls
# DevTools → Network tab → Filter "documents"

# 4. Check console logs
# DevTools → Logging tab → Search "DEBUG"
```

---

## 📝 Summary

**Root Cause:**
- ❌ Trước đây: Listen CartProvider (SAI - không liên quan loan status)
- ✅ Bây giờ: RouteAware + didPopNext() (ĐÚNG - detect khi quay lại)

**Solution:**
- User quay lại từ Borrow History → didPopNext() → reload → update UI
- Hoặc pull-to-refresh → manual reload

**Backend Must Do:**
- Approve loan → giảm availableCopies
- Return loan → tăng availableCopies
- API trả về fresh data (no cache)

**Testing:**
1. Add debug logs
2. Check didPopNext triggers
3. Check API response values
4. Verify backend updates DB
5. Test UI updates correctly

---

**Last Updated:** Nov 20, 2025  
**Status:** ✅ Frontend Fixed | ⏳ Needs Testing | ⚠️ Backend Must Update availableCopies
