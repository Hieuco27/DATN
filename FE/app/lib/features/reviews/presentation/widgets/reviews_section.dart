import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/reviews/presentation/bloc/review_bloc.dart';
import 'package:book_tech/features/reviews/domain/entities/review_entity.dart';
import 'package:book_tech/core/ui/notification_service.dart';

// Helper function để format ngày tháng
String _formatDate(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  
  // Nếu trong vòng 1 phút
  if (difference.inMinutes < 1) {
    return 'Vừa xong';
  }
  // Nếu trong vòng 1 giờ
  else if (difference.inHours < 1) {
    return '${difference.inMinutes} phút trước';
  }
  // Nếu trong vòng 24 giờ
  else if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  }
  // Nếu trong vòng 7 ngày
  else if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  }
  // Nếu cùng năm
  else if (dateTime.year == now.year) {
    final months = ['Thg 1', 'Thg 2', 'Thg 3', 'Thg 4', 'Thg 5', 'Thg 6',
                    'Thg 7', 'Thg 8', 'Thg 9', 'Thg 10', 'Thg 11', 'Thg 12'];
    return '${dateTime.day} ${months[dateTime.month - 1]}';
  }
  // Khác năm
  else {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class ReviewsSection extends StatelessWidget {
  final int documentId;
  final String accessToken;
  final int? currentUserId; // To identify own reviews

  const ReviewsSection({
    super.key,
    required this.documentId,
    required this.accessToken,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReviewBloc(
        repository: context.read(), // Should be injected or provided
      )..add(LoadReviews(documentId: documentId, accessToken: accessToken)),
      child: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewError) {
            NotificationService.showInfo(context, message: state.message);
          } else if (state is ReviewActionSuccess) {
            NotificationService.showSuccess(context, message: state.message);
          }
        },
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReviewLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReviewLoaded state) {
    
    Review? userReview;
    if (currentUserId != null) {
      try {
        userReview = state.reviews.firstWhere((r) => r.readerId == currentUserId);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state.stats),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 16),
          if (state.reviews.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Chưa có đánh giá nào.\nHãy là người đầu tiên đánh giá!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final review = state.reviews[index];
                final isOwnReview = review.readerId == currentUserId;
                return _ReviewItem(
                  review: review,
                  isOwnReview: isOwnReview,
                  onEdit: () => _showReviewDialog(context, review: review),
                  onDelete: () => _confirmDelete(context, review),
                );
              },
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReviewDialog(context, review: userReview),
                  icon: Icon(userReview == null ? Icons.rate_review_outlined : Icons.edit_outlined, size: 14),
                  label: Text(
                    userReview == null ? 'Viết đánh giá' : 'Chỉnh sửa đánh giá của bạn',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A202C),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReviewStats stats) {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Đánh giá & Bình luận',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A202C),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                const SizedBox(width: 4),
                Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A202C),
                  ),
                ),
                Text(
                  ' (${stats.totalReviews})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
  }

  void _showReviewDialog(BuildContext parentContext, {Review? review}) {
    showDialog(
      context: parentContext,
      builder: (context) => BlocProvider.value(
        value: parentContext.read<ReviewBloc>(),
        child: _ReviewDialog(
          documentId: documentId,
          accessToken: accessToken,
          initialReview: review,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa đánh giá?'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<ReviewBloc>().add(
                DeleteReview(
                  reviewId: review.reviewId,
                  documentId: documentId,
                  accessToken: accessToken,
                ),
              );
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  final bool isOwnReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReviewItem({
    required this.review,
    this.isOwnReview = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: review.readerAvatar != null 
                ? NetworkImage(review.readerAvatar!) 
                : null,
              child: review.readerAvatar == null 
                ? Text(
                    review.readerName.isNotEmpty ? review.readerName[0].toUpperCase() : '?',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                  )
                : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.readerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                  if (review.createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review.createdAt!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isOwnReview) 
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                ],
              ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final int documentId;
  final String accessToken;
  final Review? initialReview;

  const _ReviewDialog({
    required this.documentId,
    required this.accessToken,
    this.initialReview,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialReview?.rating ?? 5;
    _commentController = TextEditingController(text: widget.initialReview?.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        widget.initialReview == null ? 'Viết đánh giá' : 'Chỉnh sửa đánh giá',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 30,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm nghĩ của bạn về tài liệu này...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.initialReview == null) {
              context.read<ReviewBloc>().add(
                AddReview(
                  documentId: widget.documentId,
                  rating: _rating,
                  comment: _commentController.text,
                  accessToken: widget.accessToken,
                ),
              );
            } else {
              context.read<ReviewBloc>().add(
                UpdateReview(
                  reviewId: widget.initialReview!.reviewId,
                  documentId: widget.documentId,
                  rating: _rating,
                  comment: _commentController.text,
                  accessToken: widget.accessToken,
                ),
              );
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(widget.initialReview == null ? 'Đánh giá' : 'Chỉnh sửa'),
        ),
      ],
    );
  }
}
