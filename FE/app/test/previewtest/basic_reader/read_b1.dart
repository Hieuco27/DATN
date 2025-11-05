import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

enum ReadingMode { singlePage, continuous }

enum ReadingColorMode { normal, dark, grayscale, warm }

class ReadBook extends StatefulWidget {
  const ReadBook({
    super.key,
    required this.filePath,
    this.isDark = false,
    this.onToggleTheme,
  });

  final String?
  filePath; // Accepts null to allow showing a placeholder when no file is provided
  final bool isDark;
  final VoidCallback? onToggleTheme;

  @override
  State<ReadBook> createState() => _ReadBookState();
}

class _ReadBookState extends State<ReadBook> {
  ReadingMode _mode = ReadingMode.continuous;
  ReadingColorMode _colorMode = ReadingColorMode.normal;

  // PDF
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();
  String? _lastSelectedText;
  final List<_Annotation> _annotations = <_Annotation>[];

  // EPUB
  EpubController? _epubController;

  bool get _isPdf => _ext == '.pdf';
  bool get _isEpub => _ext == '.epub';

  String get _ext {
    final path = _resolvedPath ?? widget.filePath ?? '';
    return p.extension(path).toLowerCase();
  }

  String? _resolvedPath;
  bool _isResolving = false;
  Object? _resolveError;

  Future<void> _resolveFilePath() async {
    final inputPath = widget.filePath;
    if (inputPath == null || inputPath.isEmpty) return;
    _isResolving = true;
    setState(() {});
    try {
      final file = File(inputPath);
      if (await file.exists()) {
        _resolvedPath = file.path;
      } else {
        // Treat as asset path: load and copy to temp file
        final bytes = await rootBundle.load(inputPath);
        final tempDir = await getTemporaryDirectory();
        final outPath = p.join(tempDir.path, p.basename(inputPath));
        final outFile = File(outPath);
        await outFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        _resolvedPath = outFile.path;
      }
      // Initialize EPUB controller if needed
      if (_isEpub) {
        _epubController?.dispose();
        _epubController = EpubController(
          document: EpubDocument.openFile(File(_resolvedPath!)),
        );
      }
      _resolveError = null;
    } catch (e) {
      _resolveError = e;
    } finally {
      _isResolving = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _resolveFilePath();
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText()),
        actions: <Widget>[
          PopupMenuButton<ReadingColorMode>(
            tooltip: 'Chế độ màu đọc',
            onSelected: (m) => setState(() => _colorMode = m),
            itemBuilder: (context) => const <PopupMenuEntry<ReadingColorMode>>[
              PopupMenuItem(
                value: ReadingColorMode.normal,
                child: Text('Bình thường'),
              ),
              PopupMenuItem(
                value: ReadingColorMode.dark,
                child: Text('Night mode (tối)'),
              ),
              PopupMenuItem(
                value: ReadingColorMode.grayscale,
                child: Text('Kindle (xám)'),
              ),
              PopupMenuItem(
                value: ReadingColorMode.warm,
                child: Text('Bảo vệ mắt (ấm)'),
              ),
            ],
            icon: const Icon(Icons.palette),
          ),
          // Toggle reading mode
          PopupMenuButton<ReadingMode>(
            tooltip: 'Chế độ đọc',
            onSelected: (mode) => setState(() => _mode = mode),
            itemBuilder: (context) => const <PopupMenuEntry<ReadingMode>>[
              PopupMenuItem<ReadingMode>(
                value: ReadingMode.continuous,
                child: Text('Đọc dọc (cuộn liên tục)'),
              ),
              PopupMenuItem<ReadingMode>(
                value: ReadingMode.singlePage,
                child: Text('Lật trang (theo trang)'),
              ),
            ],
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: widget.isDark ? 'Tắt Dark mode' : 'Bật Dark mode',
            icon: Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: _mode == ReadingMode.continuous
                ? 'Chế độ lật trang'
                : 'Chế độ cuộn liên tục',
            icon: Icon(
              _mode == ReadingMode.continuous ? Icons.flip : Icons.view_agenda,
            ),
            onPressed: () => setState(() {
              _mode = _mode == ReadingMode.continuous
                  ? ReadingMode.singlePage
                  : ReadingMode.continuous;
            }),
          ),
          IconButton(
            tooltip: 'Đi đến trang...',
            icon: const Icon(Icons.find_in_page),
            onPressed: () async {
              final page = await _askPage(context);
              if (page == null) return;
              if (_isPdf) {
                _pdfController.jumpToPage(page);
              } else if (_isEpub) {
                // EPUB không có khái niệm trang cố định; hiển thị thông báo.
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'EPUB không hỗ trợ nhảy theo số trang cố định.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Mục lục',
            icon: const Icon(Icons.menu_book),
            onPressed: () {
              if (_isPdf) {
                _pdfKey.currentState?.openBookmarkView();
              } else if (_isEpub) {
                _openEpubToc(context);
              }
            },
          ),
          if (_isPdf) ...[
            PopupMenuButton<String>(
              tooltip: 'Chú thích',
              onSelected: (value) {
                if (_lastSelectedText == null ||
                    _lastSelectedText!.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hãy chọn đoạn văn bản trước.'),
                    ),
                  );
                  return;
                }
                final type = value == 'highlight'
                    ? AnnotationType.highlight
                    : AnnotationType.underline;
                setState(() {
                  _annotations.add(
                    _Annotation(type: type, text: _lastSelectedText!.trim()),
                  );
                });
              },
              itemBuilder: (context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'highlight',
                  child: Text('Đánh dấu (Highlight)'),
                ),
                PopupMenuItem<String>(
                  value: 'underline',
                  child: Text('Gạch chân (Underline)'),
                ),
              ],
            ),
          ],
        ],
      ),
      drawer: _buildAnnotationDrawer(),
      body: _buildBody(),
    );
  }

  String _titleText() {
    final path = _resolvedPath ?? widget.filePath;
    if (path == null) return 'Preview Test';
    final name = p.basename(path);
    return _isPdf
        ? 'PDF: $name'
        : _isEpub
        ? 'EPUB: $name'
        : name;
  }

  Widget _buildBody() {
    if (widget.filePath == null) {
      return _EmptyHint(onSelectDemo: () {});
    }
    if (_isResolving) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_resolveError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Không thể mở file: $_resolveError'),
        ),
      );
    }
    if (_resolvedPath == null) {
      return const Center(child: Text('Không tìm thấy tệp.'));
    }
    if (_isPdf) {
      final view = SfPdfViewer.file(
        File(_resolvedPath!),
        key: _pdfKey,
        controller: _pdfController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        pageLayoutMode: _mode == ReadingMode.continuous
            ? PdfPageLayoutMode.continuous
            : PdfPageLayoutMode.single,
        onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
          if (details.selectedText != null &&
              details.selectedText!.trim().isNotEmpty) {
            _lastSelectedText = details.selectedText;
          }
        },
      );
      return _wrapWithReadingColors(child: view);
    }
    if (_isEpub) {
      final controller = _epubController;
      if (controller == null) {
        return const Center(child: Text('Không thể tải EPUB.'));
      }
      // EpubView cuộn theo nội dung; mô phỏng chế độ "single" bằng PageScrollPhysics.
      final Widget epub = EpubView(
        controller: controller,
        onDocumentLoaded: (_) {},
        onChapterChanged: (_) {},
      );
      if (_mode == ReadingMode.singlePage) {
        // Thử mô phỏng lật trang bằng PageScrollPhysics để cuộn theo "trang".
        return _wrapWithReadingColors(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior(),
            child: PrimaryScrollController(
              controller: PrimaryScrollController.of(context),
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (n) {
                  n.disallowIndicator();
                  return false;
                },
                child: SingleChildScrollView(
                  physics: const PageScrollPhysics(),
                  child: SizedBox(width: double.infinity, child: epub),
                ),
              ),
            ),
          ),
        );
      }
      return _wrapWithReadingColors(child: epub);
    }
    return const Center(child: Text('Định dạng không được hỗ trợ.'));
  }

  Drawer _buildAnnotationDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chú thích',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            if (_annotations.isEmpty)
              const Expanded(child: Center(child: Text('Chưa có chú thích.')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _annotations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ann = _annotations[index];
                    return ListTile(
                      leading: Icon(
                        ann.type == AnnotationType.highlight
                            ? Icons.highlight
                            : Icons.format_underline,
                      ),
                      title: Text(
                        ann.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(context).maybePop();
                        // For a full solution, store page/cfi to navigate.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đi đến vị trí chú thích chưa được gắn kết.',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<int?> _askPage(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đi đến trang'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Nhập số trang'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('HỦY'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                Navigator.of(context).pop(value);
              },
              child: const Text('ĐI'),
            ),
          ],
        );
      },
    );
    return result;
  }

  Future<void> _openEpubToc(BuildContext context) async {
    final controller = _epubController;
    if (controller == null) return;
    final _ = await controller.tableOfContents();
    if (!context.mounted) return;
    // Hiển thị mục lục có sẵn từ epub_view, tự xử lý điều hướng theo CFI.
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mục lục'),
        content: SizedBox(
          width: 400,
          height: 500,
          child: EpubViewTableOfContents(controller: controller),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }

  Widget _wrapWithReadingColors({required Widget child}) {
    // Base background per mode
    Color? bg;
    switch (_colorMode) {
      case ReadingColorMode.dark:
        bg = Colors.black;
        break;
      case ReadingColorMode.grayscale:
        bg = const Color(0xFF101010);
        break;
      case ReadingColorMode.warm:
        bg = const Color(0xFF2A241A); // very dark warm background
        break;
      case ReadingColorMode.normal:
        bg = widget.isDark ? Colors.black : null;
        break;
    }

    // Color filter matrices
    const grayscale = <double>[
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    // Slight dim for dark mode without inversion
    const darkDim = <double>[
      0.85,
      0,
      0,
      0,
      0,
      0,
      0.85,
      0,
      0,
      0,
      0,
      0,
      0.85,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    // Sepia-like warm tone
    const sepia = <double>[
      0.393,
      0.769,
      0.189,
      0,
      0,
      0.349,
      0.686,
      0.168,
      0,
      0,
      0.272,
      0.534,
      0.131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];

    ColorFilter? filter;
    switch (_colorMode) {
      case ReadingColorMode.dark:
        filter = const ColorFilter.matrix(darkDim);
        break;
      case ReadingColorMode.grayscale:
        filter = const ColorFilter.matrix(grayscale);
        break;
      case ReadingColorMode.warm:
        filter = const ColorFilter.matrix(sepia);
        break;
      case ReadingColorMode.normal:
        filter = null;
        break;
    }

    // For EPUB, also enforce text theme when not normal
    Widget wrapped = child;
    if (_isEpub && _colorMode != ReadingColorMode.normal) {
      final base = Theme.of(context);
      final isWarm = _colorMode == ReadingColorMode.warm;
      final isDark =
          _colorMode == ReadingColorMode.dark ||
          _colorMode == ReadingColorMode.grayscale ||
          isWarm;
      final themed = base.copyWith(
        brightness: isDark ? Brightness.dark : base.brightness,
        colorScheme: base.colorScheme.copyWith(
          brightness: isDark ? Brightness.dark : base.brightness,
        ),
        textTheme: base.textTheme.apply(
          bodyColor: isWarm ? const Color(0xFFFFF3CF) : Colors.white,
          displayColor: isWarm ? const Color(0xFFFFF3CF) : Colors.white,
        ),
      );
      wrapped = Theme(data: themed, child: wrapped);
    }

    if (filter != null) {
      wrapped = ColorFiltered(colorFilter: filter, child: wrapped);
    }

    return Container(color: bg, child: wrapped);
  }
}

enum AnnotationType { highlight, underline }

class _Annotation {
  _Annotation({required this.type, required this.text});

  final AnnotationType type;
  final String text;
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.onSelectDemo});

  final VoidCallback onSelectDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.menu_book, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Chưa có file. Hãy truyền 1 file PDF/EPUB vào ReadBook hoặc chỉnh main.dart để chọn đường dẫn thử nghiệm.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSelectDemo,
              icon: const Icon(Icons.file_open),
              label: const Text('Hướng dẫn chạy thử'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpubDarkThemed extends StatelessWidget {
  const _EpubDarkThemed({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final base = Theme.of(context);
    final dark = base.copyWith(
      brightness: Brightness.dark,
      colorScheme: base.colorScheme.copyWith(brightness: Brightness.dark),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
    return Theme(data: dark, child: child);
  }
}
