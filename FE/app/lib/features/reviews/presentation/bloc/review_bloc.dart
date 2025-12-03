import 'package:bloc/bloc.dart';
import 'package:book_tech/features/reviews/domain/entities/review_entity.dart';
import 'package:book_tech/features/reviews/domain/repositories/review_repository.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();
  @override
  List<Object?> get props => [];
}

class LoadReviews extends ReviewEvent {
  final int documentId;
  final String accessToken;
  const LoadReviews({required this.documentId, required this.accessToken});
  @override
  List<Object?> get props => [documentId, accessToken];
}

class AddReview extends ReviewEvent {
  final int documentId;
  final int rating;
  final String? comment;
  final String accessToken;
  const AddReview({required this.documentId, required this.rating, this.comment, required this.accessToken});
  @override
  List<Object?> get props => [documentId, rating, comment, accessToken];
}

class UpdateReview extends ReviewEvent {
  final int reviewId;
  final int documentId; // Needed to reload
  final int rating;
  final String? comment;
  final String accessToken;
  const UpdateReview({required this.reviewId, required this.documentId, required this.rating, this.comment, required this.accessToken});
  @override
  List<Object?> get props => [reviewId, documentId, rating, comment, accessToken];
}

class DeleteReview extends ReviewEvent {
  final int reviewId;
  final int documentId; // Needed to reload
  final String accessToken;
  const DeleteReview({required this.reviewId, required this.documentId, required this.accessToken});
  @override
  List<Object?> get props => [reviewId, documentId, accessToken];
}

// States
abstract class ReviewState extends Equatable {
  const ReviewState();
  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewLoaded extends ReviewState {
  final List<Review> reviews;
  final ReviewStats stats;
  final int? userReviewId; // Track if user already reviewed to show Edit/Delete

  const ReviewLoaded({
    required this.reviews, 
    required this.stats,
    this.userReviewId,
  });
  
  @override
  List<Object?> get props => [reviews, stats, userReviewId];
}

class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
  @override
  List<Object?> get props => [message];
}

class ReviewActionSuccess extends ReviewState {
  final String message;
  const ReviewActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewRepository repository;

  ReviewBloc({required this.repository}) : super(ReviewInitial()) {
    on<LoadReviews>(_onLoadReviews);
    on<AddReview>(_onAddReview);
    on<UpdateReview>(_onUpdateReview);
    on<DeleteReview>(_onDeleteReview);
  }

  Future<void> _onLoadReviews(LoadReviews event, Emitter<ReviewState> emit) async {
    emit(ReviewLoading());
    try {
      final result = await repository.getReviews(
        documentId: event.documentId,
        accessToken: event.accessToken,
      );
      
      final reviews = result['reviews'] as List<Review>;
      final stats = result['stats'] as ReviewStats;
      
      // Logic to find if current user reviewed could be done here if we had current userId
      // For now, we rely on the list.
      
      emit(ReviewLoaded(reviews: reviews, stats: stats));
    } catch (e) {
      emit(ReviewError(e.toString()));
    }
  }

  Future<void> _onAddReview(AddReview event, Emitter<ReviewState> emit) async {
    // Keep current state to restore if needed or show loading overlay
    try {
      await repository.createReview(
        documentId: event.documentId,
        rating: event.rating,
        comment: event.comment,
        accessToken: event.accessToken,
      );
      emit(const ReviewActionSuccess("Đánh giá thành công"));
      add(LoadReviews(documentId: event.documentId, accessToken: event.accessToken));
    } catch (e) {
      emit(ReviewError(e.toString()));
      // Reload to show consistent state
      add(LoadReviews(documentId: event.documentId, accessToken: event.accessToken));
    }
  }

  Future<void> _onUpdateReview(UpdateReview event, Emitter<ReviewState> emit) async {
    try {
      await repository.updateReview(
        reviewId: event.reviewId,
        rating: event.rating,
        comment: event.comment,
        accessToken: event.accessToken,
      );
      emit(const ReviewActionSuccess("Cập nhật đánh giá thành công"));
      add(LoadReviews(documentId: event.documentId, accessToken: event.accessToken));
    } catch (e) {
      emit(ReviewError(e.toString()));
      add(LoadReviews(documentId: event.documentId, accessToken: event.accessToken));
    }
  }

  Future<void> _onDeleteReview(DeleteReview event, Emitter<ReviewState> emit) async {
    try {
      await repository.deleteReview(
        reviewId: event.reviewId,
        accessToken: event.accessToken,
      );
      emit(const ReviewActionSuccess("Xóa đánh giá thành công"));
      add(LoadReviews(documentId: event.documentId, accessToken: event.accessToken));
    } catch (e) {
      emit(ReviewError(e.toString()));
      add(LoadReviews(documentId: event.documentId, accessToken: event.accessToken));
    }
  }
}
