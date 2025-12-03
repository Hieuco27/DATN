import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:book_tech/features/reviews/data/models/review_model.dart';

abstract class ReviewRemoteDataSource {
  Future<Map<String, dynamic>> getReviews({
    required int documentId,
    required String accessToken,
  });
  Future<ReviewStatsModel> getReviewStats({
    required int documentId,
    required String accessToken,
  });
  Future<void> createReview({
    required int documentId,
    required int rating,
    String? comment,
    required String accessToken,
  });
  Future<void> updateReview({
    required int reviewId,
    required int rating,
    String? comment,
    required String accessToken,
  });
  Future<void> deleteReview({
    required int reviewId,
    required String accessToken,
  });
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  static const String baseUrl = 'https://kltn-2025-ehsx.onrender.com';
  final http.Client client;

  ReviewRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getReviews({
    required int documentId,
    required String accessToken,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/reviews/$documentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final reviewsData = data['data']['reviews'] as List;
        final statsData = data['data']['stats'];
        
        return {
          'reviews': reviewsData.map((e) => ReviewModel.fromJson(e)).toList(),
          'stats': ReviewStatsModel.fromJson(statsData),
        };
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  @override
  Future<ReviewStatsModel> getReviewStats({
    required int documentId,
    required String accessToken,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/reviews/$documentId/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return ReviewStatsModel.fromJson(data['data']);
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load stats');
    }
  }

  @override
  Future<void> createReview({
    required int documentId,
    required int rating,
    String? comment,
    required String accessToken,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'documentId': documentId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to create review');
    }
  }

  @override
  Future<void> updateReview({
    required int reviewId,
    required int rating,
    String? comment,
    required String accessToken,
  }) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/api/reviews/$reviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to update review');
    }
  }

  @override
  Future<void> deleteReview({
    required int reviewId,
    required String accessToken,
  }) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/reviews/$reviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete review');
    }
  }
}
