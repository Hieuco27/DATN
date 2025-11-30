# ✅ Forgot Password - 2 Step Flow (Verify OTP riêng biệt)

## 🎯 Flow mới (Tách riêng Verify OTP và Reset Password)

### API Endpoints (Backend):
```
1. POST /api/auth/forgot/send-otp
   Body: { "email": "user@example.com" }
   → Gửi OTP đến email

2. POST /api/auth/forgot/verify-otp
   Body: { "email": "user@example.com", "otp": "123456" }
   → CHỈ xác thực OTP (không có password)

3. POST /api/auth/forgot/reset-password
   Body: { "email": "user@example.com", "newPassword": "newpass123" }
   → Đặt lại mật khẩu mới (sau khi OTP đã verify)
```

---

## 📱 User Flow hoàn chỉnh:

```
1. User ở Sign In Page
   ↓ Click "Quên mật khẩu?"
   
2. Dialog nhập Email
   ↓ Nhập email + Click "Gửi OTP"
   
3. API Call: POST /auth/forgot/send-otp
   ↓ Success
   
4. Navigate to ForgotPasswordOtpPage
   ↓ User nhập 6 số OTP
   ↓ User nhập mật khẩu mới + xác nhận
   ↓ Click "Đặt lại mật khẩu"
   
5. API Call 1: POST /auth/forgot/verify-otp
   ↓ Verify OTP thành công
   
6. API Call 2: POST /auth/forgot/reset-password
   ↓ Đặt lại mật khẩu thành công
   
7. Success Dialog
   ↓ Click "Đăng nhập ngay"
   
8. Quay về Sign In Page
   → Đăng nhập với mật khẩu mới
```

---

## 🏗️ Architecture (Clean Architecture)

### 1. Data Layer

#### Remote Data Source
```dart
// authentication_remote_data_source.dart

abstract class AuthenticationRemoteDataSource {
  Future<Map<String, dynamic>> forgotPasswordSendOtp(String email);
  
  Future<Map<String, dynamic>> forgotPasswordVerifyOtp({
    required String email,
    required String otp,
  });
  
  Future<Map<String, dynamic>> forgotPasswordResetPassword({
    required String email,
    required String newPassword,
  });
}
```

#### Repository Implementation
```dart
// auth_repository_impl.dart

@override
Future<void> forgotPasswordVerifyOtp({
  required String email,
  required String otp,
}) async {
  // CHỈ validate email và OTP
  // GỌI API verify-otp
}

@override
Future<void> forgotPasswordResetPassword({
  required String email,
  required String newPassword,
}) async {
  // Validate email và password
  // GỌI API reset-password
}
```

### 2. Domain Layer

#### Use Cases
```dart
// forgot_password_usecase.dart

// Use Case 1: Send OTP
class ForgotPasswordSendOtpUseCase { ... }

// Use Case 2: Verify OTP (KHÔNG có password)
class ForgotPasswordVerifyOtpUseCase {
  Future<Result<void>> call(ForgotPasswordVerifyOtpParams params) {
    // params chỉ có: email, otp
    // KHÔNG có newPassword
  }
}

// Use Case 3: Reset Password (SAU KHI verify OTP)
class ForgotPasswordResetPasswordUseCase {
  Future<Result<void>> call(ForgotPasswordResetPasswordParams params) {
    // params có: email, newPassword, confirmPassword
  }
}
```

### 3. Presentation Layer

#### OTP Page Logic
```dart
// forgot_password_otp_page.dart

Future<void> _verifyOtpAndResetPassword() async {
  // STEP 1: Verify OTP
  final verifyResult = await ForgotPasswordVerifyOtpUseCase()(
    email: widget.email,
    otp: otp,
  );
  
  if (!verifyResult.isSuccess) {
    // Show error: "Mã OTP không hợp lệ"
    return;
  }
  
  // STEP 2: Reset Password (chỉ khi OTP verify thành công)
  final resetResult = await ForgotPasswordResetPasswordUseCase()(
    email: widget.email,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );
  
  if (resetResult.isSuccess) {
    // Show success dialog
  }
}
```

---

## 🔒 Security Benefits

### Tại sao tách riêng Verify OTP và Reset Password?

1. **Tăng bảo mật**: 
   - OTP chỉ dùng để XÁC THỰC danh tính
   - Mật khẩu mới chỉ được gửi SAU KHI đã xác thực

2. **Tránh brute force**:
   - Không thể thử nhiều OTP + password cùng lúc
   - Mỗi bước validate riêng biệt

3. **Audit trail tốt hơn**:
   - Backend có thể log riêng: "OTP verified" vs "Password reset"
   - Dễ dàng track abuse

4. **Rate limiting hiệu quả**:
   - Giới hạn verify OTP riêng
   - Giới hạn reset password riêng

---

## 📊 API Request/Response Examples

### 1. Send OTP
```http
POST /api/auth/forgot/send-otp
Content-Type: application/json

{
  "email": "user@example.com"
}

Response 200:
{
  "success": true,
  "message": "OTP đã được gửi đến email của bạn"
}
```

### 2. Verify OTP
```http
POST /api/auth/forgot/verify-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456"
}

Response 200:
{
  "success": true,
  "message": "Xác thực OTP thành công"
}

Response 400:
{
  "success": false,
  "message": "Mã OTP không hợp lệ hoặc đã hết hạn"
}
```

### 3. Reset Password
```http
POST /api/auth/forgot/reset-password
Content-Type: application/json

{
  "email": "user@example.com",
  "newPassword": "newpass123"
}

Response 200:
{
  "success": true,
  "message": "Đặt lại mật khẩu thành công"
}

Response 400:
{
  "success": false,
  "message": "Email không hợp lệ hoặc OTP chưa được xác thực"
}
```

---

## 🧪 Testing Scenarios

### Test Case 1: Happy Path
```
✅ Nhập email → OTP sent
✅ Nhập OTP đúng → OTP verified
✅ Nhập password mới → Password reset thành công
✅ Đăng nhập với password mới → Success
```

### Test Case 2: OTP sai
```
✅ Nhập email → OTP sent
❌ Nhập OTP sai → Error: "Mã OTP không hợp lệ"
→ User không đến được bước reset password
```

### Test Case 3: OTP hết hạn
```
✅ Nhập email → OTP sent
⏰ Đợi > 10 phút
❌ Nhập OTP → Error: "Mã OTP đã hết hạn"
✅ Click "Gửi lại OTP" → Nhận OTP mới
✅ Nhập OTP mới → Success
```

### Test Case 4: Password yếu
```
✅ Nhập email → OTP sent
✅ Nhập OTP đúng → OTP verified
❌ Nhập password < 6 ký tự → Error: "Mật khẩu phải có ít nhất 6 ký tự"
```

### Test Case 5: Password không khớp
```
✅ Nhập email → OTP sent
✅ Nhập OTP đúng → OTP verified
❌ Password ≠ Confirm Password → Error: "Mật khẩu xác nhận không khớp"
```

---

## 🎨 UI/UX Flow

### OTP Page có 2 phases:

#### Phase 1: Input (User nhập)
```
┌────────────────────────────────┐
│   6 ô OTP: □ □ □ □ □ □        │
│                                │
│   Password mới:  [________]    │
│   Xác nhận:      [________]    │
│                                │
│   [ Đặt lại mật khẩu ]         │
└────────────────────────────────┘
```

#### Phase 2: Processing (Khi user click button)
```
Step 1: Verify OTP
  ↓ Loading...
  ↓ API call /verify-otp
  ↓ 
  ✅ OTP valid
  ↓
Step 2: Reset Password
  ↓ Loading...
  ↓ API call /reset-password
  ↓
  ✅ Password reset thành công
  ↓
  Show Success Dialog
```

---

## ⚠️ Important Notes

1. **OTP phải verify trước**: Backend phải đảm bảo endpoint `/reset-password` chỉ chấp nhận request SAU KHI OTP đã được verify.

2. **Session/Token**: Backend có thể:
   - Option 1: Lưu verified OTP trong session (10 phút)
   - Option 2: Trả về temp token sau verify OTP
   - Option 3: Check trong database: `otp_verified = true`

3. **Race condition**: Nếu user click button nhiều lần nhanh, frontend phải disable button trong khi processing.

4. **Error handling**: Mỗi step phải có error handling riêng để user biết chính xác lỗi ở đâu.

---

## 🚀 Deployment Checklist

- [x] Backend API `/auth/forgot/send-otp`
- [x] Backend API `/auth/forgot/verify-otp`
- [x] Backend API `/auth/forgot/reset-password`
- [x] Frontend Data Source implementation
- [x] Frontend Repository implementation
- [x] Frontend Use Cases (3 use cases)
- [x] Frontend UI (Sign In dialog + OTP Page)
- [x] Error handling cho từng step
- [x] Loading states
- [x] Validation (email, OTP, password)
- [ ] Backend session/token management
- [ ] Rate limiting cho mỗi endpoint
- [ ] Monitoring & Logging
- [ ] End-to-end testing

---

**✅ Hoàn thành! Flow 2 bước đã sẵn sàng!**

Last updated: $(Get-Date)
