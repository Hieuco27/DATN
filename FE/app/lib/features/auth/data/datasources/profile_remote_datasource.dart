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
    final res = await _client.get(
      Uri.parse('https://kltn-2025-ehsx.onrender.com/api/profile/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      print('🔍 Parsed Data: $data');

      Map<String, dynamic> profileData;

      if (data is Map<String, dynamic>) {
        if (data['reader'] != null) {
          profileData = data['reader'];
        } else if (data['profile'] != null) {
          profileData = data['profile'];
        } else if (data['data'] != null) {
          profileData = data['data'];
        } else {
          profileData = data;
        }
      } else {
        throw Exception('Invalid response format');
      }

      return ReaderModel.fromJson(profileData); // ✅ Return thay vì throw
    }

    throw Exception('Lỗi lấy profile: HTTP ${res.statusCode}');
  }

  @override
  Future<ReaderEntity> updateProfile(
    String accessToken,
    ReaderEntity reader,
  ) async {
    final body = <String, dynamic>{};

    if (reader.fullName != null) body['fullName'] = reader.fullName;
    if (reader.phoneNumber != null) body['phoneNumber'] = reader.phoneNumber;
    if (reader.address != null) body['address'] = reader.address;
    if (reader.gender != null) body['gender'] = reader.gender;
    if (reader.dateOfBirth != null) {
      body['dateOfBirth'] = reader.dateOfBirth!
          .toIso8601String()
          .split('T')
          .first;
    }
    if (reader.cccd != null) body['cccd'] = reader.cccd;
    if (reader.note != null) body['note'] = reader.note;

    final url = Uri.parse('$_baseUrl/profile/me');
    print('🔧 Updating profile via PUT: $url with body=$body');

    final res = await _client.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode(body),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      final map =
          data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : (data as Map<String, dynamic>);
      return ReaderModel.fromJson(map);
    }
    print('❌ PUT $url -> ${res.statusCode} body=${res.body}');
    throw Exception('Lỗi cập nhật profile: HTTP ${res.statusCode}');
  }
}
