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
import 'package:flutter_html/flutter_html.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UniversalEbookReader extends StatefulWidget {
  final String ebookUrl;
  final String title;
  final EbookFormat? format;
  final bool hideFloatingControls;

  const UniversalEbookReader({
    super.key,
    required this.ebookUrl,
    required this.title,
    this.format,
    this.hideFloatingControls = false,
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
  EbookReadingProgress? _readingProgress;
  int _currentPage = 1;
  bool _showReaderMenu = false;
  int _readerMenuTabIndex = 0;
  late TabController _tabController;
  Timer? _restReminderTimer;
  bool _isRestDialogVisible = false;
  final ScreenBrightness _screenBrightness = ScreenBrightness();
  double? _originalBrightness;
  bool _canControlBrightness = true;
  String? _selectedPdfText;
  String? _selectedEpubText;
  bool _isHighlightSheetVisible = false;
  bool _isRestoringProgress = false;
  bool _initialProgressApplied = false;
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
      _readingProgress = await EbookSettingsService.getReadingProgress(
        widget.title,
      );

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
      _applySavedProgressIfNeeded();
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

  void _applySavedProgressIfNeeded() {
    if (_readingProgress == null || _initialProgressApplied) {
      return;
    }

    final savedPage = _readingProgress!.pageNumber;
    if (savedPage > 0 && savedPage != _currentPage) {
      setState(() {
        _currentPage = savedPage;
      });
    }

    if (_detectedFormat == EbookFormat.epub && _chapters.isNotEmpty) {
      final totalChapters = _chapters.length;
      final savedIndex =
          (_readingProgress!.chapterIndex ??
                  (savedPage > 0 ? savedPage - 1 : 0))
              .clamp(0, totalChapters - 1);
      _isRestoringProgress = true;
      _openEpubChapter(savedIndex);
      _isRestoringProgress = false;
    } else if (_detectedFormat == EbookFormat.pdf &&
        _pdfController != null &&
        savedPage > 0) {
      _isRestoringProgress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pdfController == null) {
          _isRestoringProgress = false;
          return;
        }
        _pdfController!.jumpToPage(savedPage);
      });
    }

    _initialProgressApplied = true;
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
        if (_showReaderMenu) _buildReaderMenuOverlay(),
      ],
    );
  }

  Widget _buildReaderMenuOverlay() {
    final chapters = _chapters;
    final isEpub = _detectedFormat == EbookFormat.epub;
    final showHighlights = _readerMenuTabIndex == 1;
    final mediaQuery = MediaQuery.of(context);

    return Material(
      color: Colors.black54,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: mediaQuery.size.height * 0.9,
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _closeReaderMenu,
                      ),
                      Expanded(child: _buildMenuSegmentedControl()),
                      if (showHighlights && _highlights.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          tooltip: 'Export highlights',
                          onPressed: _handleExportHighlights,
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    layoutBuilder: (currentChild, previousChildren) {
                      return currentChild ?? const SizedBox.shrink();
                    },
                    child: showHighlights
                        ? _buildHighlightsList(
                            key: const ValueKey('highlights'),
                          )
                        : _buildContentsList(
                            chapters,
                            isEpub,
                            key: const ValueKey('contents'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSegmentedControl() {
    final labels = ['Contents', 'Highlights'];
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = _readerMenuTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_readerMenuTabIndex != index) {
                  setState(() => _readerMenuTabIndex = index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.redAccent : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContentsList(
    List<EbookChapter> chapters,
    bool isEpub, {
    Key? key,
  }) {
    if (chapters.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        message: 'Không có mục lục.',
      );
    }

    return ListView.separated(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isActive = isEpub
            ? index == _currentChapterIndex
            : (index + 1) == _currentPage;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleChapterTap(chapter, index, isEpub),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.redAccent.withOpacity(0.08) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.redAccent : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (!isEpub)
                  Text(
                    'Trang ${chapter.pageNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: chapters.length,
    );
  }

  Widget _buildHighlightsList({Key? key}) {
    if (_highlights.isEmpty) {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.highlight_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Chưa có đánh dấu nào',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _detectedFormat == EbookFormat.pdf
                    ? 'Chọn văn bản trong PDF và chọn màu để đánh dấu'
                    : 'Long press vào nội dung EPUB và nhập văn bản để đánh dấu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Hướng dẫn',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_detectedFormat == EbookFormat.pdf) ...[
                      _buildInstructionRow('1. Chọn văn bản trong PDF'),
                      _buildInstructionRow('2. Chọn màu highlight'),
                      _buildInstructionRow('3. Thêm ghi chú (tùy chọn)'),
                      _buildInstructionRow('4. Nhấn "Lưu đánh dấu"'),
                    ] else ...[
                      _buildInstructionRow('1. Long press vào trang EPUB'),
                      _buildInstructionRow('2. Nhập/paste văn bản muốn đánh dấu'),
                      _buildInstructionRow('3. Chọn màu highlight'),
                      _buildInstructionRow('4. Thêm ghi chú và lưu'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemBuilder: (context, index) {
        final highlight = _highlights[index];
        final color = _colorFromHex(highlight.color);
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleHighlightTap(highlight),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (highlight.note != null &&
                          highlight.note!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            highlight.note!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _detectedFormat == EbookFormat.epub
                            ? 'Chương ${highlight.pageNumber}'
                            : 'Trang ${highlight.pageNumber}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.grey[500],
                  onPressed: () => _handleEditHighlight(highlight),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.grey[500],
                  onPressed: () => _handleDeleteHighlight(highlight),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _highlights.length,
    );
  }

  Widget _buildInstructionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
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
    unawaited(_persistReadingProgress());
  }

  void _handleChapterTap(EbookChapter chapter, int index, bool isEpub) {
    setState(() {
      _showReaderMenu = false;
    });
    if (isEpub) {
      _openEpubChapter(index);
    } else {
      _navigateToPage(chapter.pageNumber);
    }
  }

  void _handleHighlightTap(EbookHighlight highlight) {
    setState(() {
      _showReaderMenu = false;
    });
    if (_detectedFormat == EbookFormat.epub) {
      if (_chapters.isEmpty) {
        return;
      }
      final targetIndex = (highlight.pageNumber - 1).clamp(
        0,
        _chapters.length - 1,
      );
      _openEpubChapter(targetIndex);
    } else {
      _navigateToPage(highlight.pageNumber);
    }
  }

  Future<void> _handleEditHighlight(EbookHighlight highlight) async {
    final noteController = TextEditingController(text: highlight.note ?? '');
    String selectedColorHex = highlight.color;

    final updatedHighlight = await showModalBottomSheet<EbookHighlight>(
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
                            'Chỉnh sửa đánh dấu',
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
                          highlight.text,
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
                            final updated = EbookHighlight(
                              id: highlight.id,
                              text: highlight.text,
                              pageNumber: highlight.pageNumber,
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                              createdAt: highlight.createdAt,
                              color: selectedColorHex,
                            );

                            Navigator.of(context).pop(updated);
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu thay đổi'),
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

    noteController.dispose();

    if (!mounted || updatedHighlight == null) {
      return;
    }

    await EbookSettingsService.updateHighlight(widget.title, updatedHighlight);
    if (!mounted) return;
    
    setState(() {
      final index = _highlights.indexWhere((h) => h.id == updatedHighlight.id);
      if (index != -1) {
        _highlights[index] = updatedHighlight;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật đánh dấu.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDeleteHighlight(EbookHighlight highlight) async {
    await EbookSettingsService.deleteHighlight(widget.title, highlight.id);
    if (!mounted) return;
    setState(() {
      _highlights.removeWhere((h) => h.id == highlight.id);
    });
  }

  Future<void> _handleExportHighlights() async {
    if (_highlights.isEmpty) return;

    // Show export format dialog
    final format = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Highlights'),
          content: const Text('Chọn định dạng file để export:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'text'),
              child: const Text('Text (.txt)'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'json'),
              child: const Text('JSON (.json)'),
            ),
          ],
        );
      },
    );

    if (format == null || !mounted) return;

    try {
      String content;
      String fileName;
      String mimeType;

      if (format == 'json') {
        content = await EbookSettingsService.exportHighlightsToJson(widget.title);
        fileName = '${widget.title}_highlights_${DateTime.now().millisecondsSinceEpoch}.json';
        mimeType = 'application/json';
      } else {
        content = await EbookSettingsService.exportHighlightsToText(widget.title);
        fileName = '${widget.title}_highlights_${DateTime.now().millisecondsSinceEpoch}.txt';
        mimeType = 'text/plain';
      }

      // Save to temporary file and share
      if (kIsWeb) {
        // For web, trigger download
        // Note: Web download requires additional setup, for now just show content
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export không được hỗ trợ trên web. Vui lòng sử dụng trên mobile/desktop.'),
          ),
        );
      } else {
        // For mobile/desktop, save and share
        final directory = await getApplicationDocumentsDirectory();
        final file = io.File('${directory.path}/$fileName');
        await file.writeAsString(content);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: mimeType)],
          subject: 'Highlights từ ${widget.title}',
          text: 'Export ${_highlights.length} highlights',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã export ${_highlights.length} highlights'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _closeReaderMenu() {
    setState(() => _showReaderMenu = false);
  }

  Widget _buildMainReader() {
    return Stack(
      children: [
        _buildReaderContent(),
        if (!widget.hideFloatingControls) _buildFloatingControls(),
      ],
    );
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
    // Áp dụng theme trước, sau đó mới áp dụng eye comfort filters
    return _applyEyeComfortFilters(content);
  }

  // ✅ PDF reader với Syncfusion
  Widget _buildPdfReader() {
    final backgroundColor = _getBackgroundColor();
    return Container(
      color: backgroundColor,
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
    final backgroundColor = _getBackgroundColor();
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: _settings.theme == 'dark'
            ? Brightness.dark
            : Brightness.light,
        scaffoldBackgroundColor: backgroundColor,
      ),
      child: SfPdfViewer.network(
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
          if (_isRestoringProgress) {
            _isRestoringProgress = false;
            return;
          }
          unawaited(_persistReadingProgress());
        },
      ),
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
      final backgroundColor = _getBackgroundColor();
      return Theme(
        data: Theme.of(context).copyWith(
          brightness: _settings.theme == 'dark'
              ? Brightness.dark
              : Brightness.light,
          scaffoldBackgroundColor: backgroundColor,
        ),
        child: SfPdfViewer.file(
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
            if (_isRestoringProgress) {
              _isRestoringProgress = false;
              return;
            }
            unawaited(_persistReadingProgress());
          },
        ),
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
    final backgroundColor = _getBackgroundColor();
    return Container(
      color: backgroundColor,
      child: _webViewController != null
          ? WebViewWidget(controller: _webViewController!)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildWebViewReader() {
    final backgroundColor = _getBackgroundColor();
    return Container(
      color: backgroundColor,
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
      case 'sepia':
        return const Color(0xFFF4ECD8);
      case 'light':
      default:
        return Colors.white;
    }
  }

  // Method để lấy màu text theo theme
  Color _getTextColor() {
    switch (_settings.theme) {
      case 'dark':
        return Colors.white;
      case 'sepia':
        return const Color(0xFF5B4636);
      case 'light':
      default:
        return Colors.black; // Đảm bảo màu đen cho chế độ sáng
    }
  }

  Color _colorFromHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.orangeAccent;
    }
  }

  Widget _applyEyeComfortFilters(Widget child) {
    if (!_settings.eyeComfortEnabled) {
      return child;
    }

    // Chế độ bảo vệ mắt chỉ hoạt động khi ở chế độ sáng
    if (_settings.theme != 'light') {
      return child;
    }

    final warmth = _settings.warmth.clamp(0.0, 1.0);
    final brightness = _settings.brightness.clamp(0.0, 1.0);
    // Giảm opacity để overlay không che phủ quá nhiều nội dung
    final warmOverlayOpacity = (warmth * 0.3).clamp(0.0, 0.4);
    final dimOpacity = ((1 - brightness) * 0.4).clamp(0.0, 0.4);

    // Chỉ áp dụng overlay khi cần thiết
    if (warmOverlayOpacity <= 0 && dimOpacity <= 0) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        // Warmth overlay - màu vàng ấm với opacity thấp (chỉ cho light mode)
        if (warmOverlayOpacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: warmOverlayOpacity,
                duration: const Duration(milliseconds: 250),
                child: Container(color: const Color(0xFFF4E1A1)),
              ),
            ),
          ),
        // Brightness overlay - làm tối với opacity thấp (chỉ cho light mode)
        if (dimOpacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: dimOpacity,
                duration: const Duration(milliseconds: 250),
                child: Container(color: Colors.black),
              ),
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

  Future<void> _showCreateHighlightSheet({String? initialColorHex}) async {
    final selectedText = _selectedPdfText ?? _selectedEpubText;
    if (!mounted) return;
    if (selectedText == null || selectedText.isEmpty) {
      return;
    }

    setState(() => _isHighlightSheetVisible = true);

    final noteController = TextEditingController();
    String selectedColorHex = initialColorHex ?? _settings.highlightColor;

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
                            selectedText,
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
                              final text = selectedText;
                              if (text.trim().isEmpty) {
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
      _selectedEpubText = null;
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
        // Refresh để hiển thị highlight màu
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _colorFromHex(highlight.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Đã lưu đánh dấu.'),
              ],
            ),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Xem',
              onPressed: () {
                setState(() {
                  _readerMenuTabIndex = 1;
                  _showReaderMenu = true;
                });
              },
            ),
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

  Future<void> _persistReadingProgress() async {
    if (_isRestoringProgress) {
      return;
    }

    final progress = EbookReadingProgress(
      pageNumber: _currentPage,
      chapterIndex: _detectedFormat == EbookFormat.epub
          ? _currentChapterIndex
          : null,
      updatedAt: DateTime.now(),
    );

    await EbookSettingsService.saveReadingProgress(widget.title, progress);
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
            onPressed: () => setState(() {
              _readerMenuTabIndex = 1;
              _showReaderMenu = true;
            }),
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
            onPressed: () => setState(() {
              _readerMenuTabIndex = 0;
              _showReaderMenu = true;
            }),
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
    final textColor = _getTextColor(); // Sử dụng method helper

    if (_chapters.isEmpty) {
      return Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: Text(
          'Không thể tải nội dung EPUB.',
          style: TextStyle(color: textColor),
        ),
      );
    }

    final chapter =
        _chapters[_currentChapterIndex.clamp(0, _chapters.length - 1)];
    final content = chapter.content?.trim();

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.orange.withOpacity(0.3),
          selectionHandleColor: Colors.orange,
          cursorColor: Colors.orange,
        ),
      ),
      child: Container(
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
                  Stack(
                    children: [
                      // HTML content với highlights
                      Html(
                        data: _injectHighlightsToHtml(
                          _injectTextColorToHtml(content, textColor),
                          textColor,
                        ),
                        style: {
                          'html': Style(
                            color: textColor,
                            backgroundColor: backgroundColor,
                          ),
                          'body': Style(
                            fontFamily: _settings.fontFamily,
                            fontSize: FontSize(_settings.fontSize),
                            lineHeight: LineHeight(_settings.lineHeight),
                            color: textColor,
                            backgroundColor: backgroundColor,
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                          ),
                          'p': Style(
                            color: textColor,
                            margin: Margins.symmetric(vertical: 8),
                          ),
                          'div': Style(color: textColor),
                          'span': Style(color: textColor),
                          'h1': Style(
                            color: textColor,
                            fontSize: FontSize(_settings.fontSize + 8),
                          ),
                          'h2': Style(
                            color: textColor,
                            fontSize: FontSize(_settings.fontSize + 6),
                          ),
                          'h3': Style(
                            color: textColor,
                            fontSize: FontSize(_settings.fontSize + 4),
                          ),
                          'h4': Style(
                            color: textColor,
                            fontSize: FontSize(_settings.fontSize + 2),
                          ),
                          'h5': Style(color: textColor),
                          'h6': Style(color: textColor),
                          'li': Style(color: textColor),
                          'td': Style(color: textColor),
                          'th': Style(color: textColor),
                          'a': Style(color: textColor),
                          'strong': Style(color: textColor),
                          'em': Style(color: textColor),
                          'b': Style(color: textColor),
                          'i': Style(color: textColor),
                        },
                      ),
                      // Transparent layer để bắt long press
                      Positioned.fill(
                        child: GestureDetector(
                          onLongPressStart: (details) {
                            _showEpubTextSelectionMenu(details.globalPosition);
                          },
                          child: Container(color: Colors.transparent),
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

  // Helper method để inject CSS vào HTML để đảm bảo màu text được áp dụng
  String _injectTextColorToHtml(String html, Color textColor) {
    // Chuyển đổi Color sang hex string
    final hexColor = '#${textColor.value.toRadixString(16).substring(2)}';

    // Tạo CSS style để override màu text
    final styleTag =
        '''
    <style>
      * {
        color: $hexColor !important;
      }
      body, p, div, span, h1, h2, h3, h4, h5, h6, li, td, th, a, strong, em, b, i {
        color: $hexColor !important;
      }
      .highlight {
        padding: 2px 0;
        border-radius: 2px;
      }
    </style>
    ''';

    // Inject style vào đầu HTML nếu chưa có
    if (html.contains('<head>')) {
      return html.replaceFirst('<head>', '<head>$styleTag');
    } else if (html.contains('<html>')) {
      return html.replaceFirst('<html>', '<html><head>$styleTag</head>');
    } else {
      return '$styleTag$html';
    }
  }

  // Inject highlights vào HTML content
  String _injectHighlightsToHtml(String html, Color textColor) {
    // Lấy highlights cho chapter hiện tại
    final currentChapterHighlights = _highlights
        .where((h) => h.pageNumber == _currentPage)
        .toList();

    if (currentChapterHighlights.isEmpty) {
      return html;
    }

    String result = html;
    
    // Thêm màu highlight cho mỗi đoạn text
    for (var highlight in currentChapterHighlights) {
      final textToHighlight = highlight.text;
      if (textToHighlight.isEmpty) continue;

      // Escape special characters trong regex
      final escapedText = textToHighlight
          .replaceAll(RegExp(r'[.*+?^${}()|[\]\\]'), r'\$&');
      
      // Tạo pattern để tìm text (không phân biệt whitespace)
      final pattern = escapedText.replaceAll(RegExp(r'\s+'), r'\\s+');
      
      try {
        // Wrap text với span có màu highlight
        result = result.replaceAll(
          RegExp(pattern, multiLine: true, dotAll: true),
          '<span class="highlight" style="background-color: ${highlight.color};">$textToHighlight</span>',
        );
      } catch (e) {
        // Nếu regex fail, thử replace đơn giản
        if (result.contains(textToHighlight)) {
          result = result.replaceFirst(
            textToHighlight,
            '<span class="highlight" style="background-color: ${highlight.color};">$textToHighlight</span>',
          );
        }
      }
    }

    return result;
  }

  // Hiển thị menu để chọn và highlight text trong EPUB
  void _showEpubTextSelectionMenu(Offset position) {
    showDialog(
      context: context,
      builder: (context) {
        final textController = TextEditingController();
        return AlertDialog(
          title: const Text('Tạo highlight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập đoạn văn bạn muốn đánh dấu:'),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Nhập hoặc paste văn bản...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = textController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(context);
                  _selectedEpubText = text;
                  _showCreateHighlightSheet();
                }
              },
              child: const Text('Tiếp tục'),
            ),
          ],
        );
      },
    );
  }

  void _toggleTheme() async {
    // Chuyển đổi theme theo thứ tự: light -> sepia -> dark -> light
    String newTheme;
    switch (_settings.theme) {
      case 'light':
        newTheme = 'sepia';
        break;
      case 'sepia':
        newTheme = 'dark';
        break;
      case 'dark':
        newTheme = 'light';
        break;
      default:
        newTheme = 'light';
    }

    final newSettings = _settings.copyWith(theme: newTheme);
    await _updateSettings(newSettings);

    // Force rebuild để áp dụng theme ngay lập tức
    if (mounted) {
      setState(() {});
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EbookSettingsDialog(
        currentSettings: _settings,
        onSettingsChanged: (newSettings) async {
          await _updateSettings(newSettings);
        },
        onSettingsChangedRealTime: (newSettings) async {
          // Cập nhật settings real-time để preview ngay
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
    unawaited(_persistReadingProgress());
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
