import 'package:book_tech/features/auth/presentations/pages/ebook_reader_page.dart';
import 'package:book_tech/features/auth/presentations/widgets/document/similar_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/data/models/document_detail_model.dart';
import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import '../bloc/auth_bloc.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/data/models/document_response_model.dart';
import 'package:book_tech/features/auth/presentations/providers/cart_provider.dart';
import 'package:book_tech/features/auth/data/models/cart_item_model.dart';
import 'package:book_tech/core/ui/notification_service.dart';
import 'package:book_tech/features/auth/presentations/providers/wishlist_provider.dart';
import 'package:book_tech/features/auth/presentations/providers/reading_provider.dart';

class DocumentDetailPage extends StatefulWidget {
  final int documentId;

  const DocumentDetailPage({super.key, required this.documentId});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  DocumentDetailModel? _document;
  bool _isLoading = true;
  String? _error;
  List<DocumentResponseModel> _similarBooks = [];
  bool _isLoadingSimilar = false;

  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadDocumentDetail();
  }

  Future<void> _loadDocumentDetail() async {
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
      final document = await repository.getDocumentDetail(
        accessToken: authState.account.accessToken!,
        documentId: widget.documentId,
      );

      // Debug log để kiểm tra ebookUrl
      print('📚 Document ID: ${document.documentId}');
      print('📚 Title: ${document.title}');
      print('📚 Category: ${document.category['name'] ?? 'N/A'}');
      print('📚 ebookUrl: ${document.ebookUrl ?? 'NULL'}');
      print(
        '📚 Has ebook: ${document.ebookUrl != null && document.ebookUrl!.isNotEmpty}',
      );

      setState(() {
        _document = document;
        _isLoading = false;
      });
      // Sync bookmark state from wishlist
      final wishlist = Provider.of<WishlistProvider>(context, listen: false);
      _isBookmarked = wishlist.contains(document.documentId);
      _loadSimilarBooks();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Thêm method để load similar books
  Future<void> _loadSimilarBooks() async {
    if (_document == null) return;

    setState(() {
      _isLoadingSimilar = true;
    });

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

      final similarBooks = await repository.getSimilarDocuments(
        accessToken: authState.account.accessToken!,
        documentId: _document!.documentId,
        limit: 10,
      );

      setState(() {
        _similarBooks = similarBooks.map((entity) {
          // Convert DocumentEntity to DocumentResponseModel
          return DocumentResponseModel(
            documentId: entity.documentId,
            title: entity.title,
            coverPhoto: entity.coverPhoto,
            minDeposit: 0,
            maxDeposit: 0,
            coverPrice: entity.coverPrice ?? 0,
            categoryName: '',
            depositRate: 0.0,
            totalCopies: entity.numberOfCopy,
            availableCopies: entity.numberOfCopy, // Giả định tất cả đều có sẵn
            documentType: 'book',
          );
        }).toList();
        _isLoadingSimilar = false;
      });
    } catch (e) {
      print('Error loading similar books: $e');
      setState(() {
        _isLoadingSimilar = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _document?.title ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (_document?.ebookUrl != null)
            IconButton(
              tooltip: 'Tải ebook',
              icon: const Icon(
                Icons.download_for_offline_outlined,
                color: Colors.black87,
              ),
              onPressed: _downloadEbook,
            ),
          IconButton(
            tooltip: 'Chia sẻ',
            icon: const Icon(Icons.ios_share, color: Colors.black87),
            onPressed: _shareDocument,
          ),
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              if (_document == null) return;
              final wishlist = Provider.of<WishlistProvider>(
                context,
                listen: false,
              );
              wishlist.toggle(
                WishlistItem(
                  documentId: _document!.documentId,
                  title: _document!.title,
                  coverPhoto: _document!.coverPhoto,
                ),
              );
              final nowBookmarked = wishlist.contains(_document!.documentId);
              setState(() {
                _isBookmarked = nowBookmarked;
              });
              NotificationService.showInfo(
                context,
                message: nowBookmarked
                    ? 'Đã thêm vào muốn đọc'
                    : 'Đã bỏ khỏi muốn đọc',
              );
            },
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    const SizedBox(height: 30);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thông tin tài liệu',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocumentDetail,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_document == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          _buildInfo(),
          _buildActions(),
          _buildDescription(),
          _buildDetails(),
          // Thêm widget hiển thị sách tương tự
          SimilarBooksWidget(
            similarBooks: _similarBooks,
            isLoading: _isLoadingSimilar,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _document!.coverPhoto,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.book, size: 48, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _document!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Debug: Hiển thị trạng thái ebook (có thể ẩn sau khi debug xong)
                // if (_document!.ebookUrl == null || _document!.ebookUrl!.isEmpty)
                //   Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 8,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.orange.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(6),
                //       border: Border.all(color: Colors.orange, width: 1),
                //     ),
                //     child: const Text(
                //       '⚠️ Không có phiên bản điện tử',
                //       style: TextStyle(
                //         fontSize: 11,
                //         color: Colors.orange,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   )
                // else
                //   Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 8,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.green.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(6),
                //       border: Border.all(color: Colors.green, width: 1),
                //     ),
                //     child: Text(
                //       '✓ Có ebook: ${_document!.ebookUrl!.substring(0, _document!.ebookUrl!.length > 40 ? 40 : _document!.ebookUrl!.length)}${_document!.ebookUrl!.length > 40 ? '...' : ''}',
                //       style: const TextStyle(
                //         fontSize: 11,
                //         color: Colors.green,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ),
                // const SizedBox(height: 8),
                Text(
                  _document!.authors
                          .where((author) => author['role'] == 'main')
                          .map((author) => '${author['fullName'] ?? ''} ')
                          .firstOrNull ??
                      'Không có tác giả chính',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _document!.ebookUrl != null ? _readNow : null,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('ĐỌC NGAY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD33016),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_document!.ebookUrl != null)
                      OutlinedButton.icon(
                        onPressed: _downloadEbook,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('TẢI EBOOK'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black12),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem('Tổng số', '${_document!.totalCopies}'),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildInfoItem('Hiện có', '${_document!.availableCopies}'),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildInfoItem(
              'Đang cho mượn',
              '${_document!.totalCopies - _document!.availableCopies}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppPalette.gradient1,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Expanded(
          //   child: ElevatedButton.icon(
          //     onPressed: _document!.ebookUrl != null ? _downloadEbook : null,
          //     icon: const Icon(Icons.download, size: 20),
          //     label: const Text('Tải xuống'),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppPalette.gradient1,
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //   ),
          // ),
          const SizedBox(width: 12),
          // Expanded(
          //   child: ElevatedButton.icon(
          //     onPressed: _document!.ebookUrl != null ? _readNow : null,
          //     icon: const Icon(Icons.play_arrow, size: 20),
          //     label: const Text('Đọc ngay'),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.green,
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 238, 238, 238),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.all(12),
            child: Text(
              _document!.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(221, 27, 27, 27),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Nhà xuất bản', _document!.publisher['name'] ?? ''),
          _buildDetailRow(
            'Năm xuất bản',
            _document!.publicationYear.toString(),
          ),
          _buildDetailRow('Thể loại', _document!.category['name'] ?? ''),
          _buildDetailRow('Ngôn ngữ', _document!.language),
          if (_document!.minDeposit != null && _document!.maxDeposit != null)
            _buildDetailRow(
              'Tiền cọc',
              '${_formatCurrency(_document!.minDeposit!)} - ${_formatCurrency(_document!.maxDeposit!)}',
            ),
          // _buildDetailRow(
          //   'Giá bìa',
          //   '${_document!.coverPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ',
          // ),
          // if (_document!.book != null) ...[
          //   _buildDetailRow('ISBN', _document!.book!['isbn'] ?? ''),
          //   _buildDetailRow(
          //     'Số trang',
          //     '${_document!.book!['pageCount'] ?? 0}',
          //   ),
          //   _buildDetailRow(
          //     'Lần tái bản',
          //     '${_document!.book!['edition'] ?? 0}',
          //   ),
          // ],
          // _buildDetailRow(
          //   'Thể loại con',
          //   _document!.genres.map((g) => g['name'] ?? '').join(', '),
          // ),
          if (_document!.availableCopies > 0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Thêm vào giỏ hàng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadEbook() async {
    if (_document?.ebookUrl == null) return;
    final uri = Uri.tryParse(_document!.ebookUrl!);
    if (uri == null) return;
    final can = await canLaunchUrl(uri);
    if (can) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationService.showInfo(
        context,
        message: 'Không mở được liên kết tải xuống',
      );
    }
  }

  void _shareDocument() async {
    final title = _document?.title ?? '';
    final link = _document?.ebookUrl ?? '';
    final shareText = link.isNotEmpty ? '$title\n$link' : title;
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    NotificationService.showSuccess(context, message: 'Đã sao chép để chia sẻ');
  }

  // Thay thế method _readNow hiện tại
  void _readNow() {
    if (_document?.ebookUrl == null) {
      NotificationService.showInfo(
        context,
        message: 'Tài liệu này không có phiên bản điện tử',
      );
      return;
    }

    // Lưu vào danh sách đang đọc
    final readingProvider = Provider.of<ReadingProvider>(
      context,
      listen: false,
    );
    readingProvider.addOrUpdate(
      ReadingItem(
        documentId: _document!.documentId,
        title: _document!.title,
        coverPhoto: _document!.coverPhoto,
        ebookUrl: _document!.ebookUrl!,
        startedAt: DateTime.now(),
      ),
    );

    // Navigate trực tiếp đến EbookReaderPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EbookReaderPage(
          document: _document!,
          ebookUrl: _document!.ebookUrl!,
        ),
      ),
    );
  }

  // Thêm state variable
  int _quantity = 1;

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(
      CartItemModel(
        documentId: _document!.documentId,
        title: _document!.title,
        coverPhoto: _document!.coverPhoto,
        quantity: _quantity,
        minDeposit: _document!.minDeposit,
        maxDeposit: _document!.maxDeposit,
      ),
    );

    NotificationService.showSuccess(
      context,
      message: 'Đã thêm $_quantity sách vào giỏ hàng',
    );

    setState(() => _quantity = 1);
  }
}

String _formatCurrency(int amount) {
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ';
}

// removed unused extension helpers
