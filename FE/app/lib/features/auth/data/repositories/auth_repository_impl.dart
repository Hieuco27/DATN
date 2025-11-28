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
import '../../../../core/services/notification_service.dart';

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
      // Validation cơ bản
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email và password không được để trống');
      }

      final LoginResponseModel response = await remoteDataSource.login(
        email,
        password,
      );

      if (response.success && response.data != null) {
        // Kiêm tra roleId của trước khi lưulưu
        if (response.data!.roleId != 3) {
          print(
            '❌ User is not a reader (roleId=${response.data!.roleId}). Blocking login.',
          );
          throw Exception('Ứng dụng này chỉ dành cho độc giả');
        }
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
          '✅ Login successful, tokens and account saved for: ${response.data!.email}',
        );
        print('👤 User role: ${response.data!.roleId}');
        
        // 🔔 Đăng ký FCM Token lên server
        // _registerFcmTokenAfterLogin(response.data!.accessToken);
        
        return response.toEntity();
      } else {
        // Nếu login không thành công, throw exception thay vì chỉ print
        throw Exception(response.message.isNotEmpty 
          ? response.message 
          : 'Đăng nhập thất bại');
      }
    } catch (e) {
      // Phân loại lỗi để xử lý phù hợp
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      if (errorMessage.contains('Network') || errorMessage.contains('mạng')) {
        throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra internet');
      } else if (errorMessage.contains('Format')) {
        throw Exception('Lỗi xử lý dữ liệu từ server');
      } else {
        // Rethrow với message gốc, không thêm prefix
        rethrow;
      }
    }
  }

  @override
  Future<Map<String, dynamic>> registerInit(String email) async {
    try {
      return await remoteDataSource.registerInit(email);
    } catch (e) {
      throw Exception('Không thể gửi mã OTP: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> registerVerify(
    Map<String, dynamic> verifyData,
  ) async {
    try {
      return await remoteDataSource.registerVerify(verifyData);
    } catch (e) {
      throw Exception('Xác thực OTP thất bại: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> registerComplete(
    Map<String, dynamic> completeData,
  ) async {
    try {
      return await remoteDataSource.registerComplete(completeData);
    } catch (e) {
      throw Exception('Hoàn tất đăng ký thất bại: ${e.toString()}');
    }
  }

  @override
  Future<RegisterResponse> register(Map<String, dynamic> data) async {
    try {
      // Validation dữ liệu đăng ký
      if (data['email'] == null || data['password'] == null) {
        throw Exception('Email và password là bắt buộc');
      }

      if ((data['password'] as String).length < 6) {
        throw Exception('Mật khẩu phải có ít nhất 6 ký tự');
      }
      final RegisterResponseModel response = await remoteDataSource.register(
        data,
      );
      if (response.success && response.data != null) {
        if (response.data!.roleId != 3) {
          throw Exception('Ứng dụng này chỉ dành cho độc giả');
        }
        // Kiểm tra token trước khi lưu
        if (response.data!.accessToken.isEmpty ||
            response.data!.refreshToken.isEmpty) {
          // Tự động đăng nhập sau khi đăng ký thành công
          try {
            final loginResponse = await remoteDataSource.login(
              data['email'] as String,
              data['password'] as String,
            );

            if (loginResponse.success && loginResponse.data != null) {
              if (loginResponse.data!.roleId != 3) {
                throw Exception('Ứng dụng này chỉ dành cho độc giả');
              }
              // LƯU TOKEN VÀ ACCOUNT DATA SAU KHI AUTO-LOGIN THÀNH CÔNG
              if (loginResponse.data!.roleId != 3) {
                throw Exception('Ứng dụng này chỉ dành cho độc giả');
              }
              await Future.wait([
                localStorageDataSource.saveTokens(
                  loginResponse.data!.accessToken,
                  loginResponse.data!.refreshToken,
                ),
                localStorageDataSource.saveAccount(loginResponse.data!),
              ]);
            } else {}
          } catch (e) {}
        } else {
          // LƯU TOKEN VÀ ACCOUNT DATA SAU KHI ĐĂNG KÝ THÀNH CÔNG
          await Future.wait([
            localStorageDataSource.saveTokens(
              response.data!.accessToken,
              response.data!.refreshToken,
            ),
            localStorageDataSource.saveAccount(response.data!),
          ]);
        }
      } else {
        throw Exception('Đăng ký thất bại: ${response.message}');
      }

      return response.toEntity(); //  Trả về Entity thay vì Model
    } catch (e) {
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
        } catch (e) {
          // Vẫn tiếp tục clear local data dù API call thất bại
        }
      }

      // Luôn clear local data
      await localStorageDataSource.clearAllData();
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

      if (isLoggedIn) {
        // Kiểm tra thêm xem token có hết hạn không (nếu cần)
        // final isTokenValid = await _checkTokenValidity();
        // return isTokenValid;
      }

      return isLoggedIn;
    } catch (e) {
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
        return account; // Trả về Account Entity
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<LoginResponse?> refreshToken() async {
    try {
      final refreshToken = await localStorageDataSource.getRefreshToken();
      if (refreshToken == null) {
        return null;
      }

      final LoginResponseModel response = await remoteDataSource.refreshToken(
        refreshToken,
      );

      if (response.success && response.data != null) {
        if (response.data!.roleId != 3) {
          await localStorageDataSource.clearAllData();
          throw Exception('Ứng dụng này chỉ dành cho độc giả');
        }

        // Kiểm tra token trước khi lưu
        if (response.data!.accessToken.isEmpty ||
            response.data!.refreshToken.isEmpty) {
          throw Exception('Token không hợp lệ từ server');
        }

        await localStorageDataSource.saveTokens(
          response.data!.accessToken,
          response.data!.refreshToken,
        );

        return response.toEntity();
      } else {
        // Refresh thất bại nhưng không xoá dữ liệu ở đây; để caller quyết định
        return null;
      }
    } catch (e) {
      // Không xoá dữ liệu ở đây để tránh trùng lặp clear
      return null;
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final token = await localStorageDataSource.getAccessToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  // Helper method: Tự động refresh token khi gặp lỗi 401
  Future<bool> _handleTokenExpiration() async {
    try {
      final refreshResponse = await refreshToken();
      if (refreshResponse != null &&
          refreshResponse.success &&
          refreshResponse.data != null) {
        return true;
      } else {
        await localStorageDataSource.clearAllData();
        return false;
      }
    } catch (refreshError) {
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
    } catch (e) {
      throw Exception('Failed to update user profile');
    }
  }

  @override
  @override
  Future<ReaderEntity> getProfile() async {
    try {
      final accessToken = await localStorageDataSource.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Không có token để lấy thông tin profile');
      }

      // call lần đầu với token hiện tại
      final ReaderModel profileModel = await remoteDataSource.getProfile(
        accessToken,
      );
      return profileModel;
    } catch (e) {
      // chỉ refresh nếu là lỗi hết hạn/401
      if (e.toString().contains('Token không hợp lệ hoặc đã hết hạn') ||
          e.toString().contains('401')) {
        final refreshSuccess = await _handleTokenExpiration();
        if (refreshSuccess) {
          final ReaderModel retried = await _retryWithNewToken(
            (t) => remoteDataSource.getProfile(t),
          );
          return retried;
        } else {
          throw Exception(
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          );
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
      final ReaderModel updatedProfile = await remoteDataSource.updateProfile(
        accessToken,
        profileData,
      );
      return updatedProfile;
    } catch (e) {
      // Kiểm tra nếu lỗi là do token hết hạn (401)
      if (e.toString().contains('Token không hợp lệ hoặc đã hết hạn') ||
          e.toString().contains('401')) {
        final refreshSuccess = await _handleTokenExpiration();
        if (refreshSuccess) {
          try {
            final ReaderModel updatedProfile = await _retryWithNewToken(
              (token) => remoteDataSource.updateProfile(token, profileData),
            );
            return updatedProfile;
          } catch (retryError) {
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

  @override
  Future<void> changePassword({
    required String accessToken,
    required String email,
    required String phoneNumber,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        accessToken: accessToken,
        email: email,
        phoneNumber: phoneNumber,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      // Kiểm tra nếu lỗi là do token hết hạn (401)
      if (e.toString().contains('Token không hợp lệ hoặc đã hết hạn') ||
          e.toString().contains('401')) {
        final refreshSuccess = await _handleTokenExpiration();
        if (refreshSuccess) {
          final newAccessToken = await localStorageDataSource.getAccessToken();
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await remoteDataSource.changePassword(
              accessToken: newAccessToken,
              email: email,
              phoneNumber: phoneNumber,
              oldPassword: oldPassword,
              newPassword: newPassword,
            );
            return;
          }
        }
        throw Exception(
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      throw Exception(
        'Lỗi đổi mật khẩu: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}
