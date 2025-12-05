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
  Future<List<DocumentResponseModel>> getSimilarDocuments({
    required String accessToken,
    required int documentId,
    int page = 1,
    int limit = 10,
  });
  Future<Map<String, dynamic>> reserveBooks({
    required String accessToken,
    required List<Map<String, dynamic>> items,
  });
  Future<List<DocumentResponseModel>> getNewDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? documentType,
  });
  Future<List<DocumentResponseModel>> getMostBorrowedDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
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
        // Thêm log để debug
        if (responseData is Map<String, dynamic>) {
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
        for (var doc in documents) {
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
      throw Exception('Error fetching documents: $e');
    }
  }

  // danh sach the loai chi tiet
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

        for (var genre in genres) {
        }

        return genres.map((item) => GenreModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to load genres: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
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
          final document = DocumentDetailModel.fromJson(jsonData['data']);

          return document;
        } else {
          throw Exception(
            jsonData['message'] ?? 'Failed to fetch document detail',
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // tim kiem tai lieu
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

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData.containsKey('data')) {
            final List<dynamic> documents =
                responseData['data'] as List<dynamic>;

            if (documents.isEmpty) {
              if (responseData.containsKey('filter')) {}
              if (responseData.containsKey('pagination')) {}
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

            return result;
          } else {
            throw Exception(
              'Search API error: ${responseData['message'] ?? 'Unknown error'}',
            );
          }
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
          'Failed to search documents: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error searching documents: $e');
    }
  }

  // danh sach the loai chi tiet
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
          for (var doc in documents) {}
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

  // lay noi dung ebook
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
      throw Exception('Error fetching ebook: $e');
    }
  }

  // hien thi danh sach tai lieu tương tự
  @override
  Future<List<DocumentResponseModel>> getSimilarDocuments({
    required String accessToken,
    required int documentId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/api/documents/reader/$documentId/similar',
      ).replace(queryParameters: queryParams);

      print('🌐 Fetching similar documents from: $uri');

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

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true &&
              responseData.containsKey('data')) {
            final List<dynamic> documents =
                responseData['data'] as List<dynamic>;

            return documents
                .map((item) => DocumentResponseModel.fromJson(item))
                .toList();
          } else {
            throw Exception(
              'API returned error: ${responseData['message'] ?? 'Unknown error'}',
            );
          }
        } else if (responseData is List<dynamic>) {
          // Nếu response là array trực tiếp
          return responseData
              .map((item) => DocumentResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
          'Failed to load similar documents: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching similar documents: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> reserveBooks({
    required String accessToken,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/loans/reader/loans/reserve'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'items': items}),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        // Bad request - có thể là sách đã tồn tại trong phiếu mượn
        try {
          final responseData = json.decode(response.body) as Map<String, dynamic>;
          // Nếu parse được JSON và có field success, return response để xử lý ở UI
          if (responseData.containsKey('success')) {
            return responseData;
          }
          // Nếu không có field success, throw exception với message
          final errorMessage = responseData['message'] ?? 'Không thể đăng ký mượn sách';
          throw Exception(errorMessage);
        } catch (parseError) {
          if (parseError is Exception && parseError.toString().contains('Exception: ')) {
            rethrow;
          }
          final rawMessage = response.body.isNotEmpty 
            ? response.body 
            : 'Không thể đăng ký mượn sách (HTTP ${response.statusCode})';
          throw Exception(rawMessage);
        }
      } else {
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage = errorData['message'] ?? 'Không thể đăng ký mượn sách';
          throw Exception(errorMessage);
        } catch (parseError) {
          final rawMessage = response.body.isNotEmpty 
            ? response.body 
            : 'Không thể đăng ký mượn sách (HTTP ${response.statusCode})';
          throw Exception(rawMessage);
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Lỗi kết nối khi đăng ký mượn sách');
    }
  }

  // hien thi danh sach tai lieu moi nhat
  @override
  Future<List<DocumentResponseModel>> getNewDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? documentType,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (documentType != null && documentType.isNotEmpty) {
        queryParams['type'] = documentType;
      }
      final uri = Uri.parse(
        '$baseUrl/api/documents/reader/latest',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> documents;
        // Kiểm tra xem response có phải là Map không
        if (responseData is Map<String, dynamic>) {
          // Nếu là Map, tìm key chứa array documents
          if (responseData.containsKey('data')) {
            documents = responseData['data'] as List<dynamic>;
          } else {
            throw Exception(
              'Cannot find data array in response: ${responseData.keys}',
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
        // Convert từ List<dynamic> sang List<DocumentResponseModel>
        return documents
            .map((item) => DocumentResponseModel.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Failed to load new documents: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching new documents: $e');
    }
  }

  // hien thi danh sach tai lieu duoc muon nhieu nhat
  @override
  Future<List<DocumentResponseModel>> getMostBorrowedDocuments({
    required String accessToken,
    int page = 1,
    int limit = 20,
    String? documentType,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (documentType != null && documentType.isNotEmpty) {
        queryParams['type'] = documentType;
      }
      final uri = Uri.parse(
        '$baseUrl/api/documents/reader/popular',
      ).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        List<dynamic> documents;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            documents = responseData['data'] as List<dynamic>;
          } else {
            throw Exception(
              'Cannot find data array in response: ${responseData.keys}',
            );
          }
        } else if (responseData is List<dynamic>) {
          documents = responseData;
        } else {
          throw Exception(
            'Unexpected response format: ${responseData.runtimeType}',
          );
        }
        return documents
            .map((item) => DocumentResponseModel.fromJson(item))
            .toList();
      } else {
        throw Exception(
          'Failed to load most borrowed documents: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching most borrowed documents: $e');
    }
  }
}
