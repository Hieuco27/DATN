import 'package:book_tech/features/reviews/domain/entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Map<String, dynamic>> getReviews({
    required int documentId, 
    required String accessToken,
    int page = 1,
    int limit = 10,
  });

  Future<ReviewStats> getReviewStats({
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
