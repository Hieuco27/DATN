import 'dart:io';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';

class ReaderModel extends ChangeNotifier {
  ReaderModel({String? initialPath}) {
    if (initialPath != null && initialPath.isNotEmpty) {
      setInputPath(initialPath);
    }
  }

  String? _inputPath;
  String? _resolvedPath;
  bool _isResolving = false;
  Object? _resolveError;
  EpubController? _epubController;
  Widget? _epubViewCached;

  String? get inputPath => _inputPath;
  String? get resolvedPath => _resolvedPath;
  bool get isResolving => _isResolving;
  Object? get resolveError => _resolveError;
  EpubController? get epubController => _epubController;
  Widget get epubViewCached {
    if (_epubViewCached != null) return _epubViewCached!;
    if (_epubController == null) return const SizedBox.shrink();
    _epubViewCached = EpubView(
      key: const ValueKey('epub_view'),
      controller: _epubController!,
      onDocumentLoaded: (_) {},
      onChapterChanged: (_) {},
    );
    return _epubViewCached!;
  }

  bool get isPdf => _ext == '.pdf';
  bool get isEpub => _ext == '.epub';

  String get _ext {
    final path = _resolvedPath ?? _inputPath ?? '';
    return p.extension(path).toLowerCase();
  }

  Future<void> setInputPath(String? path) async {
    _inputPath = path;
    notifyListeners();
    await _resolveFilePath();
  }

  Future<void> _resolveFilePath() async {
    final inputPath = _inputPath;
    if (inputPath == null || inputPath.isEmpty) return;
    _isResolving = true;
    notifyListeners();
    try {
      final file = File(inputPath);
      if (await file.exists()) {
        _resolvedPath = file.path;
      } else {
        final bytes = await rootBundle.load(inputPath);
        final tempDir = await getTemporaryDirectory();
        final outPath = p.join(tempDir.path, p.basename(inputPath));
        final outFile = File(outPath);
        await outFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        _resolvedPath = outFile.path;
      }
      if (isEpub) {
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
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }
}


