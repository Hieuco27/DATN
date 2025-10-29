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
  Future<ReaderModel> updateProfile(
    String accessToken,
    Map<String, dynamic> profileData,
  );
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 60);

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
      // Sử dụng Dio thay vì http
      final response = await dio.post(
        '/auth/login/reader',
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200) {
        try {
          return LoginResponseModel.fromJson(response.data);
        } catch (e) {
          throw Exception('Lỗi xử lý dữ liệu đăng nhập');
        }
      } else {
        final message = response.data['message'] ?? 'Đăng nhập thất bại';
        throw Exception(message);
      }
    } on DioException catch (e) {
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
      throw Exception('Có lỗi xảy ra trong quá trình đăng nhập');
    }
  }

  @override
  Future<RegisterResponseModel> register(
    Map<String, dynamic> accountData,
  ) async {
    try {
      final response = await dio.post('/auth/register', data: accountData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final result = RegisterResponseModel.fromJson(response.data);

          if (result.data != null) {
          } else {}
          return result;
        } catch (e) {
          throw Exception('Lỗi xử lý dữ liệu đăng ký từ server: $e');
        }
      } else {
        final message = response.data['message'] ?? 'Đăng ký thất bại';

        throw Exception(message);
      }
    } on DioException catch (e) {
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
      throw Exception('Có lỗi xảy ra trong quá trình đăng ký');
    }
  }

  @override
  Future<LoginResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw Exception('Không thể làm mới token');
      }
    } on DioException catch (e) {
      throw Exception('Lỗi làm mới token: ${e.message}');
    }
  }

  @override
  Future<void> logout(String accessToken) async {
    try {
      await dio.post(
        '/auth/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw Exception('Lỗi đăng xuất: ${e.message}');
    }
  }

  @override
  Future<ReaderModel> getProfile(String accessToken) async {
    try {
      final response = await dio.get(
        '/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData == null) {
          throw Exception('Response data là null');
        }

        // Kiểm tra success flag (nếu có)
        if (responseData is Map<String, dynamic> &&
            responseData['success'] == false) {
          throw Exception(
            'API trả về success: false - ${responseData['message'] ?? 'Unknown error'}',
          );
        }

        // Tìm user data trong các cấu trúc khác nhau
        Map<String, dynamic>? userData;

        if (responseData is Map<String, dynamic>) {
          if (responseData['user'] != null) {
            userData = responseData['user'];
          } else if (responseData['data'] != null) {
            userData = responseData['data'];
          } else if (responseData['account'] != null) {
            userData = responseData['account'];
          } else if (responseData.containsKey('email')) {
            // Nếu responseData chính là user data
            userData = responseData;
          }
        }

        if (userData == null) {
          if (responseData is Map<String, dynamic>) {}
          throw Exception(
            'Dữ liệu user không tồn tại trong response. Response type: ${responseData.runtimeType}',
          );
        }

        // Tạo fallback data nếu thiếu thông tin cần thiết
        final fallbackUserData = {
          'accountId':
              userData['accountId']?.toString() ??
              userData['id']?.toString() ??
              'unknown',
          'email': userData['email']?.toString() ?? 'unknown@example.com',
          'roleName':
              userData['roleName']?.toString() ??
              userData['role']?.toString() ??
              'reader',
          'fullName':
              userData['fullName']?.toString() ??
              userData['name']?.toString() ??
              '',
          'phoneNumber':
              userData['phoneNumber']?.toString() ??
              userData['phone']?.toString() ??
              '',
          'address': userData['address']?.toString() ?? '',
          'dateOfBirth':
              userData['dateOfBirth']?.toString() ??
              userData['birthday']?.toString() ??
              '',
          'cccd': userData['cccd']?.toString() ?? '',
          'totolBorrow': userData['totolBorrow'] is int
              ? userData['totolBorrow']
              : int.tryParse(userData['totolBorrow']?.toString() ?? '0') ?? 0,
        };

        try {
          return ReaderModel.fromJson(fallbackUserData);
        } catch (parseError) {
          throw Exception('Lỗi xử lý dữ liệu profile: $parseError');
        }
      } else {
        if (response.statusCode == 401) {
          throw Exception(
            'Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
          );
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
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Kết nối tới server quá lâu. Vui lòng kiểm tra mạng và thử lại.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception(
          'Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
        );
      } else if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy thông tin profile.');
      } else {
        throw Exception('Lỗi lấy thông tin profile: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi không xác định khi lấy thông tin profile: $e');
    }
  }

  @override
  Future<ReaderModel> updateProfile(
    String accessToken,
    Map<String, dynamic> profileData,
  ) async {
    try {
      // Chuẩn hóa dateOfBirth => YYYY-MM-DD
      final data = Map<String, dynamic>.from(profileData);
      final dob = data['dateOfBirth'];
      if (dob is DateTime) {
        data['dateOfBirth'] = dob.toIso8601String().split('T').first;
      } else if (dob is String && dob.contains('T')) {
        data['dateOfBirth'] = dob.split('T').first;
      }

      final response = await dio.put(
        '/profile/me',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await getProfile(accessToken);
      } else {
        final errorMessage = response.data is Map<String, dynamic>
            ? response.data['message'] ?? 'Unknown error'
            : 'HTTP ${response.statusCode}';
        throw Exception('Không thể cập nhật thông tin profile: $errorMessage');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final resp = e.response?.data;
      print('❌ Dio updateProfile error: status=$status data=$resp');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Kết nối tới server quá lâu. Vui lòng kiểm tra mạng và thử lại.',
        );
      } else if (status == 401) {
        throw Exception(
          'Token không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
        );
      } else if (status == 400) {
        final msg = resp is Map<String, dynamic>
            ? resp['message'] ?? 'Dữ liệu không hợp lệ'
            : 'Dữ liệu không hợp lệ';
        throw Exception('Dữ liệu không hợp lệ: $msg');
      } else if (status == 404) {
        final msg = resp is Map<String, dynamic> ? resp['message'] : '$resp';
        throw Exception('Không tìm thấy route cập nhật: $msg');
      } else {
        throw Exception('Lỗi cập nhật thông tin profile: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi không xác định khi cập nhật profile: $e');
    }
  }
}
