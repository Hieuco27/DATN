import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/data/repositories/notification_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/notification_remote_data_source.dart';
import 'package:book_tech/features/auth/data/models/notification_model.dart';
import 'package:another_flushbar/flushbar.dart';

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
        Flushbar(
          title: 'Lỗi',
          message: 'Lỗi tải thông báo: ${e.toString()}',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ).show(context);
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
        Flushbar(
          title: 'Thành công',
          message: 'Đã đánh dấu là chưa đọc',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ).show(context);
      }
    } catch (e) {
      Flushbar(
        title: 'Lỗi',
        message: 'Lỗi: ${e.toString()}',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ).show(context);
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'reservation':
        return 'Đặt mượn';
      case 'info':
        return 'Thông tin';
      case 'reminder':
        return 'Nhắc nhở';
      case 'alert':
      case 'alter':
        return 'Cảnh báo';
      case 'reminder_due':
        return 'Nhắc hạn trả';
      case 'overdue_notice':
        return 'Thông báo quá hạn';
      case 'reminder_approved':
      case 'reminder_appooved':
        return 'Đã duyệt';
      case 'system':
        return 'Hệ thống';
      case 'loan_pending':
        return 'Chờ duyệt';
      case 'loan_approved':
        return 'Đã duyệt';
      case 'loan_rejected':
        return 'Từ chối';
      case 'loan_ready':
        return 'Sẵn sàng lấy';
      case 'loan_due_soon':
        return 'Sắp đến hạn';
      case 'loan_overdue':
        return 'Quá hạn';
      case 'payment_success':
        return 'Thanh toán';
      case 'return_success':
        return 'Đã trả';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'loan_approved':
      case 'payment_success':
      case 'loan_ready':
      case 'return_success':
      case 'reminder_approved':
      case 'reminder_appooved':
        return const Color(0xFF10B981); // Green
      case 'loan_rejected':
      case 'loan_overdue':
      case 'overdue_notice':
      case 'alert':
      case 'alter':
        return const Color(0xFFEF4444); // Red
      case 'reservation':
      case 'loan_pending':
      case 'loan_due_soon':
      case 'reminder_due':
        return const Color(0xFFF97316); // Orange
      case 'reminder':
        return const Color(0xFFF59E0B); // Amber
      case 'system':
      case 'info':
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'reservation':
        return Icons.book_outlined;
      case 'info':
        return Icons.info_outline;
      case 'reminder':
        return Icons.notifications_active_outlined;
      case 'alert':
      case 'alter':
        return Icons.warning_amber_rounded;
      case 'reminder_due':
        return Icons.event_busy_outlined;
      case 'overdue_notice':
        return Icons.error_outline_rounded;
      case 'reminder_approved':
      case 'reminder_appooved':
        return Icons.verified_outlined;
      case 'system':
        return Icons.settings_outlined;
      case 'loan_pending':
        return Icons.access_time;
      case 'loan_approved':
        return Icons.check_circle_outline;
      case 'loan_rejected':
        return Icons.cancel_outlined;
      case 'loan_ready':
        return Icons.done_all;
      case 'loan_due_soon':
        return Icons.schedule;
      case 'loan_overdue':
        return Icons.warning_amber;
      case 'payment_success':
        return Icons.payment;
      case 'return_success':
        return Icons.assignment_return;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'CAO';
      case 'medium':
        return 'TB';
      case 'low':
        return 'THẤP';
      case 'urgent':
        return 'KHẨN';
      default:
        return priority.toUpperCase();
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return const Color(0xFFEF4444); // Red
      case 'medium':
        return const Color(0xFFF97316); // Orange
      case 'low':
        return const Color(0xFF3B82F6); // Blue
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Icons.priority_high;
      case 'medium':
        return Icons.flag;
      case 'low':
        return Icons.flag_outlined;
      default:
        return Icons.outlined_flag;
    }
  }

  void _handleLinkNavigation(String link) {
    // Parse link like "/loan/140218" and navigate to appropriate page
    if (link.startsWith('/loan/')) {
      final loanId = link.replaceFirst('/loan/', '');
      // Navigate to borrow history page (loan detail will be shown there)
      Navigator.pop(context); // Close current page
      Navigator.pushNamed(context, '/borrow-history');
      
      Flushbar(
        title: 'Thông tin',
        message: 'Xem chi tiết phiếu mượn #$loanId trong lịch sử',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ).show(context);
    } else {
      Flushbar(
        title: 'Lỗi',
        message: 'Không thể mở liên kết: $link',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
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
              child: Column(
                children: [
                  // Hero header với gradient
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getTypeColor(_notification!.type),
                          _getTypeColor(_notification!.type).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isSmallScreen ? 10 : 14,
                          10,
                          isSmallScreen ? 10 : 14,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type badge và priority
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getIcon(_notification!.type),
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          _getTypeLabel(_notification!.type),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_notification!.priority != 'normal')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getPriorityIcon(_notification!.priority),
                                          size: 11,
                                          color: _getPriorityColor(_notification!.priority),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          _getPriorityLabel(_notification!.priority),
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700,
                                            color: _getPriorityColor(_notification!.priority),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Title
                            Text(
                              _notification!.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            // Time
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 15,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _formatDateTime(_notification!.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content card
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Content
                            Text(
                              _notification!.content,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Divider
                            Divider(
                              color: Colors.grey.shade200,
                              height: 32,
                            ),
                            // Metadata info cards
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(
                                  icon: Icons.access_time_rounded,
                                  label: _formatDateTime(_notification!.createdAt),
                                  color: const Color(0xFF64748B),
                                ),
                                if (_notification!.emailAt != null)
                                  _buildInfoChip(
                                    icon: Icons.email_outlined,
                                    label: 'Đã gửi email',
                                    color: const Color(0xFF3B82F6),
                                  ),
                                if (_notification!.readAt != null)
                                  _buildInfoChip(
                                    icon: Icons.check_circle_outline,
                                    label: 'Đã đọc',
                                    color: const Color(0xFF10B981),
                                  )
                                else
                                  _buildInfoChip(
                                    icon: Icons.circle_outlined,
                                    label: 'Chưa đọc',
                                    color: const Color(0xFFF59E0B),
                                  ),
                              ],
                            ),
                            // Action button
                            if (_notification!.link != null && _notification!.link!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _handleLinkNavigation(_notification!.link!);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getTypeColor(_notification!.type),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Flexible(
                                        child: Text(
                                          'Xem chi tiết phiếu mượn',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            // Metadata detail (if needed)
                            if (_notification!.readAt != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Đã đọc lúc ${_formatDateTime(_notification!.readAt!)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
