# 🔐 Hướng dẫn sử dụng tính năng Quên mật khẩu

## ✨ Tổng quan

Tính năng quên mật khẩu đã được triển khai đầy đủ với **Clean Architecture**, bao gồm:
- 🎨 Giao diện đẹp, thân thiện, dễ sử dụng
- 🔒 Bảo mật với OTP gửi qua email
- ⚡ Tích hợp đầy đủ với backend API
- ✅ Validation đầy đủ và xử lý lỗi tốt

---

## 📁 Cấu trúc File

### Backend (Đã có sẵn)
```
BE/src/
├── controller/authController.js
│   ├── forgotPasswordSendOtp()
│   └── forgotPasswordVerifyOtp()
├── service/authService.js
│   ├── sendForgotPasswordOtpService()
│   └── verifyOtpAndResetPasswordService()
└── routes/authRoutes.js
    ├── POST /api/auth/forgot/send-otp
    └── POST /api/auth/forgot/verify-otp
```

### Frontend (Mới tạo)
```
FE/app/lib/features/auth/
├── data/
│   ├── datasources/
│   │   └── authentication_remote_data_source.dart
│   │       ├── forgotPasswordSendOtp()
│   │       └── forgotPasswordVerifyOtp()
│   └── repositories/
│       └── auth_repository_impl.dart
│           ├── forgotPasswordSendOtp()
│           └── forgotPasswordVerifyOtp()
├── domain/
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       └── forgot_password_usecase.dart
│           ├── ForgotPasswordSendOtpUseCase
│           └── ForgotPasswordVerifyOtpUseCase
└── presentations/
    └── pages/
        ├── forgot_password_page.dart
        └── forgot_password_otp_page.dart
```

---

## 🚀 Cách sử dụng

### 1. Thêm Navigation từ Login Page

Trong file `login_page.dart`, thêm link "Quên mật khẩu":

```dart
import 'package:your_app/features/auth/presentations/pages/forgot_password_page.dart';

// Thêm vào UI của login page
TextButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordPage(),
      ),
    );
  },
  child: const Text(
    'Quên mật khẩu?',
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

### 2. Flow hoạt động

#### Bước 1: Nhập Email
```dart
// User mở ForgotPasswordPage
// Nhập email và nhấn "Gửi mã OTP"
// ➜ Gọi API: POST /api/auth/forgot/send-otp
```

#### Bước 2: Xác thực OTP
```dart
// User tự động chuyển đến ForgotPasswordOtpPage
// Nhập 6 số OTP + mật khẩu mới
// ➜ Gọi API: POST /api/auth/forgot/verify-otp
```

#### Bước 3: Hoàn tất
```dart
// Hiển thị dialog thành công
// User quay lại màn hình đăng nhập
```

---

## 🎨 Features UI

### ForgotPasswordPage
- ✅ Animation mượt mà khi load page
- ✅ Email validation real-time
- ✅ Loading state trong button
- ✅ Success/Error snackbar với icon
- ✅ Info box hướng dẫn người dùng
- ✅ Back button thân thiện

### ForgotPasswordOtpPage  
- ✅ 6 ô input OTP độc lập, tự động focus
- ✅ Animation scale cho icon
- ✅ Countdown timer 60 giây để resend
- ✅ Button "Gửi lại OTP" khi hết thời gian
- ✅ Hiển thị/ẩn mật khẩu
- ✅ Validation password matching
- ✅ Success dialog với animation
- ✅ Tự động navigate về login sau khi thành công

---

## 🔧 API Endpoints

### 1. Send OTP
```http
POST /api/auth/forgot/send-otp
Content-Type: application/json

{
  "email": "user@example.com"
}

Response 200 OK:
{
  "success": true,
  "message": "OTP đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư."
}

Response 404:
{
  "success": false,
  "message": "Email không tồn tại trong hệ thống"
}
```

### 2. Verify OTP
```http
POST /api/auth/forgot/verify-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456",
  "newPassword": "newpass123"
}

Response 200 OK:
{
  "success": true,
  "message": "Đặt lại mật khẩu thành công. Bạn có thể đăng nhập ngay."
}

Response 400:
{
  "success": false,
  "message": "Mã OTP không hợp lệ hoặc đã hết hạn"
}
```

---

## 🧪 Testing

### Test Cases cần kiểm tra:

1. **Email không tồn tại**
   - Nhập email chưa đăng ký
   - ➜ Phải hiện: "Email không tồn tại trong hệ thống"

2. **OTP hết hạn**
   - Đợi > 10 phút sau khi nhận OTP
   - ➜ Phải hiện: "Mã OTP không hợp lệ hoặc đã hết hạn"

3. **OTP sai**
   - Nhập OTP không đúng
   - ➜ Phải hiện: "Mã OTP không hợp lệ hoặc đã hết hạn"

4. **Mật khẩu không khớp**
   - Nhập 2 mật khẩu khác nhau
   - ➜ Phải hiện: "Mật khẩu xác nhận không khớp"

5. **Mật khẩu quá ngắn**
   - Nhập mật khẩu < 6 ký tự
   - ➜ Phải hiện: "Mật khẩu phải có ít nhất 6 ký tự"

6. **Resend OTP**
   - Click "Gửi lại OTP" sau 60 giây
   - ➜ Phải gửi được OTP mới

7. **Happy Path**
   - Nhập email đúng ➜ Nhận OTP
   - Nhập OTP đúng + mật khẩu mới
   - ➜ Đặt lại thành công ➜ Đăng nhập được

---

## 🎯 Customization

### Thay đổi màu sắc
```dart
// Trong forgot_password_page.dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, // Thay đổi màu này
    // ...
  ),
)
```

### Thay đổi thời gian OTP
```dart
// Trong forgot_password_otp_page.dart
void _startCountdown() {
  _resendCountdown = 120; // Đổi từ 60 giây thành 120 giây
  // ...
}
```

### Thay đổi số ký tự OTP
```dart
// Trong forgot_password_otp_page.dart
final List<TextEditingController> _otpControllers =
    List.generate(8, (_) => TextEditingController()); // Đổi từ 6 thành 8
```

---

## 📝 Notes

1. **Email Service**: Backend sử dụng SendGrid để gửi email. Đảm bảo có cấu hình `SENDGRID_API_KEY` trong `.env`

2. **OTP Storage**: OTP được lưu in-memory trên server (60 giây), không lưu database

3. **Security**: Sau khi đặt lại mật khẩu, tất cả refresh token cũ sẽ bị xóa (force logout all devices)

4. **UX**: Animation và loading state giúp user experience mượt mà hơn

5. **Error Handling**: Tất cả lỗi đều được hiển thị rõ ràng cho user

---

## 🐛 Troubleshooting

### Không nhận được email OTP?
- Kiểm tra spam folder
- Kiểm tra SendGrid API key
- Kiểm tra email có tồn tại không

### API call failed?
- Kiểm tra network connection
- Kiểm tra baseUrl trong `authentication_remote_data_source.dart`
- Xem log console để debug

### Navigation không hoạt động?
- Đảm bảo đã import đúng file
- Kiểm tra MaterialApp có đúng routes không

---

## ✅ Checklist triển khai

- [x] Backend API endpoints
- [x] Email service configuration
- [x] Frontend data layer
- [x] Frontend domain layer
- [x] Frontend presentation layer
- [x] Beautiful UI với animation
- [x] Error handling
- [x] Loading states
- [x] Validation
- [ ] Testing với user thật
- [ ] Deploy lên production

---

**🎉 Hoàn thành! Tính năng Quên mật khẩu đã sẵn sàng sử dụng!**
