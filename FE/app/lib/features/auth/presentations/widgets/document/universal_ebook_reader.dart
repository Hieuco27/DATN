import 'dart:async';
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:book_tech/core/services/ebook_reader_service.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';
import 'package:book_tech/core/services/ebook_settings_service.dart';
import 'package:book_tech/features/auth/presentations/widgets/ebook/ebook_settings_dialog.dart';
import 'package:book_tech/features/auth/presentations/widgets/ebook/ebook_table_of_contents.dart';
import 'package:book_tech/features/auth/presentations/widgets/ebook/ebook_highlights_panel.dart';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UniversalEbookReader extends StatefulWidget {
  final String ebookUrl;
  final String title;
  final EbookFormat? format;

  const UniversalEbookReader({
    super.key,
    required this.ebookUrl,
    required this.title,
    this.format,
  });

  @override
  State<UniversalEbookReader> createState() => _UniversalEbookReaderState();
}

class _UniversalEbookReaderState extends State<UniversalEbookReader>
    with TickerProviderStateMixin {
  EbookFormat? _detectedFormat;
  bool _isLoading = true;
  String? _error;
  String? _localFilePath;
  // ✅ Sử dụng PdfViewerController từ Syncfusion
  PdfViewerController? _pdfController;
  // ✅ Thêm WebViewController để tránh reload
  WebViewController? _webViewController;

  // New state variables
  EbookSettings _settings = EbookSettings();
  List<EbookChapter> _chapters = [];
  List<EbookHighlight> _highlights = [];
  int _currentPage = 1;
  bool _showTableOfContents = false;
  bool _showHighlights = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeReader();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeReader() async {
    try {
      setState(() => _isLoading = true);

      // Load settings
      _settings = await EbookSettingsService.getSettings();

      // Detect format
      _detectedFormat =
          widget.format ??
          await EbookReaderService.detectFormat(widget.ebookUrl);

      // Chuẩn bị dữ liệu theo định dạng
      // EPUB: không tải về trước, sẽ tải tạm thời khi mở
      if (_detectedFormat == EbookFormat.epub) {
        print('📖 EPUB format detected - will load from URL when opening');
      } else if (_detectedFormat != EbookFormat.html) {
        // PDF và định dạng khác: tải về file tạm để viewer sử dụng
        _localFilePath = await EbookReaderService.downloadFile(widget.ebookUrl);
      }

      // Load highlights
      _highlights = await EbookSettingsService.getHighlights(widget.title);

      // Generate mock chapters
      _generateMockChapters();

      // Load specific format
      await _loadEbookContent();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _generateMockChapters() {
    _chapters = List.generate(10, (index) {
      return EbookChapter(
        id: 'chapter_${index + 1}',
        title: 'Chương ${index + 1}',
        pageNumber: (index * 5) + 1,
      );
    });
  }

  Future<void> _loadEbookContent() async {
    try {
      switch (_detectedFormat) {
        case EbookFormat.pdf:
          // ✅ Khởi tạo PdfViewerController từ Syncfusion
          _pdfController = PdfViewerController();
          break;
        case EbookFormat.html:
        // HTML hiển thị bằng WebView
        case EbookFormat.mobi:
        case EbookFormat.txt:
          // ✅ Khởi tạo WebViewController một lần
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(widget.ebookUrl));
          break;
        case EbookFormat.epub:
          // EPUB: Không cần khởi tạo controller cho cosmos_epub
          // cosmos_epub sẽ tự mở fullscreen khi được gọi
          print('✅ EPUB format detected - will use CosmosEpub');
          break;
        default:
          throw Exception('Unsupported format: $_detectedFormat');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Removed: _initializeEpubController - using cosmos_epub instead

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return _buildReaderWidget();
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải ebook...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không thể tải ebook',
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
            onPressed: _initializeReader,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderWidget() {
    return Stack(
      children: [
        _buildMainReader(),
        if (_showTableOfContents) _buildTableOfContentsOverlay(),
        if (_showHighlights) _buildHighlightsOverlay(),
      ],
    );
  }

  Widget _buildTableOfContentsOverlay() {
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        title: const Text('Mục lục'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showTableOfContents = false),
        ),
      ),
      body: EbookTableOfContents(
        chapters: _chapters,
        currentPage: _currentPage,
        onChapterSelected: (chapter) {
          setState(() => _showTableOfContents = false);
          _navigateToPage(chapter.pageNumber);
        },
      ),
    );
  }

  Widget _buildHighlightsOverlay() {
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        title: const Text('Đánh dấu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showHighlights = false),
        ),
      ),
      body: EbookHighlightsPanel(
        highlights: _highlights,
        onHighlightTap: (highlight) {
          setState(() => _showHighlights = false);
          _navigateToPage(highlight.pageNumber);
        },
        onDeleteHighlight: (highlightId) async {
          await EbookSettingsService.deleteHighlight(widget.title, highlightId);
          setState(() {
            _highlights.removeWhere((h) => h.id == highlightId);
          });
        },
      ),
    );
  }

  Widget _buildMainReader() {
    return Stack(children: [_buildReaderContent(), _buildFloatingControls()]);
  }

  Widget _buildReaderContent() {
    switch (_detectedFormat) {
      case EbookFormat.pdf:
        return _buildPdfReader();
      case EbookFormat.epub:
        return _buildEpubReader();
      case EbookFormat.html:
        return _buildHtmlReader();
      default:
        return _buildWebViewReader();
    }
  }

  // ✅ PDF reader với Syncfusion
  Widget _buildPdfReader() {
    return Container(
      color: _getBackgroundColor(),
      child: _localFilePath == null
          ? const SizedBox.shrink()
          : _buildPdfViewer(),
    );
  }

  Widget _buildPdfViewer() {
    // Trên web hoặc không có local file, dùng network URL
    if (kIsWeb || _localFilePath == null) {
      return _buildNetworkPdfViewer();
    }

    // Trên desktop, dùng local file - chỉ compile khi không phải web
    return _buildFilePdfViewer();
  }

  Widget _buildNetworkPdfViewer() {
    return SfPdfViewer.network(
      widget.ebookUrl,
      controller: _pdfController,
      enableDoubleTapZooming: true,
      enableTextSelection: true,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        setState(() {
          _error = 'Không thể tải PDF: ${details.error}';
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
    );
  }

  Widget _buildFilePdfViewer() {
    if (kIsWeb) {
      // Không bao giờ đến đây trên web, nhưng để type checker happy
      return _buildNetworkPdfViewer();
    }

    try {
      // Chỉ sử dụng io.File trên desktop - dùng dynamic để tránh compile error trên web
      final file = _createFile(_localFilePath!);
      if (file == null) {
        return _buildNetworkPdfViewer();
      }
      return SfPdfViewer.file(
        file as dynamic,
        controller: _pdfController,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          setState(() {
            _error = 'Không thể tải PDF: ${details.error}';
          });
        },
        onPageChanged: (PdfPageChangedDetails details) {
          setState(() {
            _currentPage = details.newPageNumber;
          });
        },
      );
    } catch (e) {
      // Fallback to network if file access fails
      return _buildNetworkPdfViewer();
    }
  }

  // Helper function để tạo File - chỉ hoạt động trên desktop
  // Sử dụng conditional compilation để tránh lỗi trên web
  dynamic _createFile(String path) {
    if (kIsWeb) return null;
    // ignore: avoid_web_libraries_in_flutter
    // Trên desktop, dart:io.File có sẵn, trên web dùng stub
    return io.File(path);
  }

  Widget _buildHtmlReader() {
    return Container(
      color: _getBackgroundColor(),
      child: _webViewController != null
          ? WebViewWidget(controller: _webViewController!)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildWebViewReader() {
    return Container(
      color: _getBackgroundColor(),
      child: _webViewController != null
          ? WebViewWidget(controller: _webViewController!)
          : const SizedBox.shrink(),
    );
  }

  //  Thêm method để lấy màu nền theo theme
  Color _getBackgroundColor() {
    switch (_settings.theme) {
      case 'dark':
        return Colors.grey[900]!;
      case 'light':
      default:
        return Colors.white;
    }
  }

  Widget _buildFloatingControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "settings",
            mini: true,
            backgroundColor: _settings.theme == 'dark'
                ? Colors.grey[800]
                : Colors.blue,
            onPressed: _showSettingsDialog,
            child: Icon(
              Icons.settings,
              color: _settings.theme == 'dark' ? Colors.white : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "highlights",
            mini: true,
            backgroundColor: _settings.theme == 'dark'
                ? Colors.grey[800]
                : Colors.orange,
            onPressed: () => setState(() => _showHighlights = true),
            child: Icon(
              Icons.highlight,
              color: _settings.theme == 'dark' ? Colors.white : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "toc",
            mini: true,
            backgroundColor: _settings.theme == 'dark'
                ? Colors.grey[800]
                : Colors.green,
            onPressed: () => setState(() => _showTableOfContents = true),
            child: Icon(
              Icons.list,
              color: _settings.theme == 'dark' ? Colors.white : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "theme",
            mini: true,
            backgroundColor: _settings.theme == 'dark'
                ? Colors.grey[800]
                : Colors.purple,
            onPressed: _toggleTheme,
            child: Icon(
              _settings.theme == 'dark' ? Icons.light_mode : Icons.dark_mode,
              color: _settings.theme == 'dark' ? Colors.white : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpubReader() {
    // Sử dụng cosmos_epub thay vì epub_view
    return Container(
      color: _getBackgroundColor(),
      child: _buildCosmosEpubContent(),
    );
  }

  // Removed: _buildEpubContent - using cosmos_epub instead

  Widget _buildCosmosEpubContent() {
    // Gọi cosmos_epub để mở fullscreen reader (sẽ tải từ URL khi mở)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCosmosEpub();
    });

    // Hiển thị thông báo đang tải và mở
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Đang tải sách: ${widget.title}'),
          const SizedBox(height: 8),
          const Text(
            'Đang tải từ URL và mở Cosmos EPUB Reader...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _openCosmosEpub() async {
    if (kIsWeb) {
      print('❌ Cannot open cosmos_epub on web platform');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EPUB reader không hỗ trợ trên web'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    String? tempFilePath;

    try {
      // Tải file tạm thời từ URL
      print('📥 Downloading EPUB from URL: ${widget.ebookUrl}');
      
      final response = await http.get(Uri.parse(widget.ebookUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Không thể tải file: HTTP ${response.statusCode}',
        );
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('File tải về trống');
      }

      // Lưu vào temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.ebookUrl.split('/').last;
      final fileExtension = fileName.contains('.') 
          ? fileName.substring(fileName.lastIndexOf('.'))
          : '.epub';
      final uniqueFileName = 'epub_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      tempFilePath = '${tempDir.path}/$uniqueFileName';
      
      final file = io.File(tempFilePath);
      await file.writeAsBytes(response.bodyBytes);
      print('✅ EPUB downloaded to temporary file: $tempFilePath');

      // Mở với cosmos_epub
      print('📖 Opening EPUB with CosmosEpub: $tempFilePath');
      await CosmosEpub.openLocalBook(
        localPath: tempFilePath,
        context: context,
        bookId: widget.title,
        onPageFlip: (int currentPage, int totalPages) {
          print('📄 Page flipped: $currentPage / $totalPages');
        },
        onLastPage: (int lastPageIndex) {
          print('🏁 Reached last page: $lastPageIndex');
        },
      );

      // Xóa file tạm sau khi mở (đợi một chút để đảm bảo file đã được đọc)
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          if (tempFilePath != null) {
            final tempFile = io.File(tempFilePath);
            if (await tempFile.exists()) {
              await tempFile.delete();
              print('🗑️ Deleted temporary EPUB file: $tempFilePath');
            }
          }
        } catch (e) {
          print('⚠️ Could not delete temporary file: $e');
        }
      });
    } catch (e) {
      print('❌ Error opening cosmos_epub: $e');
      
      // Xóa file tạm nếu có lỗi
      if (tempFilePath != null) {
        try {
          final tempFile = io.File(tempFilePath);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở EPUB: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleTheme() async {
    final newTheme = _settings.theme == 'dark' ? 'light' : 'dark';
    final newSettings = _settings.copyWith(theme: newTheme);

    await EbookSettingsService.saveSettings(newSettings);
    setState(() {
      _settings = newSettings;
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => EbookSettingsDialog(
        currentSettings: _settings,
        onSettingsChanged: (newSettings) async {
          await EbookSettingsService.saveSettings(newSettings);
          setState(() {
            _settings = newSettings;
          });
        },
      ),
    );
  }

  void _navigateToPage(int pageNumber) {
    if (_pdfController != null) {
      _pdfController!.jumpToPage(pageNumber);
    }
    setState(() {
      _currentPage = pageNumber;
    });
  }
}
