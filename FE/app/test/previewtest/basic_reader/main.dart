import 'package:flutter/material.dart';

import 'read_book.dart';
import 'package:provider/provider.dart';
import 'models/reader_state.dart';
import 'types.dart';

void main() {
  runApp(const _PreviewTestApp());
}

class _PreviewTestApp extends StatefulWidget {
  const _PreviewTestApp();

  @override
  State<_PreviewTestApp> createState() => _PreviewTestAppState();
}

class _PreviewTestAppState extends State<_PreviewTestApp> {
  DisplayMode _displayMode = DisplayMode.light;

  @override
  Widget build(BuildContext context) {
    const String defaultPath = 'test/previewtest/test_epub.epub';

    final themeMode = _displayMode == DisplayMode.light
        ? ThemeMode.light
        : ThemeMode.dark;

    return ChangeNotifierProvider(
      create: (_) => ReaderState(
        initialDisplayMode: _displayMode,
        initialReadingMode: ReadingMode.continuous,

        // onExternalToggleDisplayMode: _toggleDisplayMode,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Preview Test',
        themeMode: themeMode,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.dark,
        ),
        home: ReadBook(filePath: defaultPath),
      ),
    );
  }
}
