import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:book_tech/core/services/ebook_reader_service.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';
import 'package:book_tech/core/services/ebook_settings_service.dart';
import 'package:book_tech/features/auth/presentations/widgets/ebook/ebook_settings_dialog.dart';
import 'package:book_tech/features/auth/presentations/widgets/ebook/ebook_table_of_contents.dart';
import 'package:book_tech/features/auth/presentations/widgets/ebook/ebook_highlights_panel.dart';
import 'package:epub_view/epub_view.dart';
import 'package:http/http.dart' as http;

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
  // ✅ EPUB controller
  EpubController? _epubController;
  String? _epubInitError;
  Uint8List? _epubBytes;
  // EPUB fallback WebView controller
  WebViewController? _epubFallbackController;

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
    _epubController?.dispose();
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
      if (_detectedFormat == EbookFormat.epub) {
        // Tải bytes trực tiếp để hiển thị (không ép lưu file)
        print('📥 Downloading EPUB from: ${widget.ebookUrl}');
        final resp = await http.get(Uri.parse(widget.ebookUrl));
        if (resp.statusCode != 200) {
          throw Exception('Không thể tải EPUB: HTTP ${resp.statusCode}');
        }
        print('✅ Downloaded EPUB: ${resp.bodyBytes.length} bytes');
        // Chuẩn hóa EPUB bị lệch chuẩn (../) trước khi render
        print('🔧 Sanitizing EPUB...');
        _epubBytes = EbookReaderService.sanitizeEpubBytes(resp.bodyBytes);
        print('✅ EPUB sanitization completed');
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
          // EPUB: khởi tạo controller ở _buildEpubReader khi có _localFilePath
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
          : SfPdfViewer.file(
              File(_localFilePath!),
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
            ),
    );
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

  // ✅ Thêm method để lấy màu nền theo theme
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
    return Container(
      color: _getBackgroundColor(),
      child: (_epubBytes == null && _localFilePath == null)
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải EPUB...'),
                ],
              ),
            )
          : _buildEpubContent(),
    );
  }

  Widget _buildEpubContent() {
    // Nếu đã có lỗi khởi tạo, hiển thị fallback
    if (_epubInitError != null) {
      _epubFallbackController ??= WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.ebookUrl));
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.withOpacity(0.2),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không thể hiển thị EPUB, đang mở dạng WebView',
                    style: TextStyle(color: Colors.orange[900], fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: WebViewWidget(controller: _epubFallbackController!)),
        ],
      );
    }

    // Khởi tạo controller một lần duy nhất
    if (_epubController == null) {
      try {
        print('🎯 Initializing EpubController...');
        _epubController = EpubController(
          document: _epubBytes != null
              ? EpubDocument.openData(_epubBytes!)
              : EpubDocument.openFile(File(_localFilePath!)),
        );
        print('✅ EpubController initialized successfully');
      } catch (e, stackTrace) {
        print('❌ EPUB parsing error: $e');
        print('Stack trace: $stackTrace');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _epubInitError = e.toString();
          });
        });
        return const Center(child: CircularProgressIndicator());
      }
    }

    return EpubView(
      controller: _epubController!,
      onDocumentLoaded: (_) {
        print('✅ EPUB document loaded in viewer');
      },
      onChapterChanged: (value) {},
    );
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
