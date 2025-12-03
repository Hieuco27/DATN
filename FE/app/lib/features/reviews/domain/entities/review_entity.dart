import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final int reviewId;
  final int readerId;
  final int rating;
  final String comment;
  final String readerName;
  final String? readerAvatar; // Added just in case, though API didn't explicitly show it
  final DateTime? createdAt; // Optional

  const Review({
    required this.reviewId,
    required this.readerId,
    required this.rating,
    required this.comment,
    required this.readerName,
    this.readerAvatar,
    this.createdAt,
  });

  @override
  List<Object?> get props => [reviewId, readerId, rating, comment, readerName, readerAvatar, createdAt];
}

class ReviewStats extends Equatable {
  final double averageRating;
  final int totalReviews;

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  List<Object?> get props => [averageRating, totalReviews];
}
