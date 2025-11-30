import '../core/result.dart';
import '../core/failure.dart';
import '../core/usecase.dart';
import '../repositories/auth_repository.dart';

// ============================================================
// Send OTP Use Case
// ============================================================
class ForgotPasswordSendOtpParams {
  final String email;
  
  const ForgotPasswordSendOtpParams({required this.email});
}

class ForgotPasswordSendOtpUseCase
    implements UseCase<Result<void>, ForgotPasswordSendOtpParams> {
  final AuthenticationRepository repository;
  
  ForgotPasswordSendOtpUseCase(this.repository);

  @override
  Future<Result<void>> call(ForgotPasswordSendOtpParams params) async {
    // Validation
    if (params.email.trim().isEmpty) {
      return Result.fail(ValidationFailure('Email không được trống'));
    }

    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailPattern.hasMatch(params.email.trim())) {
      return Result.fail(ValidationFailure('Email không hợp lệ'));
    }

    try {
      await repository.forgotPasswordSendOtp(params.email.trim());
      return Result.ok(null);
    } catch (e) {
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}

// ============================================================
// Verify OTP Use Case
// ============================================================
class ForgotPasswordVerifyOtpParams {
  final String email;
  final String otp;
  
  const ForgotPasswordVerifyOtpParams({
    required this.email,
    required this.otp,
  });
}

class ForgotPasswordVerifyOtpUseCase
    implements UseCase<Result<void>, ForgotPasswordVerifyOtpParams> {
  final AuthenticationRepository repository;
  
  ForgotPasswordVerifyOtpUseCase(this.repository);

  @override
  Future<Result<void>> call(ForgotPasswordVerifyOtpParams params) async {
    // Validation
    if (params.email.trim().isEmpty) {
      return Result.fail(ValidationFailure('Email không được trống'));
    }

    if (params.otp.trim().isEmpty) {
      return Result.fail(ValidationFailure('Mã OTP không được trống'));
    }

    if (params.otp.trim().length != 6) {
      return Result.fail(ValidationFailure('Mã OTP phải có 6 ký tự'));
    }

    try {
      await repository.forgotPasswordVerifyOtp(
        email: params.email.trim(),
        otp: params.otp.trim(),
      );
      return Result.ok(null);
    } catch (e) {
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}

// ============================================================
// Reset Password Use Case
// ============================================================
class ForgotPasswordResetPasswordParams {
  final String email;
  final String newPassword;
  final String confirmPassword;
  
  const ForgotPasswordResetPasswordParams({
    required this.email,
    required this.newPassword,
    required this.confirmPassword,
  });
}

class ForgotPasswordResetPasswordUseCase
    implements UseCase<Result<void>, ForgotPasswordResetPasswordParams> {
  final AuthenticationRepository repository;
  
  ForgotPasswordResetPasswordUseCase(this.repository);

  @override
  Future<Result<void>> call(ForgotPasswordResetPasswordParams params) async {
    // Validation
    if (params.email.trim().isEmpty) {
      return Result.fail(ValidationFailure('Email không được trống'));
    }

    if (params.newPassword.isEmpty) {
      return Result.fail(ValidationFailure('Mật khẩu mới không được trống'));
    }

    if (params.newPassword.length < 6) {
      return Result.fail(
        ValidationFailure('Mật khẩu phải có ít nhất 6 ký tự'),
      );
    }

    if (params.newPassword != params.confirmPassword) {
      return Result.fail(ValidationFailure('Mật khẩu xác nhận không khớp'));
    }

    try {
      await repository.forgotPasswordResetPassword(
        email: params.email.trim(),
        newPassword: params.newPassword,
      );
      return Result.ok(null);
    } catch (e) {
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}
