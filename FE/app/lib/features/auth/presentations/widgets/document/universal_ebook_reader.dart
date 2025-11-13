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
import 'package:flutter_html/flutter_html.dart';
import 'package:screen_brightness/screen_brightness.dart';

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

class _HighlightColorOption {
  const _HighlightColorOption({
    required this.label,
    required this.hex,
    required this.color,
  });

  final String label;
  final String hex;
  final Color color;
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
  final ScrollController _epubScrollController = ScrollController();
  int _currentChapterIndex = 0;

  // New state variables
  EbookSettings _settings = EbookSettings();
  List<EbookChapter> _chapters = [];
  List<EbookHighlight> _highlights = [];
  int _currentPage = 1;
  bool _showTableOfContents = false;
  bool _showHighlights = false;
  late TabController _tabController;
  Timer? _restReminderTimer;
  bool _isRestDialogVisible = false;
  final ScreenBrightness _screenBrightness = ScreenBrightness();
  double? _originalBrightness;
  bool _canControlBrightness = true;
  String? _selectedPdfText;
  bool _isHighlightSheetVisible = false;
  static const List<_HighlightColorOption> _highlightColorOptions = [
    _HighlightColorOption(
      label: 'Vàng',
      hex: '#FFF59D',
      color: Color(0xFFFFF59D),
    ),
    _HighlightColorOption(
      label: 'Xanh lá',
      hex: '#C5E1A5',
      color: Color(0xFFC5E1A5),
    ),
    _HighlightColorOption(
      label: 'Xanh dương',
      hex: '#AEDFF7',
      color: Color(0xFFAEDFF7),
    ),
    _HighlightColorOption(
      label: 'Hồng',
      hex: '#F8BBD0',
      color: Color(0xFFF8BBD0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeReader();
  }

  @override
  void dispose() {
    _restReminderTimer?.cancel();
    _tabController.dispose();
    _epubScrollController.dispose();
    unawaited(_restoreOriginalBrightness());
    super.dispose();
  }

  Future<void> _initializeReader() async {
    try {
      setState(() => _isLoading = true);

      // Load settings
      _settings = await EbookSettingsService.getSettings();
      await _captureOriginalBrightness();
      await _applyScreenBrightness();
      _restartRestReminderTimer();

      // Detect format
      _detectedFormat =
          widget.format ??
          await EbookReaderService.detectFormat(widget.ebookUrl);

      // Chuẩn bị dữ liệu theo định dạng
      if (_detectedFormat == EbookFormat.pdf ||
          _detectedFormat == EbookFormat.mobi ||
          _detectedFormat == EbookFormat.txt) {
        // Tải file cục bộ để sử dụng cho các định dạng cần file
        _localFilePath = await EbookReaderService.downloadFile(widget.ebookUrl);
      } else {
        _localFilePath = null;
      }
      // Load highlights
      _highlights = await EbookSettingsService.getHighlights(widget.title);

      if (_detectedFormat == EbookFormat.epub) {
        _chapters = await EbookReaderService.loadEpubChaptersFromUrl(
          widget.ebookUrl,
          settings: _settings,
        );
        _currentChapterIndex = 0;
        _currentPage = _currentChapterIndex + 1;
        if (_chapters.isEmpty) {
          _generateMockChapters();
        }
      } else {
        _generateMockChapters();
      }

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
        pageNumber: index + 1,
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
    final isEpub = _detectedFormat == EbookFormat.epub;
    final chapters = _chapters;
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        title: const Text('Mục lục'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showTableOfContents = false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: chapters.isEmpty
            ? const Center(child: Text('Không có mục lục.'))
            : EbookTableOfContents(
                chapters: chapters,
                currentPage: isEpub ? _currentChapterIndex + 1 : _currentPage,
                onChapterSelected: (chapter) {
                  setState(() => _showTableOfContents = false);
                  if (isEpub) {
                    final index = chapters.indexWhere(
                      (c) => c.id == chapter.id,
                    );
                    if (index != -1) {
                      _openEpubChapter(index);
                    }
                  } else {
                    _navigateToPage(chapter.pageNumber);
                  }
                },
              ),
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

  void _openEpubChapter(int index) {
    if (_detectedFormat != EbookFormat.epub ||
        index < 0 ||
        index >= _chapters.length) {
      return;
    }
    setState(() {
      _currentChapterIndex = index;
      _currentPage = index + 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_epubScrollController.hasClients) {
        _epubScrollController.jumpTo(0);
      }
    });
  }

  Widget _buildMainReader() {
    return Stack(children: [_buildReaderContent(), _buildFloatingControls()]);
  }

  Widget _buildReaderContent() {
    Widget content;
    switch (_detectedFormat) {
      case EbookFormat.pdf:
        content = _buildPdfReader();
        break;
      case EbookFormat.epub:
        content = _buildEpubReader();
        break;
      case EbookFormat.html:
        content = _buildHtmlReader();
        break;
      default:
        content = _buildWebViewReader();
        break;
    }
    return _applyEyeComfortFilters(content);
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
      onTextSelectionChanged: _handlePdfTextSelectionChanged,
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
        onTextSelectionChanged: _handlePdfTextSelectionChanged,
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

  Widget _applyEyeComfortFilters(Widget child) {
    if (!_settings.eyeComfortEnabled) {
      return child;
    }

    final warmth = _settings.warmth.clamp(0.0, 1.0);
    final brightness = _settings.brightness.clamp(0.0, 1.0);
    final warmOverlayOpacity = (warmth * 0.8).clamp(0.0, 0.85);
    final dimOpacity = ((1 - brightness) * 0.9).clamp(0.0, 0.85);

    return Stack(
      children: [
        child,
        if (warmOverlayOpacity > 0)
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: warmOverlayOpacity,
              duration: const Duration(milliseconds: 250),
              child: Container(color: const Color(0xFFF4E1A1)),
            ),
          ),
        if (dimOpacity > 0)
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: dimOpacity,
              duration: const Duration(milliseconds: 250),
              child: Container(color: Colors.black),
            ),
          ),
      ],
    );
  }

  void _handlePdfTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    final text = details.selectedText?.trim();
    if (text == null || text.isEmpty) {
      _selectedPdfText = null;
      return;
    }

    _selectedPdfText = text;

    if (!_isHighlightSheetVisible) {
      _showCreateHighlightSheet();
    }
  }

  Future<void> _showCreateHighlightSheet() async {
    if (!mounted || _selectedPdfText == null || _selectedPdfText!.isEmpty) {
      return;
    }

    setState(() => _isHighlightSheetVisible = true);

    final noteController = TextEditingController();
    String selectedColorHex = _highlightColorOptions.first.hex;

    EbookHighlight? createdHighlight;
    try {
      createdHighlight = await showModalBottomSheet<EbookHighlight>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tạo đánh dấu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedPdfText!,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chọn màu:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: _highlightColorOptions.map((option) {
                            final isSelected = option.hex == selectedColorHex;
                            return GestureDetector(
                              onTap: () {
                                setModalState(
                                  () => selectedColorHex = option.hex,
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: option.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú (tuỳ chọn)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final text = _selectedPdfText;
                              if (text == null || text.trim().isEmpty) {
                                Navigator.of(context).pop();
                                return;
                              }

                              final highlight = EbookHighlight(
                                id: DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                                text: text,
                                pageNumber: _currentPage,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                                createdAt: DateTime.now(),
                                color: selectedColorHex,
                              );

                              Navigator.of(context).pop(highlight);
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Lưu đánh dấu'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } finally {
      noteController.dispose();
      _selectedPdfText = null;
      _pdfController?.clearSelection();
      if (mounted) {
        setState(() => _isHighlightSheetVisible = false);
      }
    }

    final highlight = createdHighlight;

    if (!mounted || highlight == null) {
      return;
    }

    setState(() {
      _highlights.add(highlight);
    });
    try {
      await EbookSettingsService.saveHighlight(widget.title, highlight);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu đánh dấu.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu đánh dấu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureOriginalBrightness() async {
    if (kIsWeb || !_canControlBrightness) {
      return;
    }
    try {
      _originalBrightness ??= await _screenBrightness.current;
    } catch (_) {
      _canControlBrightness = false;
    }
  }

  Future<void> _applyScreenBrightness() async {
    if (kIsWeb || !_canControlBrightness) {
      return;
    }
    try {
      if (!_settings.eyeComfortEnabled) {
        await _restoreOriginalBrightness();
        return;
      }
      final target = _settings.brightness.clamp(0.0, 1.0);
      await _screenBrightness.setScreenBrightness(target);
    } catch (_) {
      _canControlBrightness = false;
    }
  }

  Future<void> _restoreOriginalBrightness() async {
    if (kIsWeb || !_canControlBrightness) {
      return;
    }
    try {
      if (_originalBrightness != null) {
        final value = _originalBrightness!.clamp(0.0, 1.0);
        await _screenBrightness.setScreenBrightness(value);
      } else {
        await _screenBrightness.resetScreenBrightness();
      }
    } catch (_) {}
  }

  void _restartRestReminderTimer() {
    _scheduleRestReminder(Duration(minutes: _settings.restReminderMinutes));
  }

  void _scheduleRestReminder(Duration duration) {
    _restReminderTimer?.cancel();
    if (!_settings.eyeComfortEnabled ||
        !_settings.restReminderEnabled ||
        duration.inMinutes <= 0) {
      return;
    }
    _restReminderTimer = Timer(duration, _onRestReminderElapsed);
  }

  void _onRestReminderElapsed() {
    if (!mounted) {
      return;
    }
    _showRestReminderDialog();
  }

  Future<void> _showRestReminderDialog() async {
    if (!mounted ||
        !_settings.eyeComfortEnabled ||
        !_settings.restReminderEnabled ||
        _isRestDialogVisible) {
      return;
    }

    _isRestDialogVisible = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nghỉ ngơi cho mắt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn đã đọc khoảng ${_settings.restReminderMinutes} phút.'),
              const SizedBox(height: 12),
              const Text(
                'Hãy thực hiện quy tắc 20-20-20: mỗi 20 phút, nhìn vào một điểm cách xa 6 mét trong 20 giây.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Hít thở sâu, chớp mắt và xoay cổ tay, vai để thư giãn trước khi tiếp tục đọc nhé.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _scheduleRestReminder(const Duration(minutes: 5));
              },
              child: const Text('Nhắc lại sau 5 phút'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartRestReminderTimer();
              },
              child: const Text('Đã nghỉ xong'),
            ),
          ],
        );
      },
    );

    _isRestDialogVisible = false;
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
    final backgroundColor = _getBackgroundColor();
    final textColor = _settings.theme == 'dark' ? Colors.white : Colors.black87;

    if (_chapters.isEmpty) {
      return Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: const Text('Không thể tải nội dung EPUB.'),
      );
    }

    final chapter =
        _chapters[_currentChapterIndex.clamp(0, _chapters.length - 1)];
    final content = chapter.content?.trim();

    return Container(
      color: backgroundColor,
      child: Scrollbar(
        controller: _epubScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _epubScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.title,
                style: TextStyle(
                  fontSize: _settings.fontSize + 4,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              if (content == null || content.isEmpty)
                Text(
                  'Chương này không có nội dung hoặc chưa được hỗ trợ hiển thị.',
                  style: TextStyle(
                    fontSize: _settings.fontSize,
                    height: _settings.lineHeight,
                    color: textColor,
                  ),
                )
              else
                Html(
                  data: content,
                  style: {
                    'body': Style(
                      fontFamily: _settings.fontFamily,
                      fontSize: FontSize(_settings.fontSize),
                      lineHeight: LineHeight(_settings.lineHeight),
                      color: textColor,
                      backgroundColor: backgroundColor,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    'p': Style(margin: Margins.symmetric(vertical: 8)),
                    'h1': Style(
                      color: textColor,
                      fontSize: FontSize(_settings.fontSize + 8),
                    ),
                    'h2': Style(
                      color: textColor,
                      fontSize: FontSize(_settings.fontSize + 6),
                    ),
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTheme() async {
    final newTheme = _settings.theme == 'dark' ? 'light' : 'dark';
    final newSettings = _settings.copyWith(theme: newTheme);

    await _updateSettings(newSettings);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => EbookSettingsDialog(
        currentSettings: _settings,
        onSettingsChanged: (newSettings) async {
          await _updateSettings(newSettings);
        },
      ),
    );
  }

  void _navigateToPage(int pageNumber) {
    if (_detectedFormat == EbookFormat.epub) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Định dạng EPUB không hỗ trợ nhảy trực tiếp theo số trang. Hãy chọn chương từ mục lục.',
          ),
        ),
      );
      return;
    }

    if (_pdfController != null) {
      _pdfController!.jumpToPage(pageNumber);
    }
    setState(() {
      _currentPage = pageNumber;
    });
  }

  Future<void> _updateSettings(EbookSettings newSettings) async {
    await EbookSettingsService.saveSettings(newSettings);
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = newSettings;
    });

    await _applyScreenBrightness();

    if (_settings.eyeComfortEnabled && _settings.restReminderEnabled) {
      _restartRestReminderTimer();
    } else {
      _restReminderTimer?.cancel();
      _restReminderTimer = null;
    }
  }
}
