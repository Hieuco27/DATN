import '../entities/login_response.dart';
import '../entities/register_response.dart';
import '../entities/account_entity.dart';
import '../entities/reader_entity.dart';

abstract class AuthenticationRepository {
  Future<LoginResponse> login(String email, String password);
  Future<RegisterResponse> register(Map<String, dynamic> account);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<Account?> getCurrentUser();
  Future<LoginResponse?> refreshToken();
  Future<String?> getAccessToken();
  Future<ReaderEntity> getProfile();
  Future<ReaderEntity> updateProfile(Map<String, dynamic> profileData);
}
