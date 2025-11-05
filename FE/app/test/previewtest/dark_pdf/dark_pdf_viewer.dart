import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'pdf_dark_renderer.dart';

enum DarkPdfMode { continuous, page }

class DarkPdfViewer extends StatefulWidget {
  const DarkPdfViewer({super.key, required this.filePath, this.dark = false, this.mode = DarkPdfMode.page});

  final String filePath;
  final bool dark;
  final DarkPdfMode mode;

  @override
  State<DarkPdfViewer> createState() => _DarkPdfViewerState();
}

class _DarkPdfViewerState extends State<DarkPdfViewer> {
  PdfDocument? _doc;
  PdfDarkRenderer? _renderer;
  bool _loading = true;
  Object? _error;
  final Map<int, Uint8List> _cacheDark = <int, Uint8List>{};
  final Map<int, Uint8List> _cacheLight = <int, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final path = await _resolvePath(widget.filePath);
      final doc = await PdfDocument.openFile(path);
      _doc = doc;
      _renderer = PdfDarkRenderer(doc);
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _doc?.close().ignore();
    super.dispose();
  }

  Future<String> _resolvePath(String input) async {
    final f = File(input);
    if (await f.exists()) return f.path;
    final data = await rootBundle.load(input);
    final tmp = await getTemporaryDirectory();
    final out = File(p.join(tmp.path, p.basename(input)));
    await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return out.path;
  }

  Future<Uint8List> _getPage(int index, {required bool dark}) async {
    final pageNo = index + 1;
    final cache = dark ? _cacheDark : _cacheLight;
    if (cache.containsKey(pageNo)) return cache[pageNo]!;
    final bytes = await _renderer!.renderPagePng(pageNumber: pageNo, darkMode: dark);
    cache[pageNo] = bytes;
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Lỗi mở PDF: $_error'));
    final doc = _doc!;
    final dark = widget.dark;
    final isPage = widget.mode == DarkPdfMode.page;

    final body = isPage
        ? PageView.builder(
            itemCount: doc.pagesCount,
            controller: PageController(),
            itemBuilder: (context, index) {
              return FutureBuilder<Uint8List>(
                future: _getPage(index, dark: dark),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return DecoratedBox(
                    decoration: BoxDecoration(color: dark ? Colors.black : Colors.white),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 4,
                      child: Center(child: Image.memory(snap.data!, gaplessPlayback: true)),
                    ),
                  );
                },
              );
            },
          )
        : ListView.builder(
            itemCount: doc.pagesCount,
            itemBuilder: (context, index) {
              return FutureBuilder<Uint8List>(
                future: _getPage(index, dark: dark),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const SizedBox(
                      height: 400,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Container(
                    color: dark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: Image.memory(snap.data!, gaplessPlayback: true)),
                  );
                },
              );
            },
          );

    return body;
  }
}



