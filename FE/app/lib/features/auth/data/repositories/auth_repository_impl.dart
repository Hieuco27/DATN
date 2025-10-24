import '../../domain/entities/account_entity.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/entities/register_response.dart';
import '../../domain/entities/reader_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/account_model.dart';
import '../models/login_response_model.dart';
import '../models/register_response_model.dart';
import '../datasources/authentication_remote_data_source.dart';
import '../datasources/local_storage_data_source.dart';
import '../models/reader_model.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  final AuthenticationRemoteDataSource remoteDataSource;
  final LocalStorageDataSource localStorageDataSource;

  AuthenticationRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorageDataSource,
  });

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      print('🔐 Starting login process for: $email');

      // Validation cơ bản
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email và password không được để trống');
      }

      final LoginResponseModel response = await remoteDataSource.login(
        email,

        password,
      );

      if (response.success && response.data != null) {
        // Kiểm tra token trước khi lưu
        if (response.data!.accessToken.isEmpty ||
            response.data!.refreshToken.isEmpty) {
          throw Exception('Token không hợp lệ từ server');
        }

        // LƯU TOKEN VÀ ACCOUNT DATA
        await Future.wait([
          localStorageDataSource.saveTokens(
            response.data!.accessToken,
            response.data!.refreshToken,
          ),
          localStorageDataSource.saveAccount(response.data!),
        ]);

        print(
          ' Login successful, tokens and account saved for: ${response.data!.email}',
        );
        print(' User role: ${response.data!.roleId}');
      } else {
        print(' Login failed: ${response.message}');
        // Không clear data ở đây vì có thể user chỉ nhập sai password
      }

      return response.toEntity(); // ✅ Trả về Entity thay vì Model
    } catch (e) {
      print('Login error: $e');

      // Phân loại lỗi để xử lý phù hợp
      if (e.toString().contains('Network') || e.toString().contains('mạng')) {
        throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra internet');
      } else if (e.toString().contains('Format')) {
        throw Exception('Lỗi xử lý dữ liệu từ server');
      } else {
        throw Exception(
          'Đăng nhập thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  @override
  Future<RegisterResponse> register(Map<String, dynamic> data) async {
    try {
      print('📝 Starting registration process for: ${data['email']}');
      print('📝 Registration data received: $data');

      // Validation dữ liệu đăng ký
      if (data['email'] == null || data['password'] == null) {
        print(
          '❌ Missing required fields: email=${data['email']}, password=${data['password']}',
        );
        throw Exception('Email và password là bắt buộc');
      }

      if ((data['password'] as String).length < 6) {
        print(
          '❌ Password too short: ${(data['password'] as String).length} characters',
        );
        throw Exception('Mật khẩu phải có ít nhất 6 ký tự');
      }

      print('✅ Repository validation passed, calling remote data source...');

      final RegisterResponseModel response = await remoteDataSource.register(
        data,
      );

      print(
        '📦 Repository received response: success=${response.success}, message=${response.message}',
      );
      print('📦 Response data: ${response.data}');

      if (response.success && response.data != null) {
        print('✅ Registration successful for: ${data['email']}');
        print('✅ Account created: ${response.data!.email}');

        // Kiểm tra token trước khi lưu
        if (response.data!.accessToken.isEmpty ||
            response.data!.refreshToken.isEmpty) {
          print('⚠️ Warning: No tokens received from registration response');
          print('📦 Response data structure: ${response.data!.toJson()}');
          print('🔄 Attempting auto-login after registration...');

          // Tự động đăng nhập sau khi đăng ký thành công
          try {
            final loginResponse = await remoteDataSource.login(
              data['email'] as String,
              data['password'] as String,
            );

            if (loginResponse.success && loginResponse.data != null) {
              // LƯU TOKEN VÀ ACCOUNT DATA SAU KHI AUTO-LOGIN THÀNH CÔNG
              await Future.wait([
                localStorageDataSource.saveTokens(
                  loginResponse.data!.accessToken,
                  loginResponse.data!.refreshToken,
                ),
                localStorageDataSource.saveAccount(loginResponse.data!),
              ]);
              print('💾 Tokens and account data saved after auto-login');
            } else {
              print('❌ Auto-login failed: ${loginResponse.message}');
            }
          } catch (e) {
            print('❌ Auto-login error: $e');
          }
        } else {
          // LƯU TOKEN VÀ ACCOUNT DATA SAU KHI ĐĂNG KÝ THÀNH CÔNG
          await Future.wait([
            localStorageDataSource.saveTokens(
              response.data!.accessToken,
              response.data!.refreshToken,
            ),
            localStorageDataSource.saveAccount(response.data!),
          ]);
          print('💾 Tokens and account data saved after registration');
        }
      } else {
        print('❌ Registration failed: ${response.message}');
        throw Exception('Đăng ký thất bại: ${response.message}');
      }

      return response.toEntity(); //  Trả về Entity thay vì Model
    } catch (e) {
      print(' Registration error: $e');

      // Xử lý lỗi cụ thể cho đăng ký
      final errorMessage = e.toString();
      if (errorMessage.contains('Email already exists') ||
          errorMessage.contains('Email đã tồn tại')) {
        throw Exception('Email đã được sử dụng');
      } else if (errorMessage.contains('Network')) {
        throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra internet');
      } else {
        throw Exception(
          'Đăng ký thất bại: ${errorMessage.replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Lấy access token trước khi clear data
      final accessToken = await localStorageDataSource.getAccessToken();

      // Gọi API logout nếu có token (không bắt buộc thành công)
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          await remoteDataSource.logout(accessToken);
          print(' Logout API call successful');
        } catch (e) {
          print(' Logout API call failed but continuing: $e');
          // Vẫn tiếp tục clear local data dù API call thất bại
        }
      }

      // Luôn clear local data
      await localStorageDataSource.clearAllData();
      print('Logout completed successfully');
    } catch (e) {
      // Vẫn clear local data ngay cả khi có lỗi
      await localStorageDataSource.clearAllData();
      throw Exception('Đăng xuất hoàn tất nhưng có lỗi xảy ra');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final isLoggedIn = await localStorageDataSource.isLoggedIn();
      print('🔍 Login status check: $isLoggedIn');

      if (isLoggedIn) {
        // Kiểm tra thêm xem token có hết hạn không (nếu cần)
        // final isTokenValid = await _checkTokenValidity();
        // return isTokenValid;
      }

      return isLoggedIn;
    } catch (e) {
      print(' Error checking login status: $e');
      // Khi có lỗi kiểm tra, coi như chưa đăng nhập để bảo mật
      return false;
    }
  }

  @override
  Future<Account?> getCurrentUser() async {
    try {
      final AccountModel? accountModel = await localStorageDataSource
          .getAccount();

      if (accountModel != null) {
        final account = accountModel.toEntity();
        print(
          ' Current user loaded: ${account.email} (Role: ${account.roleId})',
        );
        return account; // Trả về Account Entity
      } else {
        print(' No current user found');
        return null;
      }
    } catch (e) {
      print(' Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<LoginResponse?> refreshToken() async {
    try {
      final refreshToken = await localStorageDataSource.getRefreshToken();
      if (refreshToken == null) {
        print('❌ No refresh token available for refresh');
        return null;
      }

      print('🔄 Starting token refresh process...');

      final LoginResponseModel response = await remoteDataSource.refreshToken(
        refreshToken,
      );

      if (response.success && response.data != null) {
        // Kiểm tra token trước khi lưu
        if (response.data!.accessToken.isEmpty ||
            response.data!.refreshToken.isEmpty) {
          throw Exception('Token không hợp lệ từ server');
        }

        await localStorageDataSource.saveTokens(
          response.data!.accessToken,
          response.data!.refreshToken,
        );

        print('✅ Token refresh successful');
        return response.toEntity();
      } else {
        print('❌ Token refresh failed: ${response.message}');
        await localStorageDataSource.clearAllData();
        return null;
      }
    } catch (e) {
      print('💥 Token refresh error: $e');

      if (e.toString().contains('401') || e.toString().contains('invalid')) {
        print('🚨 Refresh token invalid, clearing local data...');
        await localStorageDataSource.clearAllData();
      }

      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final token = await localStorageDataSource.getAccessToken();
      return token;
    } catch (e) {
      print('💥 Error getting access token: $e');
      return null;
    }
  }

  // Helper method: Tự động refresh token khi gặp lỗi 401
  Future<bool> _handleTokenExpiration() async {
    try {
      print('🔄 Token expired, attempting to refresh...');

      final refreshResponse = await refreshToken();
      if (refreshResponse != null &&
          refreshResponse.success &&
          refreshResponse.data != null) {
        print('✅ Token refreshed successfully');
        return true;
      } else {
        print('❌ Token refresh failed');
        await localStorageDataSource.clearAllData();
        return false;
      }
    } catch (refreshError) {
      print('❌ Token refresh error: $refreshError');
      await localStorageDataSource.clearAllData();
      return false;
    }
  }

  // Helper method: Retry API call với token mới sau khi refresh
  Future<T> _retryWithNewToken<T>(
    Future<T> Function(String accessToken) apiCall,
  ) async {
    final newAccessToken = await localStorageDataSource.getAccessToken();
    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      return await apiCall(newAccessToken);
    } else {
      throw Exception('Không thể lấy token mới sau khi refresh');
    }
  }

  //Helper method: Update user profile (nếu cần)
  Future<void> updateUserProfile(Account updatedAccount) async {
    try {
      // Convert entity to model
      final accountModel = AccountModel(
        accountId: updatedAccount.accountId,
        email: updatedAccount.email,
        fullName: updatedAccount.fullName,
        phoneNumber: updatedAccount.phoneNumber,
        roleId: updatedAccount.roleId,
        accessToken: updatedAccount.accessToken ?? '',
        refreshToken: updatedAccount.refreshToken ?? '',
      );

      await localStorageDataSource.saveAccount(accountModel);
      print(' User profile updated successfully');
    } catch (e) {
      print(' Error updating user profile: $e');
      throw Exception('Failed to update user profile');
    }
  }

  @override
  Future<ReaderEntity> getProfile() async {
    try {
      final accessToken = await localStorageDataSource.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Không có token để lấy thông tin profile');
      }

      print('👤 Getting user profile...');
      final ReaderModel profileModel = await remoteDataSource.getProfile(
        accessToken,
      );

      print('✅ Profile loaded successfully for: ${profileModel.accountId}');
      print('📦 Profile data: ${profileModel.toJson()}');

      return profileModel;
    } catch (e) {
      print('💥 Error getting profile: $e');

      // Kiểm tra nếu lỗi là do token hết hạn (401)
      if (e.toString().contains('Token không hợp lệ hoặc đã hết hạn') ||
          e.toString().contains('401')) {
        final refreshSuccess = await _handleTokenExpiration();
        if (refreshSuccess) {
          try {
            final ReaderModel profileModel = await _retryWithNewToken(
              (token) => remoteDataSource.getProfile(token),
            );
            print(
              '✅ Profile loaded successfully after token refresh for: ${profileModel.accountId}',
            );
          } catch (retryError) {
            print('❌ Retry getProfile failed: $retryError');
            throw Exception(
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            );
          }
        } else {
          throw Exception(
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          );
        }
      }

      // Nếu lỗi là do thiếu dữ liệu user, thử lấy từ account data đã lưu
      if (e.toString().contains('Dữ liệu user không tồn tại')) {
        print('🔄 Attempting to get profile from saved account data...');
        try {
          final savedAccount = await localStorageDataSource.getAccount();
          if (savedAccount != null) {
            print('📦 Using saved account data as profile');
            final readerFromAccount = ReaderEntity(
              readerId: savedAccount.accountId ?? 0,
              accountId: savedAccount.accountId ?? 0,
              fullName: savedAccount.fullName,
              phoneNumber: savedAccount.phoneNumber,
            );
            return readerFromAccount;
          }
        } catch (accountError) {
          print('❌ Error getting profile from account: $accountError');
        }
      }

      throw Exception(
        'Lỗi lấy thông tin profile: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  @override
  Future<ReaderEntity> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final accessToken = await localStorageDataSource.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Không có token để cập nhật profile');
      }

      print('✏️ Updating user profile...');
      final ReaderModel updatedProfile = await remoteDataSource.updateProfile(
        accessToken,
        profileData,
      );

      print('✅ Profile updated successfully for: ${updatedProfile.accountId}');
      return updatedProfile;
    } catch (e) {
      print('💥 Error updating profile: $e');

      // Kiểm tra nếu lỗi là do token hết hạn (401)
      if (e.toString().contains('Token không hợp lệ hoặc đã hết hạn') ||
          e.toString().contains('401')) {
        final refreshSuccess = await _handleTokenExpiration();
        if (refreshSuccess) {
          try {
            final ReaderModel updatedProfile = await _retryWithNewToken(
              (token) => remoteDataSource.updateProfile(token, profileData),
            );
            print(
              '✅ Profile updated successfully after token refresh for: ${updatedProfile.accountId}',
            );
            return updatedProfile;
          } catch (retryError) {
            print('❌ Retry updateProfile failed: $retryError');
            throw Exception(
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            );
          }
        } else {
          throw Exception(
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          );
        }
      }

      throw Exception(
        'Lỗi cập nhật profile: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}
