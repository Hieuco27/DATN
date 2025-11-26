import 'package:dio/dio.dart';
import '../models/login_response_model.dart';
import '../models/register_response_model.dart';
import '../models/reader_model.dart';

abstract class AuthenticationRemoteDataSource {
  Future<LoginResponseModel> login(String email, String password);
  Future<RegisterResponseModel> register(Map<String, dynamic> accountData);

  // New 3-step registration flow
  Future<Map<String, dynamic>> registerInit(String email);
  Future<Map<String, dynamic>> registerVerify(Map<String, dynamic> verifyData);
  Future<Map<String, dynamic>> registerComplete(
    Map<String, dynamic> completeData,
  );
  Future<Map<String, dynamic>> checkPaymentStatus(String accessToken);

  Future<LoginResponseModel> refreshToken(String refreshToken);
  Future<void> logout(String accessToken);
  Future<ReaderModel> getProfile(String accessToken);
  Future<ReaderModel> updateProfile(
    String accessToken,
    Map<String, dynamic> profileData,
  );
  
  // FCM Token Registration
  Future<void> registerFcmToken(String accessToken, String fcmToken);
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 30); // Giảm timeout xuống 30s

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
  Future<Map<String, dynamic>> registerInit(String email) async {
    final startTime = DateTime.now();
    print('🔵 [OTP] Bắt đầu gửi OTP đến: $email');
    
    try {
      final response = await dio.post(
        '/auth/register/init',
        data: {'email': email.trim()},
      );
      
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('✅ [OTP] Phản hồi từ server sau ${elapsed}ms');
      print('📊 [OTP] Status code: ${response.statusCode}');
      print('📊 [OTP] Response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [OTP] Gửi OTP thành công!');
        return response.data as Map<String, dynamic>;
      } else {
        final message = response.data['message'] ?? 'Không thể gửi mã OTP';
        print('❌ [OTP] Thất bại: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('❌ [OTP] Lỗi sau ${elapsed}ms - Type: ${e.type}');
      print('❌ [OTP] Error message: ${e.message}');
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          print('⏱️ [OTP] Timeout - Server phản hồi chậm');
          throw Exception(
            'Server phản hồi chậm. Vui lòng kiểm tra kết nối mạng và thử lại.',
          );
        case DioExceptionType.badResponse:
          final message =
              e.response?.data?['message'] ?? 'Không thể gửi mã OTP';
          print('🚨 [OTP] Bad response: $message');
          throw Exception(message);
        case DioExceptionType.connectionError:
          print('🚫 [OTP] Lỗi kết nối mạng');
          throw Exception(
            'Không thể kết nối đến server. Kiểm tra kết nối internet.',
          );
        default:
          print('❓ [OTP] Lỗi không xác định: ${e.type}');
          throw Exception(
            'Không thể kết nối đến server. Vui lòng thử lại.',
          );
      }
    } catch (e) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      print('🔴 [OTP] Exception sau ${elapsed}ms: ${e.toString()}');
      throw Exception('Có lỗi xảy ra khi gửi mã OTP: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> registerVerify(
    Map<String, dynamic> verifyData,
  ) async {
    try {
      final response = await dio.post(
        '/auth/register/verify',
        data: verifyData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        final message = response.data['message'] ?? 'Xác thực OTP thất bại';
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
          final message =
              e.response?.data?['message'] ?? 'Xác thực OTP thất bại';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra khi xác thực OTP: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> checkPaymentStatus(String accessToken) async {
    try {
      print('📤 Checking if MemberCard has been created via profile...');
      final profile = await getProfile(accessToken);
      
      // Check if memberCard exists in profile
      final hasMemberCard = profile.memberCard != null;
      print('📥 Profile checked - Has MemberCard: $hasMemberCard');
      
      return {
        'paid': hasMemberCard,
        'status': hasMemberCard ? 'PAID' : 'PENDING',
        'profile': profile.toJson(),
      };
    } catch (e) {
      print('⚠️ Error checking profile: $e');
      return {
        'paid': false,
        'status': 'PENDING',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> registerComplete(
    Map<String, dynamic> completeData,
  ) async {
    try {
      print('📤 Sending registerComplete request: $completeData');
      final response = await dio.post(
        '/auth/register/complete',
        data: completeData,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');
      print('📥 Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Kiểm tra xem response có được wrap trong 'data' không
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          // Nếu có 'data' wrapper, lấy data bên trong
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      } else {
        final message = response.data['message'] ?? 'Hoàn tất đăng ký thất bại';
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
          final message =
              e.response?.data?['message'] ?? 'Hoàn tất đăng ký thất bại';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra khi hoàn tất đăng ký: ${e.toString()}');
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
        '/profile/me',
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

        // Chuẩn hoá dữ liệu theo dạng mà ReaderModel.fromJson mong đợi
        // Ưu tiên các khoá thông dụng: reader -> profile -> data -> chính response
        Map<String, dynamic>? profileData;
        if (responseData is Map<String, dynamic>) {
          if (responseData['reader'] is Map<String, dynamic>) {
            profileData = Map<String, dynamic>.from(responseData['reader']);
          } else if (responseData['profile'] is Map<String, dynamic>) {
            profileData = Map<String, dynamic>.from(responseData['profile']);
          } else if (responseData['data'] is Map<String, dynamic>) {
            profileData = Map<String, dynamic>.from(responseData['data']);
          } else {
            profileData = Map<String, dynamic>.from(responseData);
          }
        }

        if (profileData == null) {
          throw Exception(
            'Dữ liệu profile không tồn tại trong response. Response type: ${responseData.runtimeType}',
          );
        }

        // Đảm bảo có cấu trúc account lồng nếu backend trả email/phone ở cấp cao hơn
        final hasAccount = profileData['account'] is Map<String, dynamic>;
        if (!hasAccount) {
          final inferredAccount = <String, dynamic>{};
          // Lấy từ response cấp trên nếu có
          if (responseData is Map<String, dynamic>) {
            final topAccount = responseData['account'];
            if (topAccount is Map<String, dynamic>) {
              inferredAccount.addAll(topAccount);
            }
          }
          // Fallback: lấy ngay trên profileData nếu tồn tại
          if (profileData.containsKey('email')) {
            inferredAccount['email'] = profileData['email'];
          }
          if (profileData.containsKey('phoneNumber')) {
            inferredAccount['phoneNumber'] = profileData['phoneNumber'];
          }
          if (inferredAccount.isNotEmpty) {
            profileData['account'] = inferredAccount;
          }
        }

        try {
          return ReaderModel.fromJson(profileData);
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

  @override
  Future<void> registerFcmToken(String accessToken, String fcmToken) async {
    try {
      print('📤 [AuthRemoteDataSource] Registering FCM Token...');
      final response = await dio.post(
        '/fcm/register',
        data: {'fcmToken': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        print('✅ [AuthRemoteDataSource] FCM Token registered successfully');
      } else {
        print('⚠️ [AuthRemoteDataSource] Failed to register FCM Token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [AuthRemoteDataSource] Error registering FCM Token: ${e.message}');
      // Không throw exception vì FCM token registration không nên làm gián đoạn flow chính
    } catch (e) {
      print('❌ [AuthRemoteDataSource] Unexpected error registering FCM Token: $e');
    }
  }
}
