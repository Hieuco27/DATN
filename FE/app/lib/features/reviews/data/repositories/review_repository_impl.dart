import 'package:book_tech/features/reviews/data/datasources/review_remote_data_source.dart';
import 'package:book_tech/features/reviews/domain/entities/review_entity.dart';
import 'package:book_tech/features/reviews/domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getReviews({
    required int documentId,
    required String accessToken,
    int page = 1,
    int limit = 10,
  }) async {
    return await remoteDataSource.getReviews(
      documentId: documentId,
      accessToken: accessToken,
    );
  }

  @override
  Future<ReviewStats> getReviewStats({
    required int documentId,
    required String accessToken,
  }) async {
    return await remoteDataSource.getReviewStats(
      documentId: documentId,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> createReview({
    required int documentId,
    required int rating,
    String? comment,
    required String accessToken,
  }) async {
    await remoteDataSource.createReview(
      documentId: documentId,
      rating: rating,
      comment: comment,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> updateReview({
    required int reviewId,
    required int rating,
    String? comment,
    required String accessToken,
  }) async {
    await remoteDataSource.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> deleteReview({
    required int reviewId,
    required String accessToken,
  }) async {
    await remoteDataSource.deleteReview(
      reviewId: reviewId,
      accessToken: accessToken,
    );
  }
}
