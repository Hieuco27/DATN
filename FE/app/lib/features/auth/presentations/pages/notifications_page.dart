import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/data/repositories/notification_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/notification_remote_data_source.dart';
import 'package:book_tech/features/auth/data/models/notification_model.dart';
import 'package:another_flushbar/flushbar.dart';
import 'notification_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationRepositoryImpl _repository = NotificationRepositoryImpl(
    remoteDataSource: NotificationRemoteDataSourceImpl(),
  );

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 20;
  String? _selectedType;
  bool? _selectedIsRead;
  final ScrollController _scrollController = ScrollController();
  bool _isHandlingTap = false; // Prevent double tap

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    print('🔃 _loadNotifications called (refresh=$refresh)');
    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _notifications = [];
        _hasMore = true;
      }
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        throw Exception('User not authenticated');
      }

      final response = await _repository.getNotifications(
        accessToken: authState.account.accessToken!,
        page: _currentPage,
        limit: _limit,
        type: _selectedType,
        isRead: _selectedIsRead,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = response.data;
          } else {
            _notifications.addAll(response.data);
          }
          _hasMore = response.data.length == _limit;
          _isLoading = false;
        });
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

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        throw Exception('User not authenticated');
      }

      final response = await _repository.markAllAsRead(
        accessToken: authState.account.accessToken!,
      );

      if (mounted) {
        Flushbar(
          title: 'Thành công',
          message: 'Đã đánh dấu ${response.updated} thông báo là đã đọc',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ).show(context);
        _loadNotifications(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        Flushbar(
          title: 'Lỗi',
          message: errorMessage,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ).show(context);
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Prevent double tap
    if (_isHandlingTap) {
      print('⚠️ Ignoring tap - already handling');
      return;
    }
    
    _isHandlingTap = true;
    print('👆 Handling tap for notification ${notification.notificationID}');
    
    // Auto mark as read nếu chưa đọc
    if (!notification.isRead) {
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated &&
            authState.account.accessToken?.isNotEmpty == true) {
          // Update UI ngay lập tức
          setState(() {
            final index = _notifications.indexWhere(
              (n) => n.notificationID == notification.notificationID,
            );
            if (index != -1) {
              print('🔄 Marking notification ${notification.notificationID} as read');
              _notifications[index] = notification.copyWith(
                isRead: true,
                readAt: DateTime.now(),
              );
              print('✅ Updated notification ${notification.notificationID}: isRead = ${_notifications[index].isRead}');
            }
          });

          // Gọi API trong background
          _repository.markAsRead(
            accessToken: authState.account.accessToken!,
            notificationId: notification.notificationID,
          ).then((_) {
            // Success
          }).catchError((e) {
            // Revert nếu lỗi
            if (mounted) {
              setState(() {
                final index = _notifications.indexWhere(
                  (n) => n.notificationID == notification.notificationID,
                );
                if (index != -1) {
                  _notifications[index] = notification;
                }
              });
            }
          });
        }
      } catch (e) {
        // Silently fail
      }
    }

    // Navigate to detail
    if (mounted) {
      print('📱 Navigating to detail page for notification ${notification.notificationID}');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationDetailPage(
            notificationId: notification.notificationID,
          ),
        ),
      );
      print('🔙 Back from detail page');
      // Không refresh toàn bộ để giữ trạng thái "đã đọc"
      _isHandlingTap = false; // Reset flag
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building NotificationsPage - notifications count: ${_notifications.length}');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A202C)),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Đọc tất cả'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B35),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    hint: const Text('Tất cả loại'),
                    isExpanded: true,
                    isDense: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả loại'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'reservation',
                        child: Text('📚 Đặt mượn'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'loan_approved',
                        child: Text('✅ Đã duyệt'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'loan_rejected',
                        child: Text('❌ Từ chối'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'loan_ready',
                        child: Text('🎉 Sẵn sàng lấy'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'loan_overdue',
                        child: Text('⚠️ Quá hạn'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'system',
                        child: Text('🔔 Hệ thống'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                      _loadNotifications(refresh: true);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<bool>(
                    value: _selectedIsRead,
                    hint: const Text('Tất cả'),
                    isExpanded: true,
                    isDense: true,
                    items: const [
                      DropdownMenuItem<bool>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text('Chưa đọc'),
                      ),
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text('Đã đọc'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedIsRead = value;
                      });
                      _loadNotifications(refresh: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: _notifications.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có thông báo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadNotifications(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _notifications.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _notifications.length) {
                          return _hasMore
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final notification = _notifications[index];
                        print('📦 ItemBuilder index=$index: notification ${notification.notificationID}, isRead=${notification.isRead}');
                        return _NotificationItem(
                          key: ValueKey('${notification.notificationID}_${notification.isRead}'),
                          notification: notification,
                          onTap: () => _handleNotificationTap(notification),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

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
        return 'Quá hạn';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building notification ${notification.notificationID}: isRead = ${notification.isRead}');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.grey.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : const Color(0xFFFF6B35).withOpacity(0.3),
              width: notification.isRead ? 1 : 1.5,
            ),
          ),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: const Color(0xFF1A202C),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B35),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(
                            notification.type,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(notification.type),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getTypeColor(notification.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
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
          ],
          ),
        ),
      ),
    );
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
}
