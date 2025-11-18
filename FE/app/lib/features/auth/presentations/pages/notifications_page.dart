import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/data/repositories/notification_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/notification_remote_data_source.dart';
import 'package:book_tech/features/auth/data/models/notification_model.dart';
import 'package:book_tech/core/ui/notification_service.dart';
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
        NotificationService.showError(
          context,
          message: 'Lỗi tải thông báo: ${e.toString()}',
        );
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
        NotificationService.showSuccess(
          context,
          message: 'Đã đánh dấu ${response.updated} thông báo là đã đọc',
        );
        _loadNotifications(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, message: 'Lỗi: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    hint: const Text('Tất cả loại'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả loại'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'SYSTEM',
                        child: Text('Hệ thống'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'LOAN_PENDING',
                        child: Text('Chờ duyệt'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'LOAN_APPROVED',
                        child: Text('Đã duyệt'),
                      ),
                      const DropdownMenuItem<String>(
                        value: 'LOAN_REJECTED',
                        child: Text('Từ chối'),
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
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<bool>(
                    value: _selectedIsRead,
                    hint: const Text('Tất cả'),
                    isExpanded: true,
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
                        return _NotificationItem(
                          notification: notification,
                          onTap: () async {
                            // Mark as read when opening
                            if (!notification.isRead) {
                              try {
                                final authState = context
                                    .read<AuthBloc>()
                                    .state;
                                if (authState is AuthAuthenticated &&
                                    authState.account.accessToken?.isNotEmpty ==
                                        true) {
                                  await _repository.markAsRead(
                                    accessToken: authState.account.accessToken!,
                                    notificationId: notification.notificationID,
                                  );
                                  setState(() {
                                    // Find and update the notification in the list
                                    final index = _notifications.indexWhere(
                                      (n) =>
                                          n.notificationID ==
                                          notification.notificationID,
                                    );
                                    if (index != -1) {
                                      _notifications[index] = notification
                                          .copyWith(
                                            isRead: true,
                                            readAt: DateTime.now(),
                                          );
                                    }
                                  });
                                }
                              } catch (e) {
                                // Ignore error, still open detail
                              }
                            }

                            // Navigate to detail
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationDetailPage(
                                    notificationId: notification.notificationID,
                                  ),
                                ),
                              ).then((_) {
                                // Refresh after returning
                                _loadNotifications(refresh: true);
                              });
                            }
                          },
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

  const _NotificationItem({required this.notification, required this.onTap});

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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B35),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
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
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
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
    );
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
}
