import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/presentations/providers/wishlist_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/cart_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/reading_provider.dart';

class MyBooksPage extends StatefulWidget {
  const MyBooksPage({super.key});

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  bool _isSelectionMode = false;
  Set<int> _selectedItems = {};
  late AnimationController _animationController;

  // Màu sắc đồng nhất với cart_page
  static const Color _primaryColor = Color(0xFFFF6B35);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF1A202C);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: _isSelectionMode
            ? Container(
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
                    Icons.close_rounded,
                    color: _textColor,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedItems.clear();
                    });
                  },
                ),
              )
            : null,
        title: Text(
          _isSelectionMode ? 'Đã chọn ${_selectedItems.length}' : 'Thư viện',
          style: const TextStyle(
            color: _textColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedItems.isNotEmpty)
              Container(
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
                  onPressed: () => _handleDelete(),
                  tooltip: 'Xóa',
                ),
              ),
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.select_all_rounded,
                  color: _primaryColor,
                ),
                onPressed: _selectAll,
                tooltip: 'Chọn tất cả',
              ),
            ),
          ] else ...[
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                final count = cart.totalItems;
                return Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
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
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 26,
                          color: _textColor,
                        ),
                        if (count > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  count > 99 ? '99+' : '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_selectedTabIndex == 0) {
                  return _buildReadingList();
                } else if (_selectedTabIndex == 1) {
                  return _buildWishlist();
                }
                return _buildEmptyState(
                  'Chưa có dữ liệu',
                  Icons.menu_book_outlined,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Đang đọc', 0, Icons.menu_book_rounded),
          ),
          Expanded(
            child: _buildTabButton('Muốn đọc', 1, Icons.bookmark_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            _selectedItems.clear();
            if (_isSelectionMode) {
              _isSelectionMode = false;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingList() {
    return Consumer<ReadingProvider>(
      builder: (context, reading, _) {
        if (reading.items.isEmpty) {
          return _buildEmptyState(
            'Chưa có sách đang đọc',
            Icons.menu_book_outlined,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.52,
          ),
          itemCount: reading.items.length,
          itemBuilder: (context, index) {
            final item = reading.items[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildBookCard(
                      item.documentId,
                      item.title,
                      item.coverPhoto,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/document-detail',
                        arguments: item.documentId,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWishlist() {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, _) {
        if (wishlist.items.isEmpty) {
          return _buildEmptyState(
            'Chưa có sách muốn đọc',
            Icons.bookmark_border,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.52,
          ),
          itemCount: wishlist.items.length,
          itemBuilder: (context, index) {
            final item = wishlist.items[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildBookCard(
                      item.documentId,
                      item.title,
                      item.coverPhoto,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/document-detail',
                        arguments: item.documentId,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBookCard(
    int documentId,
    String title,
    String coverPhoto, {
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedItems.contains(documentId);

    return GestureDetector(
      onTap: _isSelectionMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedItems.remove(documentId);
                } else {
                  _selectedItems.add(documentId);
                }
              });
            }
          : onTap,
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _selectedItems.add(documentId);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
          border: isSelected
              ? Border.all(color: _primaryColor, width: 2.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'book_$documentId',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 0.63,
                      child: Image.network(
                        coverPhoto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _primaryColor.withOpacity(0.3),
                                _primaryColor.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.book_rounded,
                            size: 40,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isSelectionMode)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? _primaryColor : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey[300]!,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.grey[400],
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 10.0),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 72, color: Colors.grey[400]),
            ),
            const SizedBox(height: 28),
            Text(
              message,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Hãy thêm sách vào thư viện của bạn',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Có thể navigate đến trang tìm kiếm
              },
              icon: const Icon(Icons.explore_rounded, size: 20),
              label: const Text(
                'Khám phá sách',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: _primaryColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAll() {
    setState(() {
      if (_selectedTabIndex == 0) {
        final reading = context.read<ReadingProvider>();
        if (_selectedItems.length == reading.items.length) {
          _selectedItems.clear();
        } else {
          _selectedItems = reading.items.map((e) => e.documentId).toSet();
        }
      } else {
        final wishlist = context.read<WishlistProvider>();
        if (_selectedItems.length == wishlist.items.length) {
          _selectedItems.clear();
        } else {
          _selectedItems = wishlist.items.map((e) => e.documentId).toSet();
        }
      }
    });
  }

  void _handleDelete() {
    if (_selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFE53E3E),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Xác nhận xóa',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: _textColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${_selectedItems.length} sách khỏi thư viện?',
          style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final count = _selectedItems.length;
              if (_selectedTabIndex == 0) {
                final reading = context.read<ReadingProvider>();
                for (final id in _selectedItems) {
                  reading.remove(id);
                }
              } else {
                final wishlist = context.read<WishlistProvider>();
                for (final id in _selectedItems) {
                  wishlist.remove(id);
                }
              }
              setState(() {
                _selectedItems.clear();
                _isSelectionMode = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Đã xóa $count sách',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
