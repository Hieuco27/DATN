import 'package:dio/dio.dart';
import '../models/member_card_model.dart';

abstract class MembershipRemoteDataSource {
  // Lấy danh sách các loại thẻ thành viên
  Future<List<CardTypeModel>> getCardTypes(String accessToken);

  // Tạo thẻ thành viên mới (sau khi thanh toán)
  Future<MemberCardModel> createMemberCard(
    String accessToken,
    int cardTypeId,
    Map<String, dynamic> paymentData,
  );

  // Xử lý thanh toán (có thể tích hợp VNPay, MoMo, etc.)
  Future<Map<String, dynamic>> processPayment(
    String accessToken,
    int cardTypeId,
    String paymentMethod,
  );
  
  // Nạp tiền vào thẻ thành viên
  Future<Map<String, dynamic>> createMemberCardTopup(
    String accessToken,
    int memberCardId,
    int readerId,
  );
  
  // Lấy thông tin thẻ thành viên
  Future<Map<String, dynamic>> getMemberCard(
    String accessToken,
    int memberCardId,
  );
}

class MembershipRemoteDataSourceImpl implements MembershipRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com/api';
  static const Duration timeoutDuration = Duration(seconds: 60);

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
  Future<List<CardTypeModel>> getCardTypes(String accessToken) async {
    try {
      final response = await dio.get(
        '/membership/card-types',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => CardTypeModel.fromJson(json)).toList();
      } else {
        throw Exception(
          response.data['message'] ?? 'Không thể lấy danh sách loại thẻ',
        );
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
              e.response?.data?['message'] ?? 'Lỗi khi lấy danh sách loại thẻ';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra: ${e.toString()}');
    }
  }

  @override
  Future<MemberCardModel> createMemberCard(
    String accessToken,
    int cardTypeId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await dio.post(
        '/membership/member-cards',
        data: {'cardTypeId': cardTypeId, ...paymentData},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data =
            response.data['data'] ??
            response.data['memberCard'] ??
            response.data;
        return MemberCardModel.fromJson(data);
      } else {
        throw Exception(
          response.data['message'] ?? 'Không thể tạo thẻ thành viên',
        );
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
              e.response?.data?['message'] ?? 'Lỗi khi tạo thẻ thành viên';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> processPayment(
    String accessToken,
    int cardTypeId,
    String paymentMethod,
  ) async {
    try {
      // API này sẽ tạo payment link (VNPay, MoMo, etc.) hoặc xử lý thanh toán trực tiếp
      final response = await dio.post(
        '/membership/payment',
        data: {
          'cardTypeId': cardTypeId,
          'paymentMethod': paymentMethod, // 'VNPAY', 'MOMO', 'CASH', etc.
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(
          response.data['message'] ?? 'Không thể xử lý thanh toán',
        );
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
              e.response?.data?['message'] ?? 'Lỗi khi xử lý thanh toán';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> createMemberCardTopup(
    String accessToken,
    int memberCardId,
    int readerId,
  ) async {
    try {
      final response = await dio.post(
        '/member-cards/topup',
        data: {
          'memberCardId': memberCardId,
          'readerId': readerId,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          response.data['message'] ?? 'Không thể tạo thanh toán nạp thẻ',
        );
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
              e.response?.data?['message'] ?? 'Lỗi khi tạo thanh toán nạp thẻ';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getMemberCard(
    String accessToken,
    int memberCardId,
  ) async {
    try {
      final response = await dio.get(
        '/member-cards/$memberCardId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          response.data['message'] ?? 'Không thể lấy thông tin thẻ',
        );
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
              e.response?.data?['message'] ?? 'Lỗi khi lấy thông tin thẻ';
          throw Exception(message);
        default:
          throw Exception(
            'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
          );
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra: ${e.toString()}');
    }
  }
}
