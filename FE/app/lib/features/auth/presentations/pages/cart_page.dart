import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../../domain/repositories/document_repository.dart';
// removed unused model import
import 'package:book_tech/core/ui/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReservation() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final selected = cartProvider.items
        .where((i) => _selectedItems.contains(i.documentId))
        .toList();

    if (selected.isEmpty) {
      NotificationService.showInfo(
        context,
        message: 'Vui lòng chọn sách (tối đa 3) để đăng ký.',
      );
      return;
    }
    if (selected.length > 3) {
      NotificationService.showInfo(
        context,
        message: 'Chỉ được chọn tối đa 3 sách.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
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

      final result = await repository.reserveBooks(
        accessToken: authState.account.accessToken!,
        items: items,
      );

      // Clear chỉ các sách đã chọn khỏi giỏ
      for (final it in selected) {
        cartProvider.removeItem(it.documentId);
      }
      _selectedItems.clear();

      if (mounted) {
        NotificationService.showSuccess(
          context,
          message: result['message'] ?? 'Đăng ký mượn thành công!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, message: 'Lỗi: ${e.toString()}');
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
              'Giỏ hàng',
              style: TextStyle(
                color: Color(0xFF1A202C),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            titleSpacing: 0,
            actions: [
              Consumer<CartProvider>(
                builder: (context, cart, _) {
                  if (cart.items.isEmpty) return const SizedBox.shrink();
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Xóa tất cả?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            content: const Text(
                              'Bạn có chắc chắn muốn xóa tất cả sách khỏi giỏ hàng?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Provider.of<CartProvider>(
                                    context,
                                    listen: false,
                                  ).clear();
                                  _selectedItems.clear();
                                  Navigator.pop(context);
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53E3E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Xóa'),
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
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (cart.items.isEmpty) {
                  return _buildEmptyState();
                }

                final selectedItems = cart.items
                    .where((i) => _selectedItems.contains(i.documentId))
                    .toList();
                final totalMin = selectedItems.fold<int>(
                  0,
                  (s, i) => s + ((i.minDeposit ?? 0) * i.quantity),
                );
                final totalMax = selectedItems.fold<int>(
                  0,
                  (s, i) => s + ((i.maxDeposit ?? 0) * i.quantity),
                );

                return Column(
                  children: [
                    // Items list
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
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

                    // Summary section
                    _buildSummarySection(
                      selectedItems.length,
                      totalMin,
                      totalMax,
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
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Giỏ hàng trống',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hãy thêm sách vào giỏ hàng để tiếp tục',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedItems.remove(item.documentId);
              } else {
                if (_selectedItems.length >= 3) {
                  NotificationService.showInfo(
                    context,
                    message: 'Bạn chỉ được mượn tối đa 3 quyển sách.',
                  );
                } else {
                  _selectedItems.add(item.documentId);
                  _animationController.forward(from: 0);
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            size: 40,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Book info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Color(0xFF1A202C),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Quantity badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_rounded,
                              size: 14,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Số lượng: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Deposit info
                      if (item.minDeposit != null && item.maxDeposit != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF6B35).withOpacity(0.1),
                                const Color(0xFFFF6B35).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 14,
                                color: const Color(0xFFFF6B35),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cọc: ${_formatCurrency(item.minDeposit!)} - ${_formatCurrency(item.maxDeposit!)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedItems.remove(item.documentId);
                              } else {
                                if (_selectedItems.length >= 3) {
                                  NotificationService.showInfo(
                                    context,
                                    message:
                                        'Bạn chỉ được mượn tối đa 3 quyển sách.',
                                  );
                                } else {
                                  _selectedItems.add(item.documentId);
                                }
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
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
                              Provider.of<CartProvider>(
                                context,
                                listen: false,
                              ).removeItem(item.documentId);
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
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

  Widget _buildSummarySection(int selectedCount, int totalMin, int totalMax) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đã chọn',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '$selectedCount',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                              Text(
                                '/3',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: selectedCount / 3,
                              strokeWidth: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                          Text(
                            '${(selectedCount / 3 * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Total price
              if (selectedCount > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF6B35).withOpacity(0.1),
                        const Color(0xFFFF6B35).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: const Color(0xFFFF6B35),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tổng cọc',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatCurrency(totalMin)} - ${_formatCurrency(totalMax)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF6B35),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

              if (selectedCount > 0) const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _selectedItems.isEmpty)
                      ? null
                      : _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: _selectedItems.isEmpty ? 0 : 8,
                    shadowColor: const Color(0xFFFF6B35).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Đăng ký mượn',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ';
  }
}
