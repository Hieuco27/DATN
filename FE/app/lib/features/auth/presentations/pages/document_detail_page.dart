import 'package:book_tech/features/auth/presentations/pages/ebook_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/data/models/document_detail_model.dart';
import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import '../bloc/auth_bloc.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';

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

      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isBookmarked ? 'Đã đánh dấu' : 'Bỏ đánh dấu'),
                  backgroundColor: _isBookmarked ? Colors.green : Colors.grey,
                ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildInfo(),
          _buildActions(),
          _buildDescription(),
          _buildDetails(),
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
          // Hình ảnh sách
          Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
          // Thông tin cơ bản
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _document!.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Tác giả
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

                const SizedBox(height: 60),
                ElevatedButton.icon(
                  onPressed: _document!.ebookUrl != null ? _readNow : null,
                  icon: const Icon(Icons.play_arrow, size: 1),
                  label: const Text('ĐỌC NGAY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 211, 48, 22),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                // Nhà xuất bản
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
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _document!.ebookUrl != null ? _downloadEbook : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download,
                      color: _document!.ebookUrl != null
                          ? Colors.blue[600]
                          : Colors.grey[400],
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tải xuống',
                      style: TextStyle(
                        fontSize: 12,
                        color: _document!.ebookUrl != null
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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
          _buildDetailRow('Ngôn ngữ', _document!.language ?? ''),
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
          const SizedBox(height: 16),
          // Nút đăng ký mượn trước
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _document!.availableCopies > 0
                  ? _registerBorrow
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _document!.availableCopies > 0
                    ? Colors.orange
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _document!.availableCopies > 0
                    ? 'Đăng ký mượn trước'
                    : 'Hết sách',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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

  void _downloadEbook() {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng tải xuống đang được phát triển')),
    );
  }

  // Thay thế method _readNow hiện tại
  void _readNow() {
    if (_document?.ebookUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài liệu này không có phiên bản điện tử'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

  void _registerBorrow() {
    // TODO: Implement borrow registration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đăng ký mượn đang được phát triển'),
      ),
    );
  }
}

extension on Map<String, dynamic> {
  get fullName => null;

  get isbn => null;

  get edition => null;

  String? get name => null;

  get pageCount => null;
}
