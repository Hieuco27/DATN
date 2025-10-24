import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../models/login_response_model.dart';
import '../models/register_response_model.dart';
import '../models/reader_model.dart';
import 'package:book_tech/core/network_exception.dart';

abstract class AuthenticationRemoteDataSource {
  Future<LoginResponseModel> login(String email, String password);
  Future<RegisterResponseModel> register(Map<String, dynamic> accountData);
  Future<LoginResponseModel> refreshToken(String refreshToken);
  Future<void> logout(String accessToken);
  Future<ReaderModel> getProfile(String accessToken);
  Future<ReaderModel> updateProfile(String accessToken, Map<String, dynamic> profileData);
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com/api';
  static const Duration timeoutDuration = Duration(
    seconds: 60,
  ); // Tăng thời gian timeout

  // Tạo instance của Dio với cấu hình
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeoutDuration,
      receiveTimeout: timeoutDuration,
      sendTimeout: timeoutDuration,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  @override
  Future<LoginResponseModel> login(String email, String password) async {
    try {
      print('🔐 Attempting login for: $email');
      print('🌐 Connecting to: $baseUrl/auth/login');

      // Sử dụng Dio thay vì http
      final response = await dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      print('📨 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200) {
        try {
          return LoginResponseModel.fromJson(response.data);
        } catch (e) {
          print('❌ Error parsing response: $e');
          throw Exception('Lỗi xử lý dữ liệu đăng nhập');
        }
      } else {
        final message = response.data['message'] ?? 'Đăng nhập thất bại';
        throw Exception(message);
      }
    } on DioException catch (e) {
      print('❌ Network error: ${e.message}');
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception(
            'Kết nối tới server quá lâu. Vui lòng kiểm tra mạng và thử lại.',
          );
        case DioExceptionType.badResponse:
          final message = e.response?.data?['message'] ?? 'Đăng nhập thất bại';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Có lỗi xảy ra trong quá trình đăng nhập');
    }
  }

  @override
  Future<RegisterResponseModel> register(
    Map<String, dynamic> accountData,
  ) async {
    try {
      print('📝 Sending registration data: $accountData');

      final response = await dio.post('/auth/register', data: accountData);

      print('📨 Registration response status: ${response.statusCode}');
      print('📦 Registration response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          print('🔄 Parsing RegisterResponseModel from: ${response.data}');
          final result = RegisterResponseModel.fromJson(response.data);
          print('✅ Successfully parsed RegisterResponseModel: success=${result.success}, message=${result.message}');
          if (result.data != null) {
            print('📦 Account data: ${result.data!.toJson()}');
            print('🔑 Access token present: ${result.data!.accessToken.isNotEmpty}');
            print('🔄 Refresh token present: ${result.data!.refreshToken.isNotEmpty}');
          } else {
            print('⚠️ No account data in response');
          }
          return result;
        } catch (e) {
          print('❌ Error parsing RegisterResponseModel: $e');
          throw Exception('Lỗi xử lý dữ liệu đăng ký từ server: $e');
        }
      } else {
        final message = response.data['message'] ?? 'Đăng ký thất bại';
        print('❌ Registration failed with status ${response.statusCode}: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      print('❌ Network error during registration: ${e.message}');
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception(
            'Kết nối tới server quá lâu. Vui lòng kiểm tra mạng và thử lại.',
          );
        case DioExceptionType.badResponse:
          final message = e.response?.data?['message'] ?? 'Đăng ký thất bại';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      print('❌ Unexpected error during registration: $e');
      throw Exception('Có lỗi xảy ra trong quá trình đăng ký');
    }
  }

  @override
  Future<LoginResponseModel> refreshToken(String refreshToken) async {
    try {
      print('🔄 Refreshing token');

      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      print('📨 Token refresh response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw Exception('Không thể làm mới token');
      }
    } on DioException catch (e) {
      print('❌ Token refresh error: ${e.message}');
      throw Exception('Lỗi làm mới token: ${e.message}');
    }
  }

  @override
  Future<void> logout(String accessToken) async {
    try {
      print('🚪 Logging out');

      await dio.post(
        '/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      print('✅ Logout successful');
    } on DioException catch (e) {
      throw Exception('Lỗi đăng xuất: ${e.message}');
    }
  }

  @override
  Future<ReaderModel> getProfile(String accessToken) async {
    try {
      print('👤 Getting user profile');
      print('🔑 Access token: ${accessToken.substring(0, 10)}...');

      final response = await dio.get(
        '/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      print('📨 Profile response status: ${response.statusCode}');
      print('📦 Profile response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData == null) {
          throw Exception('Response data là null');
        }
        
        print('📦 Full response data: $responseData');
        
        // Kiểm tra success flag (nếu có)
        if (responseData is Map<String, dynamic> && responseData['success'] == false) {
          throw Exception('API trả về success: false - ${responseData['message'] ?? 'Unknown error'}');
        }
        
        // Tìm user data trong các cấu trúc khác nhau
        Map<String, dynamic>? userData;
        
        if (responseData is Map<String, dynamic>) {
          if (responseData['user'] != null) {
            userData = responseData['user'];
            print('👤 Found user data in responseData["user"]: $userData');
          } else if (responseData['data'] != null) {
            userData = responseData['data'];
            print('👤 Found user data in responseData["data"]: $userData');
          } else if (responseData['account'] != null) {
            userData = responseData['account'];
            print('👤 Found user data in responseData["account"]: $userData');
          } else if (responseData.containsKey('email')) {
            // Nếu responseData chính là user data
            userData = responseData;
            print('👤 Response data is user data itself: $userData');
          }
        }
        
        if (userData == null) {
          if (responseData is Map<String, dynamic>) {
            print('📦 Available keys: ${responseData.keys.toList()}');
          }
          throw Exception('Dữ liệu user không tồn tại trong response. Response type: ${responseData.runtimeType}');
        }
        
        print('👤 User data found: $userData');
        
        // Tạo fallback data nếu thiếu thông tin cần thiết
        final fallbackUserData = {
          'accountId': userData['accountId']?.toString() ?? userData['id']?.toString() ?? 'unknown',
          'email': userData['email']?.toString() ?? 'unknown@example.com',
          'roleName': userData['roleName']?.toString() ?? userData['role']?.toString() ?? 'reader',
          'fullName': userData['fullName']?.toString() ?? userData['name']?.toString() ?? '',
          'phoneNumber': userData['phoneNumber']?.toString() ?? userData['phone']?.toString() ?? '',
          'address': userData['address']?.toString() ?? '',
          'dateOfBirth': userData['dateOfBirth']?.toString() ?? userData['birthday']?.toString() ?? '',
          'cccd': userData['cccd']?.toString() ?? '',
          'totolBorrow': userData['totolBorrow'] is int ? userData['totolBorrow'] : int.tryParse(userData['totolBorrow']?.toString() ?? '0') ?? 0,
        };
        
        print('📦 Fallback user data: $fallbackUserData');
        
        try {
          return ReaderModel.fromJson(fallbackUserData);
        } catch (parseError) {
          throw Exception('Lỗi xử lý dữ liệu profile: $parseError');
        }
      } else {
        print('❌ Profile API failed with status ${response.statusCode}');
        if (response.statusCode == 401) {
          throw Exception('Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.');
        } else if (response.statusCode == 404) {
          throw Exception('Không tìm thấy thông tin profile.');
        } else {
          final errorMessage = response.data is Map<String, dynamic> 
              ? response.data['message'] ?? 'Unknown error'
              : 'HTTP ${response.statusCode}';
          throw Exception('HTTP ${response.statusCode}: $errorMessage');
        }
      }
    } on DioException catch (e) {
      print('❌ Get profile error: ${e.message}');
      print('❌ Error type: ${e.type}');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Response status: ${e.response?.statusCode}');
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.sendTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Kết nối tới server quá lâu. Vui lòng kiểm tra mạng và thử lại.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy thông tin profile.');
      } else {
        throw Exception('Lỗi lấy thông tin profile: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error in getProfile: $e');
      throw Exception('Lỗi không xác định khi lấy thông tin profile: $e');
    }
  }

  @override
  Future<ReaderModel> updateProfile(String accessToken, Map<String, dynamic> profileData) async {
    try {
      print('✏️ Updating user profile');
      print('📦 Profile data to update: $profileData');

      final response = await dio.put(
        '/auth/profile',
        data: profileData,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      print('📨 Update profile response status: ${response.statusCode}');
      print('📦 Update profile response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Kiểm tra response có chứa success flag không
        if (response.data is Map<String, dynamic> && response.data['success'] == false) {
          throw Exception('API trả về success: false - ${response.data['message'] ?? 'Unknown error'}');
        }
        
        // Sau khi update thành công, lấy lại thông tin profile mới
        return await getProfile(accessToken);
      } else {
        final errorMessage = response.data is Map<String, dynamic> 
            ? response.data['message'] ?? 'Unknown error'
            : 'HTTP ${response.statusCode}';
        throw Exception('Không thể cập nhật thông tin profile: $errorMessage');
      }
    } on DioException catch (e) {
      print('❌ Update profile error: ${e.message}');
      print('❌ Error type: ${e.type}');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Response status: ${e.response?.statusCode}');
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.sendTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Kết nối tới server quá lâu. Vui lòng kiểm tra mạng và thử lại.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data is Map<String, dynamic> 
            ? e.response?.data['message'] ?? 'Dữ liệu không hợp lệ'
            : 'Dữ liệu không hợp lệ';
        throw Exception('Dữ liệu không hợp lệ: $errorMessage');
      } else {
        throw Exception('Lỗi cập nhật thông tin profile: ${e.message}');
      }
    } catch (e) {
      print('❌ Unexpected error in updateProfile: $e');
      throw Exception('Lỗi không xác định khi cập nhật profile: $e');
    }
  }
  
}
