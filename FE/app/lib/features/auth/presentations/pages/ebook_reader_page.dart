import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:book_tech/features/auth/data/models/document_detail_model.dart';
import 'package:book_tech/features/auth/presentations/widgets/document/universal_ebook_reader.dart';
import 'package:book_tech/core/services/ebook_reader_service.dart';
import 'package:book_tech/core/ui/notification_service.dart';

class EbookReaderPage extends StatefulWidget {
  final DocumentDetailModel document;
  final String ebookUrl;

  const EbookReaderPage({
    super.key,
    required this.document,
    required this.ebookUrl,
  });

  @override
  State<EbookReaderPage> createState() => _EbookReaderPageState();
}

class _EbookReaderPageState extends State<EbookReaderPage> {
  bool _isFullscreen = false;
  EbookFormat? _detectedFormat;

  @override
  void initState() {
    super.initState();
    _detectFormat();
  }

  Future<void> _detectFormat() async {
    _detectedFormat = await EbookReaderService.detectFormat(widget.ebookUrl);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isFullscreen ? null : _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _isFullscreen ? null : _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.document.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.fullscreen, color: Colors.black),
          onPressed: () {
            setState(() {
              _isFullscreen = !_isFullscreen;
            });
            if (_isFullscreen) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
            } else {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            }
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (value) {
            switch (value) {
              case 'bookmark':
                _addBookmark();
                break;
              case 'share':
                _shareBook();
                break;
              case 'refresh':
                _refreshEbook();
                break;
              case 'format':
                _showFormatInfo();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'bookmark',
              child: Row(
                children: [
                  Icon(Icons.bookmark_border),
                  SizedBox(width: 8),
                  Text('Đánh dấu'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Chia sẻ'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Tải lại'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'format',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Thông tin'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return UniversalEbookReader(
      // key: ValueKey('${widget.ebookUrl}_${widget.document.title}'),
      ebookUrl: widget.ebookUrl,
      title: widget.document.title,
      format: _detectedFormat,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _addBookmark,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshEbook),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showFormatInfo,
          ),
          const Spacer(),
          Text(
            _detectedFormat?.name.toUpperCase() ?? 'UNKNOWN',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshEbook() {
    setState(() {});
  }

  void _addBookmark() {
    NotificationService.showSuccess(
      context,
      message: 'Đã thêm vào danh sách đánh dấu',
    );
  }

  void _shareBook() {
    NotificationService.showInfo(
      context,
      message: 'Tính năng chia sẻ đang được phát triển',
    );
  }

  void _showFormatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin định dạng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Định dạng: ${_detectedFormat?.name.toUpperCase() ?? 'Không xác định'}',
            ),
            const SizedBox(height: 8),
            Text('URL: ${widget.ebookUrl}'),
            const SizedBox(height: 8),
            Text('Tiêu đề: ${widget.document.title}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
