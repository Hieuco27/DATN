import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import 'models/reader_state.dart';
import 'models/reader_model.dart';
import 'widgets/annotation_drawer.dart';
import 'widgets/empty_hint.dart';
import 'widgets/epub_dark_themed.dart';
import 'types.dart';

// enums moved to types.dart

class ReadBook extends StatefulWidget {
  const ReadBook({
    super.key,
    required this.filePath,
    this.displayMode = DisplayMode.light,
    this.onToggleDisplayMode,
  });

  final String?
  filePath; // Accepts null to allow showing a placeholder when no file is provided
  final DisplayMode displayMode;
  final VoidCallback? onToggleDisplayMode;

  @override
  State<ReadBook> createState() => _ReadBookState();
}

class _ReadBookState extends State<ReadBook> {
  // PDF
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfKey = GlobalKey();
  String? _lastSelectedText;
  final List<AnnotationItem> _annotations = <AnnotationItem>[];

  @override
  void initState() {
    super.initState();
    // No-op: file resolving is handled by ReaderModel provider
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReaderModel>(
      create: (_) => ReaderModel(initialPath: widget.filePath),
      child: Builder(builder: (context) => _buildWithModel(context)),
    );
  }

  Widget _buildWithModel(BuildContext context) {
    final state = context.watch<ReaderState>();
    final model = context.watch<ReaderModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText()),
        actions: <Widget>[
          // Toggle reading mode
          PopupMenuButton<ReadingMode>(
            tooltip: 'Chế độ đọc',
            onSelected: (mode) => state.setReadingMode(mode),
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
          PopupMenuButton<DisplayMode>(
            tooltip: 'Chế độ hiển thị',
            icon: Icon(_getDisplayModeIcon(state.displayMode)),
            onSelected: (_) => state.cycleDisplayMode(),
            itemBuilder: (context) => [
              PopupMenuItem<DisplayMode>(
                value: DisplayMode.light,
                child: Row(
                  children: [
                    Icon(
                      Icons.light_mode,
                      color: state.displayMode == DisplayMode.light
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Sáng'),
                  ],
                ),
              ),
              PopupMenuItem<DisplayMode>(
                value: DisplayMode.dark,
                child: Row(
                  children: [
                    Icon(
                      Icons.dark_mode,
                      color: state.displayMode == DisplayMode.dark
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tối'),
                  ],
                ),
              ),
              PopupMenuItem<DisplayMode>(
                value: DisplayMode.night,
                child: Row(
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      color: state.displayMode == DisplayMode.night
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Đêm (Chống ánh sáng xanh)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: state.readingMode == ReadingMode.continuous
                ? 'Chế độ lật trang'
                : 'Chế độ cuộn liên tục',
            icon: Icon(
              state.readingMode == ReadingMode.continuous
                  ? Icons.flip
                  : Icons.view_agenda,
            ),
            onPressed: () => state.toggleReadingMode(),
          ),
          IconButton(
            tooltip: 'Đi đến trang...',
            icon: const Icon(Icons.find_in_page),
            onPressed: () async {
              final page = await _askPage(context);
              if (page == null) return;
              if (model.isPdf) {
                _pdfController.jumpToPage(page);
              } else if (model.isEpub) {
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
              if (model.isPdf) {
                _pdfKey.currentState?.openBookmarkView();
              } else if (model.isEpub) {
                _openEpubToc(context);
              }
            },
          ),
          if (model.isPdf) ...[
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
                    AnnotationItem(type: type, text: _lastSelectedText!.trim()),
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
      drawer: AnnotationDrawer(annotations: _annotations),
      body: _buildBody(model),
    );
  }

  IconData _getDisplayModeIcon(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.light:
        return Icons.light_mode;
      case DisplayMode.dark:
        return Icons.dark_mode;
      case DisplayMode.night:
        return Icons.nightlight_round;
    }
  }

  String _titleText() {
    final model = context.read<ReaderModel>();
    final path = model.resolvedPath ?? widget.filePath;
    if (path == null) return 'Preview Test';
    final name = p.basename(path);
    return model.isPdf
        ? 'PDF: $name'
        : model.isEpub
        ? 'EPUB: $name'
        : name;
  }

  Widget _buildBody(ReaderModel model) {
    final state = context.watch<ReaderState>();
    if (model.inputPath == null) {
      return const EmptyHint(onSelectDemo: null);
    }
    if (model.isResolving) {
      return const Center(child: CircularProgressIndicator());
    }
    if (model.resolveError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Không thể mở file: ${model.resolveError}'),
        ),
      );
    }
    if (model.resolvedPath == null) {
      return const Center(child: Text('Không tìm thấy tệp.'));
    }
    if (model.isPdf) {
      // Wrap SfPdfViewer với key động để force rebuild khi displayMode thay đổi
      final view = KeyedSubtree(
        key: ValueKey('pdf_wrapper_${state.displayMode.name}'),
        child: SfPdfViewer.file(
          File(model.resolvedPath!),
          key: _pdfKey,
          controller: _pdfController,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          pageLayoutMode: state.readingMode == ReadingMode.continuous
              ? PdfPageLayoutMode.continuous
              : PdfPageLayoutMode.single,
          onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
            if (details.selectedText != null &&
                details.selectedText!.trim().isNotEmpty) {
              _lastSelectedText = details.selectedText;
            }
          },
        ),
      );
      return _buildDisplayModeWrapper(epubWidget: view);
    }
    if (model.isEpub) {
      final controller = model.epubController;
      if (controller == null) {
        return const Center(child: Text('Không thể tải EPUB.'));
      }
      // Use cached EpubView instance to avoid rebuilds on display mode changes
      final Widget epub = model.epubViewCached;
      if (state.readingMode == ReadingMode.singlePage) {
        // Thử mô phỏng lật trang bằng PageScrollPhysics để cuộn theo "trang".
        return _buildDisplayModeWrapper(
          epubWidget: EpubDarkThemed(
            enabled: state.displayMode != DisplayMode.light,
            epubWidget: ScrollConfiguration(
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
          ),
        );
      }
      return _buildDisplayModeWrapper(
        epubWidget: EpubDarkThemed(
          enabled: state.displayMode != DisplayMode.light,
          epubWidget: epub,
        ),
      );
    }
    return const Center(child: Text('Định dạng không được hỗ trợ.'));
  }

  // Drawer moved to widgets/annotation_drawer.dart

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
    final controller = context.read<ReaderModel>().epubController;
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

  Widget _buildDisplayModeWrapper({required Widget epubWidget}) {
    final state = context.watch<ReaderState>();
    final isDark = state.displayMode == DisplayMode.dark;
    final isNight = state.displayMode == DisplayMode.night;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always keep the same parent type to avoid detaching children on mode switch
        Container(
          color: isDark || isNight ? Colors.black : null,
          child: epubWidget,
        ),
        // Blue light filter overlay - use opacity toggle instead of swapping widget types
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: isNight ? 0.3 : 0.0,
              child: Container(
                color: const Color(0x33FFE5B4), // Sepia tint
              ),
            ),
          ),
        ),
      ],
    );
  }
}
