import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/reader_model.dart';
import '../models/reader_state.dart';
import '../types.dart';
import 'annotation_drawer.dart';

AppBar buildReaderAppBar({
  required BuildContext context,
  required String title,
  required ReaderState state,
  required ReaderModel model,
   PdfViewerController? pdfController,
  required GlobalKey<SfPdfViewerState> pdfKey,
  required Future<int?> Function(BuildContext) askPage,
  required void Function(AnnotationItem) addAnnotation,
  required VoidCallback openEpubToc,
  required VoidCallback toggleReadingMode,
  required IconData Function(DisplayMode) getDisplayModeIcon,
  String? lastSelectedText,
}) {
  return AppBar(
    title: Text(title),
    actions: <Widget>[
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
        icon: Icon(getDisplayModeIcon(state.displayMode)),
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
        onPressed: toggleReadingMode,
      ),
      IconButton(
        tooltip: 'Đi đến trang...',
        icon: const Icon(Icons.find_in_page),
        onPressed: () async {
          final page = await askPage(context);
          if (page == null) return;
          if (model.isPdf) {
            pdfController?.jumpToPage(page);
          } else if (model.isEpub) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('EPUB không hỗ trợ nhảy theo số trang cố định.'),
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
            pdfKey.currentState?.openBookmarkView();
          } else if (model.isEpub) {
            openEpubToc();
          }
        },
      ),
      if (model.isPdf) ...[
        PopupMenuButton<String>(
          tooltip: 'Chú thích',
          onSelected: (value) {
            if (lastSelectedText == null || lastSelectedText.trim().isEmpty) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hãy chọn đoạn văn bản trước.'),
                  ),
                );
              }
              return;
            }
            final type = value == 'highlight'
                ? AnnotationType.highlight
                : AnnotationType.underline;
            addAnnotation(AnnotationItem(type: type, text: lastSelectedText.trim()));
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
  );
}


