import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

enum EbookFormat { pdf, epub, mobi, txt, html }

class EbookReaderService {
  static Future<EbookFormat> detectFormat(String url) async {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.pdf')) return EbookFormat.pdf;
    if (path.endsWith('.epub')) return EbookFormat.epub;
    if (path.endsWith('.mobi')) return EbookFormat.mobi;
    if (path.endsWith('.txt')) return EbookFormat.txt;
    if (path.endsWith('.html') || path.endsWith('.htm'))
      return EbookFormat.html;

    // Fallback: kiểm tra content-type
    try {
      final response = await http.head(Uri.parse(url));
      final contentType = response.headers['content-type']?.toLowerCase();

      if (contentType?.contains('pdf') == true) return EbookFormat.pdf;
      if (contentType?.contains('epub') == true) return EbookFormat.epub;
      if (contentType?.contains('html') == true) return EbookFormat.html;
    } catch (e) {
      print('Error detecting format: $e');
    }

    return EbookFormat.pdf; // Default fallback
  }

  static Future<String> downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    final directory = await getTemporaryDirectory();
    final fileName = url.split('/').last;
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}
