# Các Loại Thông Báo Trong Ứng Dụng

Tài liệu này mô tả chi tiết các loại thông báo mà trang thông báo sẽ hiển thị cho người dùng.

## 📋 Tổng Quan

Trang thông báo hiển thị tất cả các thông báo liên quan đến hoạt động của người dùng trong hệ thống thư viện, bao gồm:

- Thông báo về mượn sách
- Thông báo về thanh toán
- Thông báo hệ thống

---

## 🔔 Các Loại Thông Báo

### 1. **SYSTEM** - Thông Báo Hệ Thống

**Icon:** ℹ️ `Icons.info_outline`  
**Màu:** 🔵 Xanh dương (Blue)  
**Nhãn hiển thị:** "Hệ thống"

**Mô tả:**

- Thông báo chung từ hệ thống
- Thông báo bảo trì, cập nhật, hoặc các thông tin quan trọng

**Ví dụ:**

- "Thông báo bảo trì thư viện"
- "Thư viện đóng cửa vào thứ 7"
- "Cập nhật tính năng mới"
- "Thông báo về quy định mới"

**Khi nào gửi:**

- Khi có thông báo chung từ admin
- Khi hệ thống bảo trì
- Khi có cập nhật quan trọng

---

### 2. **LOAN_PENDING** - Đang Chờ Duyệt

**Icon:** ⏰ `Icons.access_time`  
**Màu:** 🟠 Cam (Orange)  
**Nhãn hiển thị:** "Chờ duyệt"

**Mô tả:**

- Thông báo khi user đăng ký mượn sách thành công
- Đơn mượn đang chờ admin duyệt

**Ví dụ:**

- **Title:** "Đăng ký mượn sách thành công"
- **Content:** "Yêu cầu mượn sách của bạn đang được xử lý. Vui lòng chờ duyệt."

**Khi nào gửi:**

- Ngay sau khi user đăng ký mượn sách thành công
- Khi đơn mượn được tạo với trạng thái "PENDING"

**Dữ liệu kèm theo:**

- `loan_id`: ID của đơn mượn
- `document_id`: ID của sách
- `document_title`: Tên sách

---

### 3. **LOAN_APPROVED** - Đã Được Duyệt

**Icon:** ✅ `Icons.check_circle_outline`  
**Màu:** 🟢 Xanh lá (Green)  
**Nhãn hiển thị:** "Đã duyệt"

**Mô tả:**

- Thông báo khi admin duyệt đơn mượn
- User có thể đến thư viện để nhận sách

**Ví dụ:**

- **Title:** "Đơn mượn đã được duyệt"
- **Content:** "Đơn mượn sách 'Sách XYZ' đã được duyệt. Vui lòng đến thư viện để nhận sách."

**Khi nào gửi:**

- Khi admin duyệt đơn mượn (status = 'APPROVED')
- Từ backend khi có sự kiện duyệt đơn

**Dữ liệu kèm theo:**

- `loan_id`: ID của đơn mượn
- `document_id`: ID của sách
- `document_title`: Tên sách

---

### 4. **LOAN_REJECTED** - Từ Chối

**Icon:** ❌ `Icons.cancel_outlined`  
**Màu:** 🔴 Đỏ (Red)  
**Nhãn hiển thị:** "Từ chối"

**Mô tả:**

- Thông báo khi admin từ chối đơn mượn
- Kèm theo lý do từ chối

**Ví dụ:**

- **Title:** "Đơn mượn bị từ chối"
- **Content:** "Đơn mượn sách 'Sách ABC' đã bị từ chối. Lý do: Sách đã được mượn hết."

**Khi nào gửi:**

- Khi admin từ chối đơn mượn (status = 'REJECTED')
- Từ backend khi có sự kiện từ chối đơn

**Dữ liệu kèm theo:**

- `loan_id`: ID của đơn mượn
- `document_id`: ID của sách
- `document_title`: Tên sách
- `rejection_reason`: Lý do từ chối

---

### 5. **LOAN_READY** - Sách Sẵn Sàng

**Icon:** ✅ `Icons.done_all`  
**Màu:** 🔵 Xanh dương (Blue)  
**Nhãn hiển thị:** "Sẵn sàng"

**Mô tả:**

- Thông báo khi sách đã được chuẩn bị sẵn
- User có thể đến thư viện để nhận sách

**Ví dụ:**

- **Title:** "Sách đã sẵn sàng"
- **Content:** "Sách 'Sách XYZ' đã sẵn sàng. Vui lòng đến thư viện để nhận sách trong vòng 3 ngày."

**Khi nào gửi:**

- Khi admin cập nhật loan status = 'READY'
- Khi sách đã được chuẩn bị và sẵn sàng để user đến lấy

**Dữ liệu kèm theo:**

- `loan_id`: ID của đơn mượn
- `document_id`: ID của sách
- `document_title`: Tên sách

---

### 6. **LOAN_DUE_SOON** - Sắp Đến Hạn

**Icon:** ⏰ `Icons.schedule`  
**Màu:** 🟠 Cam (Orange)  
**Nhãn hiển thị:** "Sắp đến hạn"

**Mô tả:**

- Thông báo nhắc nhở sách sắp đến hạn trả
- Thường gửi 3 ngày trước khi đến hạn

**Ví dụ:**

- **Title:** "Sách sắp đến hạn trả"
- **Content:** "Sách 'Sách ABC' sẽ đến hạn trả vào 15/11/2025. Vui lòng chuẩn bị trả sách."

**Khi nào gửi:**

- Tự động từ cron job (chạy hàng ngày)
- 3 ngày trước khi đến hạn trả
- Chỉ gửi 1 lần cho mỗi đơn mượn

**Dữ liệu kèm theo:**

- `loan_id`: ID của đơn mượn
- `document_id`: ID của sách
- `document_title`: Tên sách
- `due_date`: Ngày đến hạn

---

### 7. **LOAN_OVERDUE** - Quá Hạn Trả

**Icon:** ⚠️ `Icons.warning_amber`  
**Màu:** 🔴 Đỏ (Red)  
**Nhãn hiển thị:** "Quá hạn"

**Mô tả:**

- Thông báo khi sách đã quá hạn trả
- Nhắc nhở user trả sách ngay

**Ví dụ:**

- **Title:** "Sách đã quá hạn trả"
- **Content:** "Sách 'Sách XYZ' đã quá hạn 5 ngày. Vui lòng trả sách sớm nhất có thể."

**Khi nào gửi:**

- Tự động từ cron job (chạy hàng ngày)
- Khi `due_date < today`
- Có thể gửi nhiều lần cho đến khi trả sách

**Dữ liệu kèm theo:**

- `loan_id`: ID của đơn mượn
- `document_id`: ID của sách
- `document_title`: Tên sách
- `due_date`: Ngày đến hạn
- `days_overdue`: Số ngày quá hạn

---

### 8. **PAYMENT_SUCCESS** - Thanh Toán Thành Công

**Icon:** 💳 `Icons.payment`  
**Màu:** 🟢 Xanh lá (Green)  
**Nhãn hiển thị:** "Thanh toán"

**Mô tả:**

- Thông báo khi thanh toán thẻ Premium thành công
- Thẻ Premium đã được kích hoạt

**Ví dụ:**

- **Title:** "Thanh toán thành công"
- **Content:** "Thanh toán thẻ Premium đã thành công. Thẻ của bạn đã được kích hoạt."

**Khi nào gửi:**

- Khi payment status = 'SUCCESS' (từ PayOS webhook)
- Sau khi thanh toán thành công

**Dữ liệu kèm theo:**

- `payment_id`: ID của giao dịch
- `amount`: Số tiền thanh toán
- `order_code`: Mã đơn hàng

---

## 🎨 Giao Diện Hiển Thị

### Cấu Trúc Một Thông Báo

```
┌─────────────────────────────────────────┐
│  [Icon]  Title                    [•]   │  ← Chưa đọc có chấm đỏ
│          Content...                      │
│          [Tag]  Thời gian                │
└─────────────────────────────────────────┘
```

### Màu Sắc Theo Loại

| Loại                           | Màu           | Ý Nghĩa              |
| ------------------------------ | ------------- | -------------------- |
| LOAN_APPROVED, PAYMENT_SUCCESS | 🟢 Xanh lá    | Thành công, tích cực |
| LOAN_REJECTED, LOAN_OVERDUE    | 🔴 Đỏ         | Lỗi, cảnh báo        |
| LOAN_PENDING, LOAN_DUE_SOON    | 🟠 Cam        | Đang chờ, nhắc nhở   |
| SYSTEM, LOAN_READY             | 🔵 Xanh dương | Thông tin            |

### Trạng Thái Đọc

- **Chưa đọc:**

  - Nền: Xanh nhạt (`Color(0xFFE3F2FD)`)
  - Border: Cam đậm hơn, dày hơn
  - Title: Font đậm (FontWeight.w700)
  - Có chấm đỏ ở góc

- **Đã đọc:**
  - Nền: Trắng
  - Border: Xám nhạt, mỏng hơn
  - Title: Font bình thường (FontWeight.w500)
  - Không có chấm đỏ

---

## 🔍 Tính Năng Lọc

### Lọc Theo Loại

User có thể lọc thông báo theo loại:

- **Tất cả loại**: Hiển thị tất cả
- **Hệ thống**: Chỉ SYSTEM
- **Chờ duyệt**: Chỉ LOAN_PENDING
- **Đã duyệt**: Chỉ LOAN_APPROVED
- **Từ chối**: Chỉ LOAN_REJECTED

### Lọc Theo Trạng Thái Đọc

- **Tất cả**: Cả đã đọc và chưa đọc
- **Chưa đọc**: Chỉ thông báo chưa đọc
- **Đã đọc**: Chỉ thông báo đã đọc

---

## 📱 Ví Dụ Thực Tế

### Ví Dụ 1: User Mượn Sách

```
1. User đăng ký mượn sách "Harry Potter"
   ↓
2. Backend tạo notification:
   - Type: LOAN_PENDING
   - Title: "Đăng ký mượn sách thành công"
   - Content: "Yêu cầu mượn sách của bạn đang được xử lý..."
   ↓
3. User nhận thông báo (chưa đọc, màu cam)
   ↓
4. Admin duyệt đơn
   ↓
5. Backend tạo notification:
   - Type: LOAN_APPROVED
   - Title: "Đơn mượn đã được duyệt"
   - Content: "Đơn mượn sách 'Harry Potter' đã được duyệt..."
   ↓
6. User nhận thông báo mới (chưa đọc, màu xanh lá)
```

### Ví Dụ 2: Nhắc Nhở Trả Sách

```
1. User mượn sách, hạn trả: 20/11/2025
   ↓
2. Ngày 17/11/2025 (3 ngày trước):
   - Cron job chạy
   - Tạo notification: LOAN_DUE_SOON
   - Title: "Sách sắp đến hạn trả"
   ↓
3. Ngày 21/11/2025 (đã quá hạn):
   - Cron job chạy
   - Tạo notification: LOAN_OVERDUE
   - Title: "Sách đã quá hạn trả"
   - Content: "Sách 'Harry Potter' đã quá hạn 1 ngày..."
```

### Ví Dụ 3: Thanh Toán Premium

```
1. User thanh toán thẻ Premium (150k)
   ↓
2. PayOS xử lý thanh toán thành công
   ↓
3. Backend nhận webhook từ PayOS
   ↓
4. Backend tạo notification:
   - Type: PAYMENT_SUCCESS
   - Title: "Thanh toán thành công"
   - Content: "Thanh toán thẻ Premium đã thành công..."
   ↓
5. User nhận thông báo (màu xanh lá)
```

---

## 📊 Thống Kê

### Các Loại Thông Báo Theo Tần Suất

1. **LOAN_PENDING**: Mỗi lần user đăng ký mượn
2. **LOAN_APPROVED**: Mỗi lần admin duyệt đơn
3. **LOAN_DUE_SOON**: Tự động, 3 ngày trước hạn
4. **LOAN_OVERDUE**: Tự động, hàng ngày nếu quá hạn
5. **PAYMENT_SUCCESS**: Mỗi lần thanh toán thành công
6. **SYSTEM**: Theo nhu cầu của admin

---

## 🎯 Tóm Tắt

Trang thông báo hiển thị **8 loại thông báo chính**:

1. ✅ **SYSTEM** - Thông báo hệ thống
2. ⏰ **LOAN_PENDING** - Chờ duyệt mượn sách
3. ✅ **LOAN_APPROVED** - Đã duyệt mượn sách
4. ❌ **LOAN_REJECTED** - Từ chối mượn sách
5. ✅ **LOAN_READY** - Sách sẵn sàng để lấy
6. ⏰ **LOAN_DUE_SOON** - Sắp đến hạn trả
7. ⚠️ **LOAN_OVERDUE** - Quá hạn trả sách
8. 💳 **PAYMENT_SUCCESS** - Thanh toán thành công

Mỗi loại có:

- Icon riêng để dễ nhận biết
- Màu sắc phù hợp với ý nghĩa
- Nội dung rõ ràng, dễ hiểu
- Dữ liệu kèm theo để xử lý
