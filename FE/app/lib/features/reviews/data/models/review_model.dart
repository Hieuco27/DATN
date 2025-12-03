import 'package:book_tech/features/reviews/domain/entities/review_entity.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.reviewId,
    required super.readerId,
    required super.rating,
    required super.comment,
    required super.readerName,
    super.readerAvatar,
    super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Backend trả về created_at (snake_case), hỗ trợ cả createdAt (camelCase)
    final createdAtStr = json['created_at'] ?? json['createdAt'];
    
    return ReviewModel(
      reviewId: json['reviewId'] as int,
      readerId: json['readerId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String? ?? '',
      readerName: json['Reader']?['fullName'] as String? ?? 'Người dùng',
      readerAvatar: json['Reader']?['avatarUrl'] as String?,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'readerId': readerId,
      'rating': rating,
      'comment': comment,
      'Reader': {
        'fullName': readerName,
        'avatarUrl': readerAvatar,
      },
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class ReviewStatsModel extends ReviewStats {
  const ReviewStatsModel({
    required super.averageRating,
    required super.totalReviews,
  });

  factory ReviewStatsModel.fromJson(Map<String, dynamic> json) {
    return ReviewStatsModel(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
    );
  }
}
