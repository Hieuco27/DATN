import 'dart:io';
import 'dart:typed_data';
// Removed unused viewer imports
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

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

  // Chuẩn hóa EPUB: loại bỏ các href có '../' gây lỗi parser, trả về bytes mới
  static Uint8List sanitizeEpubBytes(Uint8List originalBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(originalBytes);
      final Archive fixed = Archive();

      // Tạo map các file có sẵn trong archive để kiểm tra
      final availableFiles = <String>{};
      for (final file in archive) {
        if (file.isFile) {
          availableFiles.add(file.name);
        }
      }

      // Debug: In danh sách file có trong EPUB
      print('📦 EPUB Archive contains ${availableFiles.length} files:');
      for (final filename in availableFiles.take(10)) {
        print('  - $filename');
      }
      if (availableFiles.length > 10) {
        print('  ... and ${availableFiles.length - 10} more files');
      }

      // Bước 1: Copy tất cả HTML files từ root vào OEBPS nếu chưa có
      final htmlFilesAtRoot = <String>[];
      for (final file in archive) {
        if (file.isFile) {
          final name = file.name;
          // Tìm HTML files ở root level (không có folder prefix)
          if ((name.endsWith('.html') || name.endsWith('.xhtml')) &&
              !name.contains('/')) {
            htmlFilesAtRoot.add(name);
          }
        }
      }

      // Sao chép HTML files ở root vào OEBPS folder
      for (final rootFile in htmlFilesAtRoot) {
        final targetPath = 'OEBPS/$rootFile';
        if (!availableFiles.contains(targetPath)) {
          final file = archive.findFile(rootFile);
          if (file != null && file.isFile) {
            fixed.addFile(
              ArchiveFile(
                targetPath,
                file.size,
                Uint8List.fromList(file.content as List<int>),
              ),
            );
            availableFiles.add(targetPath);
            print('📋 Copied $rootFile -> $targetPath');
          }
        }
      }

      for (final file in archive) {
        if (file.isFile) {
          final name = file.name;
          final data = file.content as List<int>;
          if (name.endsWith('.opf') ||
              name.endsWith('.ncx') ||
              name.endsWith('.xhtml') ||
              name.endsWith('.html')) {
            final content = String.fromCharCodes(data);
            String normalized = content;

            // Thay thế các pattern '../' phổ biến trong href/src
            normalized = normalized
                .replaceAll('OEBPS/../', '')
                .replaceAll('OPS/../', '')
                .replaceAll('Text/../', '')
                .replaceAll('..//', '')
                .replaceAll('../', '');

            // Tìm tất cả href/src trỏ đến file
            final regex = RegExp(
              '''(href|src)=["'\"]([^"'\s]+\\.html?)["'\"]''',
              caseSensitive: false,
            );
            normalized = normalized.replaceAllMapped(regex, (match) {
              final attr = match.group(1);
              final path = match.group(2);
              if (path == null) return match.group(0)!;

              // Kiểm tra nếu file có tồn tại trong archive
              String normalizedPath = path;
              // Thử một số variations phổ biến
              if (!availableFiles.contains(normalizedPath)) {
                // Thử file không có OEBPS prefix
                if (normalizedPath.startsWith('OEBPS/')) {
                  final withoutOEBPS = normalizedPath.substring(7);
                  if (availableFiles.contains(withoutOEBPS)) {
                    normalizedPath = withoutOEBPS;
                  } else if (availableFiles.contains('OEBPS/$withoutOEBPS')) {
                    normalizedPath = 'OEBPS/$withoutOEBPS';
                  }
                } else {
                  // Thử thêm OEBPS prefix nếu file ở root
                  if (availableFiles.contains('OEBPS/$normalizedPath')) {
                    normalizedPath = 'OEBPS/$normalizedPath';
                  }
                }
                // Nếu vẫn không tìm thấy, giữ nguyên để tránh lỗi
              }

              return '$attr="$normalizedPath"';
            });

            fixed.addFile(
              ArchiveFile(
                name,
                normalized.length,
                Uint8List.fromList(normalized.codeUnits),
              ),
            );
          } else {
            fixed.addFile(
              ArchiveFile(name, data.length, Uint8List.fromList(data)),
            );
          }
        }
      }
      final encoded = ZipEncoder().encode(fixed);
      print('✅ EPUB sanitization successful, created ${fixed.length} files');
      return Uint8List.fromList(encoded!);
    } catch (e, stackTrace) {
      print('❌ Error sanitizing EPUB: $e');
      print('Stack trace: $stackTrace');
      // Nếu có lỗi, trả lại bytes gốc để không chặn luồng
      return originalBytes;
    }
  }
}
