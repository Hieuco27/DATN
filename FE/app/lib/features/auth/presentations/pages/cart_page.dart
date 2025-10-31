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

class _CartPageState extends State<CartPage> {
  bool _isSubmitting = false;
  final Set<int> _selectedItems = {};

  Future<void> _submitReservation() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final selected = cartProvider.items
        .where((i) => _selectedItems.contains(i.documentId))
        .toList();

    if (selected.isEmpty) {
      NotificationService.showInfo(context, message: 'Vui lòng chọn sách (tối đa 3) để đăng ký.');
      return;
    }
    if (selected.length > 3) {
      NotificationService.showInfo(context, message: 'Chỉ được chọn tối đa 3 sách.');
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
          message: result['message'] ?? 'Đăng ký mượn thành công!'
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 141, 141, 141),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () =>
                Provider.of<CartProvider>(context, listen: false).clear(),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Giỏ hàng trống',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Card(
                      color: const Color(0xFFFFF3E0),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item.coverPhoto,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.book, size: 24),
                            ),
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Số lượng: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color.fromARGB(255, 84, 84, 84),
                              ),
                            ),
                            const SizedBox(height: 4),

                            if (item.minDeposit != null &&
                                item.maxDeposit != null)
                              Text(
                                'Cọc: ${_formatCurrency(item.minDeposit!)} - ${_formatCurrency(item.maxDeposit!)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color.fromARGB(255, 84, 84, 84),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _selectedItems.contains(item.documentId),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    if (_selectedItems.length >= 3) {
                                      NotificationService.showInfo(
                                        context,
                                        message: 'Bạn chỉ được mượn tối đa 3 quyển sách.',
                                      );
                                    } else {
                                      _selectedItems.add(item.documentId);
                                    }
                                  } else {
                                    _selectedItems.remove(item.documentId);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                _selectedItems.remove(
                                  item.documentId,
                                ); // bỏ chọn nếu xóa
                                cart.removeItem(item.documentId);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Tổng tiền và nút đăng ký
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),

                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đã chọn: ${_selectedItems.length}/3',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_formatCurrency(totalMin)} - ${_formatCurrency(totalMax)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _selectedItems.isEmpty)
                            ? null
                            : _submitReservation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Đăng ký mượn',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ';
  }
}
