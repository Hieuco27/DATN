import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/loan_repository.dart';
// removed unused model import
import 'package:book_tech/core/ui/notification_service.dart';
import 'package:book_tech/core/ui/overlay_notification_service.dart';
import 'package:book_tech/core/utils/app_logger.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  bool _isSubmitting = false;
  final Set<int> _selectedItems = {};
  late AnimationController _animationController;
  
  // Theo dõi số sách đang mượn
  int _activeBorrowCount = 0;
  bool _isLoadingBorrowStatus = true;
  static const int _maxBorrowLimit = 3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Load cart từ server khi mở trang
    context.read<CartBloc>().add(const CartStarted());
    _checkActiveBorrowCount();
  }

  /// Kiểm tra số sách đang mượn (không bao gồm RETURNED)
  Future<void> _checkActiveBorrowCount() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        setState(() => _isLoadingBorrowStatus = false);
        return;
      }

      final loanRepo = Provider.of<LoanRepository>(context, listen: false);
      
      // Lấy tất cả borrow history (page 1, limit lớn để lấy hết)
      final response = await loanRepo.getMyLoans(page: 1, limit: 100);
      
      // Đếm số sách đang mượn (đang có sách trong tay)
      int activeCount = 0;
      for (final loan in response.data) {
        // Đếm từng quyển sách trong details
        for (final detail in loan.details) {
          final detailStatus = detail.status.toUpperCase();
          
          // CHỈ tính các trạng thái đang có sách trong tay người mượn:
          // - BORROWED: Đang mượn bình thường
          // - OVERDUE: Quá hạn (vẫn đang giữ sách)
          // 
          // KHÔNG tính:
          // - PENDING, WAITING_FOR_PICKUP: Chưa lấy sách
          // - RETURNED, CANCELLED, REJECTED: Đã kết thúc
          // - LOST, DAMAGED: Đã xử lý phạt
          if (detailStatus == 'BORROWED' || detailStatus == 'OVERDUE') {
            activeCount++;
          }
        }
      }
      
      log.i('Active borrow count: $activeCount/$_maxBorrowLimit', 'CartPage');
      
      setState(() {
        _activeBorrowCount = activeCount;
        _isLoadingBorrowStatus = false;
      });
      
      // Nếu đã đạt giới hạn, hiển thị thông báo
      if (activeCount >= _maxBorrowLimit && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            NotificationService.showWarning(
              context,
              message: 'Bạn đã đạt giới hạn mượn $_maxBorrowLimit quyển sách. Vui lòng trả sách đã mượn trước khi đăng ký mượn thêm.',
              duration: const Duration(seconds: 4),
            );
          }
        });
      }
    } catch (e) {
      log.e('Failed to check borrow count', e, 'CartPage');
      setState(() => _isLoadingBorrowStatus = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleItemSelection(int documentId, bool isCurrentlySelected) {
    setState(() {
      if (isCurrentlySelected) {
        _selectedItems.remove(documentId);
      } else {
        // Kiểm tra tổng số sách (đang mượn + sẽ chọn)
        final totalAfterSelect = _activeBorrowCount + _selectedItems.length + 1;
        
        if (totalAfterSelect > _maxBorrowLimit) {
          NotificationService.showWarning(
            context,
            message: 'Bạn đã đạt giới hạn mượn $_maxBorrowLimit quyển. Hiện đang mượn $_activeBorrowCount quyển. Vui lòng trả sách trước khi mượn thêm.',
            duration: const Duration(seconds: 4),
          );
        } else if (_selectedItems.length >= 3) {
          NotificationService.showInfo(
            context,
            message: 'Chỉ được chọn tối đa 3 quyển mỗi lần.',
          );
        } else {
          _selectedItems.add(documentId);
          _animationController.forward(from: 0);
        }
      }
    });
  }

  Future<void> _submitReservation() async {
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded) return;

    final selected = cartState.items
        .where((i) => _selectedItems.contains(i.documentId))
        .toList();

    if (selected.isEmpty) {
      NotificationService.showInfo(
        context,
        message: 'Vui lòng chọn sách để đăng ký.',
      );
      return;
    }
    
    // ✅ KIỂM TRA THẺ THƯ VIỆN
    try {
      final authRepo = context.read<AuthenticationRepository>();
      log.i('Fetching profile to check member card...', 'CartPage');
      
      final profile = await authRepo.getProfile();
      log.i('Profile fetched successfully. MemberCard: ${profile.memberCard != null ? "exists" : "null"}', 'CartPage');
      

      if (profile.memberCard == null) {
        log.w('User does not have a member card', 'CartPage');
        NotificationService.showWarning(
          context,
          message: 'Bạn chưa đăng ký thẻ thư viện. Vui lòng đăng ký thẻ để được mượn sách về nhà.',
          duration: const Duration(seconds: 4),
        );
        return;
      }
      
      final cardStatus = profile.memberCard!.status.toUpperCase();
      log.i('Member card status: $cardStatus', 'CartPage');
      
      if (cardStatus != 'ACTIVE') {
        log.w('Member card is not active: $cardStatus', 'CartPage');
        NotificationService.showWarning(
          context,
          message: 'Thẻ thư viện của bạn chưa kích hoạt hoặc đã hết hạn. Vui lòng gia hạn thẻ.',
          duration: const Duration(seconds: 4),
        );
        return;
      }
      
      // Lấy giới hạn từ loại thẻ (nếu có)
      final memberCardLimit = profile.memberCard!.cardType?.maxBorrowLimit ?? 3;
      log.i('Member card limit: $memberCardLimit (CardType: ${profile.memberCard!.cardType?.typeName ?? "unknown"})', 'CartPage');
      
      // Kiểm tra giới hạn từ thẻ thành viên
      final totalAfterSubmit = _activeBorrowCount + selected.length;
      if (totalAfterSubmit > memberCardLimit) {
        log.w('Borrow limit exceeded: $totalAfterSubmit > $memberCardLimit', 'CartPage');
        NotificationService.showWarning(
          context,
message: 'Bạn đã đạt giới hạn $memberCardLimit quyển của thẻ thư viện. Đang mượn: $_activeBorrowCount quyển.',        );
        return;
      }
      
      log.i('Member card validation passed. Proceeding with reservation...', 'CartPage');
    } catch (e, stackTrace) {
      log.e('Failed to check member card status: ${e.toString()}', e, 'CartPage');
      
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      NotificationService.showError(
        context,
        message: 'Lỗi kiểm tra thẻ: $errorMessage',
        duration: const Duration(seconds: 4),
      );
      return;
    }
    
    // Kiểm tra giới hạn tổng số sách (fallback - double check)
    final totalAfterSubmit = _activeBorrowCount + selected.length;
    if (totalAfterSubmit > _maxBorrowLimit) {
      NotificationService.showWarning(
        context,
        message: 'Vượt quá giới hạn $_maxBorrowLimit quyển. Bạn đang mượn $_activeBorrowCount quyển, không thể mượn thêm ${selected.length} quyển. Vui lòng trả sách trước khi mượn thêm.',
        duration: const Duration(seconds: 4),
      );
      return;
    }
    
    if (selected.length > 3) {
      NotificationService.showInfo(
        context,
        message: 'Chỉ được chọn tối đa 3 quyển mỗi lần.',
      );
      return;
    }
    

    setState(() => _isSubmitting = true);

    try {
      log.i('Starting book reservation process...', 'CartPage');
      
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        throw Exception('User not authenticated');
      }

      final repository = Provider.of<DocumentRepository>(
        context,
        listen: false,
      );

      final items = selected.map((item) => item.toJson()).toList();
      log.i('Reserving ${items.length} books...', 'CartPage');

      final result = await repository.reserveBooks(
        accessToken: authState.account.accessToken!,
        items: items,
      );
      
      log.i('Reservation result: $result', 'CartPage');

      if (mounted) {
        // Kiểm tra xem có sách nào đã tồn tại trong phiếu mượn không
        // Chỉ dựa vào message, không check success field
        final hasExistingBooks = result['alreadyReserved'] != null || 
                                 result['existingBooks'] != null || 
                                 result['skipped'] != null ||
                                 (result['message']?.toString().toLowerCase().contains('đã có') ?? false) ||
                                 (result['message']?.toString().toLowerCase().contains('đã tồn tại') ?? false) ||
                                 (result['message']?.toString().toLowerCase().contains('already') ?? false);
        
        if (hasExistingBooks) {
          // Chỉ hiển thị message từ backend, không check success
          // KHÔNG xóa sách khỏi giỏ hàng
          final message = result['message'] ?? 'Một số sách đã có trong phiếu mượn của bạn.';
          NotificationService.showInfo(
            context,
            message: message,
            duration: const Duration(seconds: 4),
          );
        } else {
          // Mượn thành công - Clear các sách đã chọn khỏi giỏ
          for (final it in selected) {
            context.read<CartBloc>().add(CartItemRemoved(it.documentId));
          }
          _selectedItems.clear();
          
          // Hiển thị success notification như bình thường
          // Show overlay notification giống Messenger
          OverlayNotificationService.show(
            context,
            title: 'Đặt mượn thành công! ',
            message: 'Đã gửi yêu cầu mượn ${selected.length} quyển sách. Chờ thư viện duyệt.',
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            duration: const Duration(seconds: 5),
            onTap: () {
              // Navigate to notifications page nếu user click vào notification
              Navigator.pushNamed(context, '/notifications');
            },
          );
          
          // Show snackbar phụ - chỉ dùng message từ backend
          NotificationService.showSuccess(
            context,
            message: result['message'] ?? 'Đăng ký mượn thành công!',
          );
          
          // Cập nhật lại số sách đang mượn sau khi đăng ký thành công
          await _checkActiveBorrowCount();
          
          // Tránh Navigator đang locked
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e, stackTrace) {
      log.e('Book reservation failed: ${e.toString()}', e, 'CartPage');
      
      if (mounted) {
        // Loại bỏ prefix "Exception: " để hiển thị message gốc
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        
        // Nếu là JSON response, extract chỉ message field (bỏ success field)
        if (errorMessage.contains('"message"')) {
          final messageMatch = RegExp(r'"message"\s*:\s*"([^"]*)"').firstMatch(errorMessage);
          if (messageMatch != null && messageMatch.group(1) != null) {
            errorMessage = messageMatch.group(1)!;
          }
        }
        
        NotificationService.showError(
          context, 
          message: errorMessage,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern AppBar với gradient
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF2D3748),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'Danh sách đặt mượn',
              style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            titleSpacing: 0,
            actions: [
              BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  if (state is! CartLoaded || state.items.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE53E3E),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Xóa tất cả?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF1A202C),
                              ),
                            ),
                            content: const Text(
                              'Bạn có chắc chắn muốn xóa tất cả sách khỏi giỏ ?',
                              style: TextStyle(
                                color: Color(0xFF1A202C),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy', style: TextStyle(color: Color(0xFF1A202C))),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CartBloc>().add(const CartCleared());
                                  _selectedItems.clear();
                                  Navigator.pop(context);
                                  // CartBloc will emit new state and trigger rebuild
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53E3E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),

          // Body content
          SliverToBoxAdapter(
            child: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is! CartLoaded || state.items.isEmpty) {
                  return _buildEmptyState();
                }

                final selectedItems = state.items
                    .where((i) => _selectedItems.contains(i.documentId))
                    .toList();
                
               

                return Column(
                  children: [
                    // Warning banner về số sách đang mượn
                    if (!_isLoadingBorrowStatus && _activeBorrowCount > 0)
                      _buildBorrowStatusBanner(),
                    
                    // Items list
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final isSelected = _selectedItems.contains(
                            item.documentId,
                          );
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: _buildCartItem(
                                    item,
                                    isSelected,
                                    index,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Checkout Button
                    if (selectedItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitReservation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Đăng ký mượn (${selectedItems.length})',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Banner hiển thị số sách đang mượn
  Widget _buildBorrowStatusBanner() {
    final remainingSlots = _maxBorrowLimit - _activeBorrowCount;
    final isAtLimit = _activeBorrowCount >= _maxBorrowLimit;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAtLimit
              ? [
                  Colors.red.withOpacity(0.15),
                  Colors.red.withOpacity(0.05),
                ]
              : [
                  Colors.orange.withOpacity(0.15),
                  Colors.orange.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtLimit ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isAtLimit 
                  ? Colors.red.withOpacity(0.2) 
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAtLimit ? Icons.block_rounded : Icons.info_outline_rounded,
              color: isAtLimit ? Colors.red : Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAtLimit 
                      ? 'Đã đạt giới hạn mượn sách'
                      : 'Thông tin mượn sách',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isAtLimit ? Colors.red.shade700 : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAtLimit
                      ? 'Bạn đang mượn $_activeBorrowCount/$_maxBorrowLimit quyển. Vui lòng trả sách trước khi mượn thêm.'
                      : 'Bạn đang mượn: $_activeBorrowCount/$_maxBorrowLimit quyển. Còn lại: $remainingSlots quyển.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Giỏ sách trống',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hãy thêm sách vào giỏ để đăng ký mượn',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(dynamic item, bool isSelected, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFFF6B35).withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
        border: Border.all(
          color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleItemSelection(item.documentId, isSelected),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover
                Hero(
                  tag: 'book_${item.documentId}',
                  child: Container(
                    width: 80,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.coverPhoto,
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFF6B35).withOpacity(0.3),
                                const Color(0xFFFF6B35).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.book_rounded,
                            size: 30,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Book info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Color(0xFF1A202C),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Quantity removed
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFFFF6B35)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF6B35)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleItemSelection(item.documentId, isSelected),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedItems.remove(item.documentId);
                            });
                            context.read<CartBloc>().add(
                              CartItemRemoved(item.documentId),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFE53E3E),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
