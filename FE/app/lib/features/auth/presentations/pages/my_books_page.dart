import 'package:flutter/material.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/presentations/providers/wishlist_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/cart_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/reading_provider.dart';

class MyBooksPage extends StatefulWidget {
  const MyBooksPage({super.key});

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  int _selectedTabIndex = 0;
  bool _isSelectionMode = false;
  Set<int> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _isSelectionMode ? 'Đã chọn ${_selectedItems.length}' : 'Thư viện',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItems.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _handleDelete(),
                tooltip: 'Xóa',
              ),
            IconButton(
              icon: const Icon(Icons.check_box, color: AppPalette.gradient1),
              onPressed: _selectAll,
              tooltip: 'Chọn tất cả',
            ),
          ] else ...[
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                final count = cart.totalItems;
                return IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 26,
                        color: Colors.black87,
                      ),
                      if (count > 0)
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton('Đang đọc', 0, Icons.menu_book)),
          Expanded(child: _buildTabButton('Muốn đọc', 1, Icons.bookmark)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
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
          color: isSelected ? AppPalette.gradient1 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppPalette.gradient1.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
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
            return _buildBookCard(
              item.documentId,
              item.title,
              item.coverPhoto,
              onTap: () => Navigator.pushNamed(
                context,
                '/document-detail',
                arguments: item.documentId,
              ),
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
            return _buildBookCard(
              item.documentId,
              item.title,
              item.coverPhoto,
              onTap: () => Navigator.pushNamed(
                context,
                '/document-detail',
                arguments: item.documentId,
              ),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppPalette.gradient1.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: AppPalette.gradient1, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 0.63,
                    child: Image.network(
                      coverPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.book, size: 40),
                      ),
                    ),
                  ),
                ),
                if (_isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.gradient1
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.white : Colors.grey[400],
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.1,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search),
            label: const Text('Khám phá sách'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.gradient1,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${_selectedItems.length} sách?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
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
                  content: Text('Đã xóa ${_selectedItems.length} sách'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
