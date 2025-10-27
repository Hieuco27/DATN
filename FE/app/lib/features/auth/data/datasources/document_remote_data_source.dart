// lib/features/auth/data/datasources/document_remote_data_source.dart
import 'dart:convert';
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/domain/entities/genre_entity.dart';
import 'package:http/http.dart' as http;
import '../models/document_response_model.dart';
import '../models/document_detail_model.dart';
import 'package:dio/dio.dart';

abstract class DocumentRemoteDataSource {
  Future<List<DocumentResponseModel>> getDocumentsForReader({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? categoryName,
    String? documentType,
  });
  Future<DocumentDetailModel> getDocumentDetail({
    required String accessToken,
    required int documentId,
  });

  Future<List<GenreModel>> getGenres({required String accessToken});

  Future<List<DocumentResponseModel>> searchDocuments({
    required String accessToken,
    required String query,
    required int page,
    required int limit,
  });
  // Thêm vào abstract class DocumentRemoteDataSource
  Future<List<DocumentResponseModel>> getDocumentsByGenre({
    required String accessToken,
    required List<int> genreIds,
    String? documentType,
    int page = 1,
    int limit = 20,
    String match = 'any', // 'any' hoặc 'all'
  });
  Future<String> getEbook({
    required String accessToken,
    required int documentId,
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

  @override
  Future<List<GenreModel>> getGenres({required String accessToken}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/documents/genres'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('📡 Genres response status: ${response.statusCode}');
      print('📡 Genres response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        List<dynamic> genres;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            genres = responseData['data'] as List<dynamic>;
          } else {
            throw Exception(
              'Cannot find genres data in response: ${responseData.keys}',
            );
          }
        } else if (responseData is List<dynamic>) {
          genres = responseData;
        } else {
          throw Exception(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }

        print('📚 Total genres returned: ${genres.length}');
        for (var genre in genres) {
          print('🎭 Genre: ${genre['name']} - ID: ${genre['genreId']}');
        }

        return genres.map((item) => GenreModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to load genres: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching genres: $e');
      throw Exception('Error fetching genres: $e');
    }
  }

  // Lay chi tiet tai lieu
  @override
  Future<DocumentDetailModel> getDocumentDetail({
    required String accessToken,
    required int documentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/documents/reader/$documentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return DocumentDetailModel.fromJson(jsonData['data']);
        } else {
          throw Exception(
            jsonData['message'] ?? 'Failed to fetch document detail',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in getDocumentDetail: $e');
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<List<DocumentResponseModel>> searchDocuments({
    required String accessToken,
    required String query,
    required int page,
    required int limit,
  }) async {
    try {
      // Encode query để xử lý ký tự đặc biệt
      final encodedQuery = Uri.encodeComponent(query);

      final Map<String, String> queryParams = {
        'q': encodedQuery,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/api/documents/reader/search',
      ).replace(queryParameters: queryParams);

      print('🔍 Searching documents: $uri');
      print('📋 Original query: "$query"');
      print('📋 Encoded query: "$encodedQuery"');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('📡 Search response status: ${response.statusCode}');
      print('📡 Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          print('📊 Response structure: ${responseData.keys}');
          print('📊 Success: ${responseData['success']}');
          print('📊 Message: ${responseData['message']}');
          print('📊 Data length: ${responseData['data']?.length ?? 0}');
          print('📊 Filter: ${responseData['filter']}');

          if (responseData['success'] == true &&
              responseData.containsKey('data')) {
            final List<dynamic> documents =
                responseData['data'] as List<dynamic>;

            print('📚 Search results: ${documents.length} documents found');

            if (documents.isEmpty) {
              print('⚠️ No documents found, checking filter info...');
              if (responseData.containsKey('filter')) {
                print('🔍 Filter info: ${responseData['filter']}');
              }
              if (responseData.containsKey('pagination')) {
                print('📄 Pagination info: ${responseData['pagination']}');
              }
            }
            // Parse documents thành DocumentResponseModel
            final List<DocumentResponseModel> result = documents
                .map((item) {
                  try {
                    return DocumentResponseModel.fromJson(item);
                  } catch (e) {
                    return null;
                  }
                })
                .where((item) => item != null)
                .cast<DocumentResponseModel>()
                .toList();

            print('✅ Successfully parsed ${result.length} documents');
            return result;
          } else {
            throw Exception(
              'Search API error: ${responseData['message'] ?? 'Unknown error'}',
            );
          }
        } else {
          print('❌ Response is not a Map: ${responseData.runtimeType}');
          throw Exception('Unexpected response format');
        }
      } else {
        print('❌ Search failed with status: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
        throw Exception(
          'Failed to search documents: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error searching documents: $e');
      throw Exception('Error searching documents: $e');
    }
  }

  // Thêm implementation vào DocumentRemoteDataSourceImpl
  @override
  Future<List<DocumentResponseModel>> getDocumentsByGenre({
    required String accessToken,
    required List<int> genreIds,
    String? documentType,
    int page = 1,
    int limit = 20,
    String match = 'any',
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'match': match,
      };

      // Thêm genreIds
      if (genreIds.isNotEmpty) {
        queryParams['genreIds'] = genreIds.join(',');
      }

      if (documentType != null && documentType.isNotEmpty) {
        queryParams['type'] = documentType;
      }

      final uri = Uri.parse(
        '$baseUrl/api/documents/reader/by-genre',
      ).replace(queryParameters: queryParams);

      print('🌐 Fetching documents by genre from: $uri');
      print('📋 Query params: $queryParams');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true) {
          final List<dynamic> documents = responseData['data'] as List<dynamic>;

          print('📚 Total documents returned: ${documents.length}');
          for (var doc in documents) {
            print(
              '📄 Document: ${doc['title']} - Genre: ${doc['categoryName']}',
            );
          }
          return documents
              .map((item) => DocumentResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception(
            'API returned error: ${responseData['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception(
          'Failed to load documents by genre: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching documents by genre: $e');
    }
  }

  // Thêm implementation vào DocumentRemoteDataSourceImpl
  @override
  Future<String> getEbook({
    required String accessToken,
    required int documentId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/documents/ebook/$documentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      print('📖 Ebook response status: ${response.statusCode}');
      print('📖 Ebook response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData.containsKey('data')) {
            return responseData['data']['content'] ??
                responseData['data']['text'] ??
                '';
          } else {
            throw Exception(
              'API returned error: ${responseData['message'] ?? 'Unknown error'}',
            );
          }
        } else if (responseData is String) {
          return responseData;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
          'Failed to load ebook: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error fetching ebook: $e');
      throw Exception('Error fetching ebook: $e');
    }
  }
}
