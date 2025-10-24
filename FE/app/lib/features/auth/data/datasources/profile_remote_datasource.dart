import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/entities/reader_entity.dart';
import '../models/reader_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ReaderEntity> getProfile(String accessToken);
  Future<ReaderEntity> updateProfile(String accessToken, ReaderEntity reader);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final http.Client _client;
  final String _baseUrl;

  ProfileRemoteDataSourceImpl({
    required http.Client client,
    required String baseUrl,
  }) : _client = client,
       _baseUrl = baseUrl;

  @override
  Future<ReaderEntity> getProfile(String accessToken) async {
    print('🔍 Calling API: $_baseUrl/auth/profile');

    final res = await _client.get(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    print('🔍 Response Status: ${res.statusCode}');
    print('🔍 Response Body: ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      print('🔍 Parsed Data: $data');

      // Sửa logic parse - lấy từ 'profile' thay vì 'data'
      Map<String, dynamic> profileData;

      if (data is Map<String, dynamic>) {
        if (data['profile'] != null) {
          profileData = data['profile'];
          print('🔍 Using profile data: $profileData');
        } else if (data['data'] != null) {
          profileData = data['data'];
          print('🔍 Using data field: $profileData');
        } else {
          profileData = data;
          print('🔍 Using root data: $profileData');
        }
      } else {
        throw Exception('Invalid response format');
      }
      print('🔍 Final Profile Data: $profileData');
      print('🔍 Profile Keys: ${profileData.keys.toList()}');

      return ReaderModel.fromJson(profileData);
    }
    throw Exception('Lỗi lấy profile: HTTP ${res.statusCode}');
  }

  @override
  Future<ReaderEntity> updateProfile(
    String accessToken,
    ReaderEntity reader,
  ) async {
    
    final res = await _client.put(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(reader.toJson()),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return ReaderModel.fromJson(
        data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
            ? data['data']
            : data,
      );
    }
    throw Exception('Lỗi cập nhật profile: HTTP ${res.statusCode}');
  }
}
