import 'package:flutter/material.dart';

import 'dark_pdf_viewer.dart';

void main() {
  runApp(const _DarkPdfDemoApp());
}

class _DarkPdfDemoApp extends StatefulWidget {
  const _DarkPdfDemoApp({super.key});

  @override
  State<_DarkPdfDemoApp> createState() => _DarkPdfDemoAppState();
}

class _DarkPdfDemoAppState extends State<_DarkPdfDemoApp> {
  bool _darkContent = true;
  DarkPdfMode _mode = DarkPdfMode.page;

  @override
  Widget build(BuildContext context) {
    const String pdfPath = 'test/previewtest/test_pdf.pdf';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dark PDF Preview',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo, brightness: Brightness.dark),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dark PDF (Advanced)'),
          actions: <Widget>[
            IconButton(
              tooltip: _darkContent ? 'Tắt dark trong PDF' : 'Bật dark trong PDF',
              icon: Icon(_darkContent ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => setState(() => _darkContent = !_darkContent),
            ),
            PopupMenuButton<DarkPdfMode>(
              tooltip: 'Chế độ đọc',
              initialValue: _mode,
              onSelected: (m) => setState(() => _mode = m),
              itemBuilder: (context) => const <PopupMenuEntry<DarkPdfMode>>[
                PopupMenuItem(value: DarkPdfMode.page, child: Text('Lật trang (PageView)')),
                PopupMenuItem(value: DarkPdfMode.continuous, child: Text('Đọc dọc (ListView)')),
              ],
            ),
          ],
        ),
        body: DarkPdfViewer(
          filePath: pdfPath,
          dark: _darkContent,
          mode: _mode,
        ),
      ),
    );
  }
}


