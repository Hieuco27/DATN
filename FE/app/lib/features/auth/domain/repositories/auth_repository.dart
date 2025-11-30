import '../entities/login_response.dart';
import '../entities/register_response.dart';
import '../entities/account_entity.dart';
import '../entities/reader_entity.dart';

abstract class AuthenticationRepository {
  Future<LoginResponse> login(String email, String password);
  Future<RegisterResponse> register(Map<String, dynamic> account);

  // New 3-step registration flow
  Future<Map<String, dynamic>> registerInit(String email);
  Future<Map<String, dynamic>> registerVerify(Map<String, dynamic> verifyData);
  Future<Map<String, dynamic>> registerComplete(
    Map<String, dynamic> completeData,
  );

  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<Account?> getCurrentUser();
  Future<LoginResponse?> refreshToken();
  Future<String?> getAccessToken();
  Future<ReaderEntity> getProfile();
  Future<ReaderEntity> updateProfile(Map<String, dynamic> profileData);
  Future<void> changePassword({
    required String accessToken,
    required String email,
    required String phoneNumber,
    required String oldPassword,
    required String newPassword,
  });
  
  // Forgot Password
  Future<void> forgotPasswordSendOtp(String email);
  Future<void> forgotPasswordVerifyOtp({
    required String email,
    required String otp,
  });
  Future<void> forgotPasswordResetPassword({
    required String email,
    required String newPassword,
  });
}
