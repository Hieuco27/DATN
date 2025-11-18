import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/data/repositories/notification_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/notification_remote_data_source.dart';
import 'package:book_tech/features/auth/data/models/notification_model.dart';
import 'package:book_tech/core/ui/notification_service.dart';

class NotificationDetailPage extends StatefulWidget {
  final int notificationId;

  const NotificationDetailPage({Key? key, required this.notificationId})
    : super(key: key);

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  final NotificationRepositoryImpl _repository = NotificationRepositoryImpl(
    remoteDataSource: NotificationRemoteDataSourceImpl(),
  );

  NotificationModel? _notification;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationDetail();
  }

  Future<void> _loadNotificationDetail() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        throw Exception('User not authenticated');
      }

      final response = await _repository.getNotificationDetail(
        accessToken: authState.account.accessToken!,
        notificationId: widget.notificationId,
      );

      if (mounted) {
        setState(() {
          _notification = response.data;
          _isLoading = false;
        });

        // Auto mark as read if not read
        if (!_notification!.isRead) {
          await _markAsRead();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        NotificationService.showError(
          context,
          message: 'Lỗi tải thông báo: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _markAsRead() async {
    if (_notification?.isRead == true) return;

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        return;
      }

      await _repository.markAsRead(
        accessToken: authState.account.accessToken!,
        notificationId: widget.notificationId,
      );

      if (mounted) {
        setState(() {
          _notification = _notification!.copyWith(isRead: true);
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _markAsUnread() async {
    if (_notification?.isRead != true) return;

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        return;
      }

      await _repository.markAsUnread(
        accessToken: authState.account.accessToken!,
        notificationId: widget.notificationId,
      );

      if (mounted) {
        setState(() {
          _notification = _notification!.copyWith(isRead: false);
        });
        NotificationService.showSuccess(
          context,
          message: 'Đã đánh dấu là chưa đọc',
        );
      }
    } catch (e) {
      NotificationService.showError(context, message: 'Lỗi: ${e.toString()}');
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'SYSTEM':
        return 'Hệ thống';
      case 'LOAN_PENDING':
        return 'Chờ duyệt';
      case 'LOAN_APPROVED':
        return 'Đã duyệt';
      case 'LOAN_REJECTED':
        return 'Từ chối';
      case 'LOAN_READY':
        return 'Sẵn sàng';
      case 'LOAN_DUE_SOON':
        return 'Sắp đến hạn';
      case 'LOAN_OVERDUE':
        return 'Quá hạn';
      case 'PAYMENT_SUCCESS':
        return 'Thanh toán';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'LOAN_APPROVED':
      case 'PAYMENT_SUCCESS':
        return Colors.green;
      case 'LOAN_REJECTED':
      case 'LOAN_OVERDUE':
        return Colors.red;
      case 'LOAN_PENDING':
      case 'LOAN_DUE_SOON':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'SYSTEM':
        return Icons.info_outline;
      case 'LOAN_PENDING':
        return Icons.access_time;
      case 'LOAN_APPROVED':
        return Icons.check_circle_outline;
      case 'LOAN_REJECTED':
        return Icons.cancel_outlined;
      case 'LOAN_READY':
        return Icons.done_all;
      case 'LOAN_DUE_SOON':
        return Icons.schedule;
      case 'LOAN_OVERDUE':
        return Icons.warning_amber;
      case 'PAYMENT_SUCCESS':
        return Icons.payment;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Chi tiết thông báo',
          style: TextStyle(
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A202C)),
        actions: [
          if (_notification != null)
            IconButton(
              icon: Icon(
                _notification!.isRead
                    ? Icons.mark_email_unread
                    : Icons.mark_email_read,
              ),
              onPressed: _notification!.isRead ? _markAsUnread : null,
              tooltip: 'Đánh dấu chưa đọc',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notification == null
          ? const Center(child: Text('Không tìm thấy thông báo'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getTypeColor(
                                _notification!.type,
                              ).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIcon(_notification!.type),
                              color: _getTypeColor(_notification!.type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _notification!.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(
                                      _notification!.type,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getTypeLabel(_notification!.type),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getTypeColor(_notification!.type),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      // Content
                      Text(
                        _notification!.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Metadata
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildMetadataRow(
                              'Thời gian',
                              _formatDateTime(_notification!.createdAt),
                            ),
                            if (_notification!.readAt != null) ...[
                              const SizedBox(height: 8),
                              _buildMetadataRow(
                                'Đã đọc lúc',
                                _formatDateTime(_notification!.readAt!),
                              ),
                            ],
                            const SizedBox(height: 8),
                            _buildMetadataRow(
                              'Trạng thái',
                              _notification!.isRead ? 'Đã đọc' : 'Chưa đọc',
                              valueColor: _notification!.isRead
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A202C),
          ),
        ),
      ],
    );
  }
}
