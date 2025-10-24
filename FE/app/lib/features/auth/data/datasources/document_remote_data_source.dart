// lib/features/auth/data/datasources/document_remote_data_source.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/document_response_model.dart';

abstract class DocumentRemoteDataSource {
  Future<List<DocumentResponseModel>> getDocumentsForReader({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  });
}

class DocumentRemoteDataSourceImpl implements DocumentRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com';

  @override
  Future<List<DocumentResponseModel>> getDocumentsForReader({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (categoryName != null && categoryName.isNotEmpty) {
        queryParams['categoryName'] = categoryName;
      }
      if (documentType != null && documentType.isNotEmpty) {
        queryParams['documentType'] = documentType;
      }

      final uri = Uri.parse(
        '$baseUrl/api/documents/reader',
      ).replace(queryParameters: queryParams);

      print('🌐 Fetching documents from: $uri');
      print('📋 Query params: $queryParams');
      print('📋 Document type filter: $documentType');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        // Thêm log để debug
        if (responseData is Map<String, dynamic>) {
          print('📊 Response structure: ${responseData.keys}');
          if (responseData.containsKey('filter')) {
            print('🔍 API Filter: ${responseData['filter']}');
          }
        }
        List<dynamic> documents;

        // Kiểm tra xem response có phải là Map không
        if (responseData is Map<String, dynamic>) {
          // Nếu là Map, tìm key chứa array documents
          if (responseData.containsKey('data')) {
            documents = responseData['data'] as List<dynamic>;
          } else if (responseData.containsKey('documents')) {
            documents = responseData['documents'] as List<dynamic>;
          } else if (responseData.containsKey('results')) {
            documents = responseData['results'] as List<dynamic>;
          } else {
            throw Exception(
              'Cannot find documents array in response: ${responseData.keys}',
            );
          }
        } else if (responseData is List<dynamic>) {
          // Nếu response là array trực tiếp
          documents = responseData;
        } else {
          throw Exception(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }
        // Thêm log để debug document types
        print('📚 Total documents returned: ${documents.length}');
        for (var doc in documents) {
          print('📄 Document: ${doc['title']} - Type: ${doc['documentType']}');
        }
        return documents
            .map((item) => DocumentResponseModel.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Failed to load documents: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching documents: $e');
      throw Exception('Error fetching documents: $e');
    }
  }
}
