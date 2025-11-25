import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
// Removed unused viewer imports
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:book_tech/features/auth/data/models/ebook_model.dart';

const bool _enableEpubRepairVerboseLogs = false;

void _epubRepairLog(String message) {
  if (!_enableEpubRepairVerboseLogs) {
    return;
  }
  debugPrint(message);
}

enum EbookFormat { pdf, epub, mobi, txt, html }

class _ReaderThemePalette {
  final String background;
  final String text;
  final String link;
  final String muted;

  const _ReaderThemePalette({
    required this.background,
    required this.text,
    required this.link,
    required this.muted,
  });
}

class EbookReaderService {
  static Future<EbookFormat> detectFormat(String url) async {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.pdf')) {
      return EbookFormat.pdf;
    }
    if (path.endsWith('.epub')) {
      return EbookFormat.epub;
    }
    if (path.endsWith('.mobi')) {
      return EbookFormat.mobi;
    }
    if (path.endsWith('.txt')) {
      return EbookFormat.txt;
    }
    if (path.endsWith('.html') || path.endsWith('.htm')) {
      return EbookFormat.html;
    }

    // Fallback: kiểm tra content-type
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      final contentType = response.headers['content-type']?.toLowerCase();

      if (contentType?.contains('pdf') == true) {
        return EbookFormat.pdf;
      }
      if (contentType?.contains('epub') == true) {
        return EbookFormat.epub;
      }
      if (contentType?.contains('html') == true) {
        return EbookFormat.html;
      }
    } catch (e) {}

    return EbookFormat.pdf; // Default fallback
  }

  /// Lấy thư mục lưu trữ ebooks lâu dài (không bị xóa khi app đóng)
  static Future<Directory> _getEbooksDirectory() async {
    // Sử dụng Application Documents Directory thay vì Temporary Directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final ebooksDir = Directory('${appDocDir.path}/ebooks');

    // Tạo thư mục nếu chưa tồn tại
    if (!await ebooksDir.exists()) {
      await ebooksDir.create(recursive: true);
    }

    return ebooksDir;
  }

  static Future<String> downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));

    // ✅ Thêm kiểm tra status code
    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải file: HTTP ${response.statusCode}. URL: $url',
      );
    }

    // ✅ Kiểm tra response body không rỗng
    if (response.bodyBytes.isEmpty) {
      throw Exception('File tải về trống. URL: $url');
    }

    // ✅ Sử dụng thư mục Documents thay vì Temporary để lưu lâu dài
    final ebooksDirectory = await _getEbooksDirectory();
    var fileName = url.split('/').last;

    // ✅ Xử lý trường hợp fileName rỗng hoặc không hợp lệ
    if (fileName.isEmpty || !fileName.contains('.')) {
      // Tạo tên file mặc định dựa trên format
      final format = await detectFormat(url);
      fileName = 'ebook.${format.name}';
    }

    // ✅ Tạo tên file unique bằng cách hash URL để tránh trùng lặp
    // Sử dụng hash của URL để đảm bảo mỗi URL có một file riêng
    // Tạo hash đơn giản từ URL bằng cách dùng hashCode
    final urlHashCode = url.hashCode.abs();
    // Chuyển hashCode sang hex string (12 ký tự)
    final urlHash = urlHashCode
        .toRadixString(16)
        .padLeft(12, '0')
        .substring(0, 12);
    final fileExtension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '';
    final baseFileName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    // Tạo tên file: baseName_hash.extension (ví dụ: ebook_a1b2c3d4e5f6.pdf)
    final uniqueFileName = '${baseFileName}_$urlHash$fileExtension';
    final filePath = '${ebooksDirectory.path}/$uniqueFileName';
    final file = File(filePath);

    // ✅ Kiểm tra file đã tồn tại chưa (nếu có thì không cần tải lại)
    if (await file.exists()) {
      return file.path;
    }

    // ✅ Ghi file vào thư mục Documents
    await file.writeAsBytes(response.bodyBytes);

    return file.path;
  }

  /// Xóa file ebook đã tải về
  static Future<bool> deleteEbookFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // Silently fail
      return false;
    }
  }

  /// Lấy danh sách tất cả các file ebook đã tải về
  static Future<List<FileSystemEntity>> getDownloadedEbooks() async {
    try {
      final ebooksDirectory = await _getEbooksDirectory();
      if (await ebooksDirectory.exists()) {
        final files = ebooksDirectory.listSync();
        // Lọc chỉ lấy file, bỏ qua thư mục
        return files
            .where((file) => FileSystemEntity.isFileSync(file.path))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Xóa tất cả các file ebook đã tải về
  static Future<int> clearAllDownloadedEbooks() async {
    try {
      final ebooks = await getDownloadedEbooks();
      int deletedCount = 0;
      for (final ebook in ebooks) {
        try {
          await ebook.delete();
          deletedCount++;
        } catch (e) {
          // Silently continue
        }
      }
      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  static _ReaderThemePalette _resolveThemePalette(String theme) {
    switch (theme.toLowerCase()) {
      case 'dark':
        return const _ReaderThemePalette(
          background: '#0F1115',
          text: '#F5F5F7',
          link: '#8AB4F8',
          muted: '#3A3D42',
        );
      case 'sepia':
        return const _ReaderThemePalette(
          background: '#F4ECD8',
          text: '#5B4636',
          link: '#A66B2B',
          muted: '#CBB899',
        );
      default:
        return const _ReaderThemePalette(
          background: '#FFFFFF',
          text: '#1F2933',
          link: '#1E88E5',
          muted: '#CBD2D9',
        );
    }
  }

  static String _applyReaderSettingsToHtml(
    String html,
    EbookSettings settings,
  ) {
    final normalizedHtml = _normalizeChapterHtml(html);
    final palette = _resolveThemePalette(settings.theme);
    final css = _buildReaderCss(settings, palette);
    return _injectCssIntoHtml(normalizedHtml, css);
  }

  static String _buildReaderCss(
    EbookSettings settings,
    _ReaderThemePalette palette,
  ) {
    final bool eyeComfort = settings.eyeComfortEnabled;
    final double rawBrightness = settings.brightness.clamp(0.0, 1.2);
    final double brightnessFactor = eyeComfort
        ? math.max(0.3, math.min(1.2, rawBrightness))
        : 1.0;
    final double textAdjustment = brightnessFactor < 0.85
        ? math.min(1.35, 1 + (0.85 - brightnessFactor) * 0.9)
        : 1.0;
    final double backgroundAdjustment = brightnessFactor > 1.05
        ? math.min(1.2, brightnessFactor)
        : 1.0;

    final String backgroundColor = _adjustHexBrightness(
      palette.background,
      backgroundAdjustment,
    );
    final String textColor = _adjustHexBrightness(palette.text, textAdjustment);

    final double warmthValue = eyeComfort
        ? settings.warmth.clamp(0.0, 1.0)
        : 0.0;

    final filters = <String>[];
    if ((brightnessFactor - 1.0).abs() > 0.01) {
      filters.add('brightness(${brightnessFactor.toStringAsFixed(2)})');
    }
    if (warmthValue > 0) {
      final double warmthStrength = math.max(
        0.15,
        math.min(0.85, 0.25 + warmthValue * 0.55),
      );
      filters.add('sepia(${warmthStrength.toStringAsFixed(2)})');
      final double saturation = math.max(
        0.65,
        math.min(1.15, 1.05 - warmthValue * 0.25),
      );
      filters.add('saturate(${saturation.toStringAsFixed(2)})');
      final double hueRotate = -12 * warmthValue;
      filters.add('hue-rotate(${hueRotate.toStringAsFixed(2)}deg)');
    }

    final filterCss = filters.isNotEmpty
        ? 'filter: ${filters.join(' ')} !important;'
        : '';

    return '''
:root {
  color-scheme: ${settings.theme.toLowerCase() == 'dark' ? 'dark' : 'light'};
}
body, html {
  margin: 0 !important;
  padding: 0 !important;
  background: $backgroundColor !important;
  color: $textColor !important;
  font-family: "${settings.fontFamily}", sans-serif !important;
  font-size: ${settings.fontSize}px !important;
  line-height: ${settings.lineHeight} !important;
  $filterCss
}
p, span, li, div, section, article {
  color: $textColor !important;
}
a {
  color: ${palette.link} !important;
}
img, video, svg, canvas {
  max-width: 100% !important;
  height: auto !important;
}
table {
  width: 100% !important;
  border-collapse: collapse !important;
}
table, th, td {
  border-color: ${palette.muted} !important;
}
blockquote {
  border-left: 4px solid ${palette.muted} !important;
  margin-left: 0 !important;
  padding-left: 16px !important;
}
mark {
  background-color: rgba(255, 214, 64, 0.4) !important;
  color: $textColor !important;
  padding: 0 0.1em;
}
h1, h2, h3, h4, h5, h6 {
  font-family: "${settings.fontFamily}", sans-serif !important;
  color: $textColor !important;
}
''';
  }

  static String _injectCssIntoHtml(String html, String css) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return '''
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8" />
<style id="ebook-reader-theme">
$css
</style>
</head>
<body class="ebook-reader-body">
</body>
</html>
''';
    }

    final sanitized = trimmed.replaceAll(
      RegExp(
        '<style[^>]+id=["\']ebook-reader-theme["\'][^>]*>[\\s\\S]*?</style>',
        caseSensitive: false,
      ),
      '',
    );
    final styleTag = '<style id="ebook-reader-theme">\n$css\n</style>';
    final headRegex = RegExp(r'<head[^>]*>', caseSensitive: false);
    final htmlRegex = RegExp(r'<html[^>]*>', caseSensitive: false);
    final bodyRegex = RegExp(r'<body[^>]*>', caseSensitive: false);

    if (headRegex.hasMatch(sanitized)) {
      return sanitized.replaceFirstMapped(
        headRegex,
        (match) => '${match.group(0)}\n$styleTag',
      );
    }
    if (htmlRegex.hasMatch(sanitized)) {
      return sanitized.replaceFirstMapped(
        htmlRegex,
        (match) => '${match.group(0)}\n<head>\n$styleTag\n</head>',
      );
    }
    if (bodyRegex.hasMatch(sanitized)) {
      return '''
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8" />
$styleTag
</head>
$sanitized
</html>
''';
    }
    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8" />
$styleTag
</head>
<body class="ebook-reader-body">
$sanitized
</body>
</html>
''';
  }

  static String _normalizeChapterHtml(String html) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return '<p>(Không có nội dung)</p>';
    }
    return trimmed;
  }

  static String _adjustHexBrightness(String hexColor, double factor) {
    final rgb = _hexToRgb(hexColor);
    if (rgb == null) {
      return hexColor;
    }
    final adjusted = rgb
        .map(
          (channel) => math.max(0, math.min(255, (channel * factor).round())),
        )
        .toList();
    return _rgbToHex(adjusted);
  }

  static List<int>? _hexToRgb(String hex) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 3) {
      cleaned = cleaned.split('').map((c) => '$c$c').join();
    }
    if (cleaned.length != 6) {
      return null;
    }
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) {
      return null;
    }
    return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF];
  }

  static String _rgbToHex(List<int> rgb) {
    final buffer = StringBuffer('#');
    for (final channel in rgb) {
      final clamped = channel.clamp(0, 255).toInt();
      buffer.write(clamped.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  // Helper function to get items that need to be removed (for creating placeholders)
  static List<Map<String, String>> _getItemsToRemove(
    String opfContent,
    Set<String> availableFiles,
  ) {
    final result = <Map<String, String>>[];
    try {
      final manifestItemRegex1 = RegExp(
        r'''<item[^>]+id=["']([^"']+)["'][^>]+href=["']([^"']+)["']''',
        caseSensitive: false,
        multiLine: false,
      );
      final manifestItemRegex2 = RegExp(
        r'''<item[^>]+href=["']([^"']+)["'][^>]+id=["']([^"']+)["']''',
        caseSensitive: false,
        multiLine: false,
      );

      final itemData = <String, Map<String, String>>{};
      manifestItemRegex1.allMatches(opfContent).forEach((match) {
        final id = match.group(1)!;
        final href = match.group(2)!;
        itemData[id] = {'href': href, 'fullMatch': match.group(0)!};
      });
      manifestItemRegex2.allMatches(opfContent).forEach((match) {
        final href = match.group(1)!;
        final id = match.group(2)!;
        itemData.putIfAbsent(
          id,
          () => {'href': href, 'fullMatch': match.group(0)!},
        );
      });

      itemData.forEach((id, data) {
        final href = data['href']!;
        String normalizedHref = href;
        if (normalizedHref.startsWith('/')) {
          normalizedHref = normalizedHref.substring(1);
        }
        final withoutOEBPS = normalizedHref.startsWith('OEBPS/')
            ? normalizedHref.substring(7)
            : normalizedHref;
        final filename = normalizedHref.split('/').last;

        final possiblePaths = <String>{
          normalizedHref,
          withoutOEBPS,
          'OEBPS/$normalizedHref',
          'OEBPS/$withoutOEBPS',
          filename,
        };

        bool fileExists = false;
        for (final path in possiblePaths) {
          if (availableFiles.contains(path)) {
            fileExists = true;
            break;
          }
        }

        if (!fileExists && (id.contains('/') || id.contains('\\'))) {
          final idPath = id.replaceAll('\\', '/');
          final possibleIdPaths = [idPath, 'OEBPS/$idPath'];
          for (final path in possibleIdPaths) {
            if (availableFiles.contains(path)) {
              fileExists = true;
              break;
            }
          }
        }

        if (!fileExists) {
          result.add({'id': id, 'href': href});
        }
      });
    } catch (e) {
      print('   ⚠️ Error getting items to remove: $e');
    }
    return result;
  }

  // Clean up OPF manifest: remove items that reference non-existent files
  // Returns: Map với key là cleaned OPF content và value là map của IDs cần duplicate files
  static Map<String, dynamic> _cleanupOpfManifestWithInfo(
    String opfContent,
    Set<String> availableFiles,
  ) {
    final result = <String, dynamic>{
      'cleaned': opfContent,
      'idToActualPath': <String, String>{},
    };
    try {
      // Tìm tất cả manifest items - cải thiện regex để match nhiều format hơn
      // Pattern 1: id trước, href sau
      final manifestItemRegex1 = RegExp(
        r'''<item[^>]+id=["']([^"']+)["'][^>]+href=["']([^"']+)["']''',
        caseSensitive: false,
        multiLine: false,
      );
      // Pattern 2: href trước, id sau
      final manifestItemRegex2 = RegExp(
        r'''<item[^>]+href=["']([^"']+)["'][^>]+id=["']([^"']+)["']''',
        caseSensitive: false,
        multiLine: false,
      );
      // Pattern 3: multiline (id trước) - cho trường hợp item tag bị split trên nhiều dòng
      final manifestItemRegex3 = RegExp(
        r'''<item[^>]*id=["']([^"']+)["'][\s\S]*?href=["']([^"']+)["'][^>]*>''',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      );
      // Pattern 4: multiline (href trước)
      final manifestItemRegex4 = RegExp(
        r'''<item[^>]*href=["']([^"']+)["'][\s\S]*?id=["']([^"']+)["'][^>]*>''',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      );

      final itemsToRemove = <String>[]; // List of IDs to remove
      final itemData =
          <String, Map<String, String>>{}; // ID -> {href, fullMatch}

      // Match pattern 1: id trước
      final matches1 = manifestItemRegex1.allMatches(opfContent);
      print('   📝 Pattern 1 matches: ${matches1.length}');
      matches1.forEach((match) {
        final id = match.group(1)!;
        final href = match.group(2)!;
        itemData[id] = {'href': href, 'fullMatch': match.group(0)!};
      });

      // Match pattern 2: href trước (id và href đổi chỗ)
      final matches2 = manifestItemRegex2.allMatches(opfContent);
      print('   📝 Pattern 2 matches: ${matches2.length}');
      matches2.forEach((match) {
        final href = match.group(1)!;
        final id = match.group(2)!;
        // Chỉ thêm nếu chưa có (pattern 1 đã match)
        itemData.putIfAbsent(
          id,
          () => {'href': href, 'fullMatch': match.group(0)!},
        );
      });

      // Match pattern 3: multiline (id trước)
      final matches3 = manifestItemRegex3.allMatches(opfContent);
      print('   📝 Pattern 3 (multiline) matches: ${matches3.length}');
      matches3.forEach((match) {
        final id = match.group(1)!;
        final href = match.group(2)!;
        itemData.putIfAbsent(
          id,
          () => {'href': href, 'fullMatch': match.group(0)!},
        );
      });

      // Match pattern 4: multiline (href trước)
      final matches4 = manifestItemRegex4.allMatches(opfContent);
      print('   📝 Pattern 4 (multiline) matches: ${matches4.length}');
      matches4.forEach((match) {
        final href = match.group(1)!;
        final id = match.group(2)!;
        itemData.putIfAbsent(
          id,
          () => {'href': href, 'fullMatch': match.group(0)!},
        );
      });

      print('   📦 Total unique manifest items found: ${itemData.length}');

      // Map để lưu ID -> actual file path (để update href sau)
      final idToActualPath = <String, String>{};

      itemData.forEach((id, data) {
        final href = data['href']!;
        print('   🔍 Checking manifest item: ID="$id", href="$href"');

        // Normalize href path (similar to normalizeFilePath logic)
        String normalizedHref = href;
        // Remove leading slash
        if (normalizedHref.startsWith('/')) {
          normalizedHref = normalizedHref.substring(1);
        }
        // Remove OEBPS prefix if present (we'll check both variants)
        final withoutOEBPS = normalizedHref.startsWith('OEBPS/')
            ? normalizedHref.substring(7)
            : normalizedHref;

        // Extract filename for searching in Images/Text folders
        final filename = normalizedHref.split('/').last;

        // Try different path variations - comprehensive search
        // Build comprehensive list of possible paths
        final possiblePaths = <String>{
          normalizedHref,
          withoutOEBPS,
          'OEBPS/$normalizedHref',
          'OEBPS/$withoutOEBPS',
        };

        // ✅ QUAN TRỌNG: Nếu href không có OEBPS prefix, thử tìm trong OEBPS folder
        // Ví dụ: titlepage.xhtml có thể ở OEBPS/titlepage.xhtml
        if (!normalizedHref.startsWith('OEBPS/')) {
          possiblePaths.add('OEBPS/$normalizedHref');
          // Cũng thử trong các subfolder phổ biến
          possiblePaths.addAll([
            'OEBPS/Text/$normalizedHref',
            'OEBPS/text/$normalizedHref',
            'OEBPS/Contents/$normalizedHref',
            'OEBPS/contents/$normalizedHref',
            'OEBPS/Content/$normalizedHref',
            'OEBPS/content/$normalizedHref',
          ]);
        }

        // ✅ Xử lý các file trong contents/ folder
        if (normalizedHref.contains('contents/') ||
            normalizedHref.contains('Contents/')) {
          // Giữ nguyên path có contents/
          possiblePaths.add(normalizedHref);
          // Thử không có contents/ prefix
          final withoutContents = normalizedHref.replaceAll(
            RegExp(r'contents?/', caseSensitive: false),
            '',
          );
          possiblePaths.addAll([
            withoutContents,
            'OEBPS/$withoutContents',
            'OEBPS/Text/$withoutContents',
            'OEBPS/text/$withoutContents',
          ]);
        }

        // Try in Images folder variations
        if (normalizedHref.contains('Images/') ||
            normalizedHref.contains('images/') ||
            id.contains('Images/') ||
            id.contains('images/')) {
          possiblePaths.addAll([
            'OEBPS/Images/$filename',
            'Images/$filename',
            'OEBPS/images/$filename',
            'images/$filename',
            filename,
          ]);
        }

        // Try in Text folder variations
        if (normalizedHref.contains('Text/') ||
            normalizedHref.contains('text/') ||
            id.contains('Text/') ||
            id.contains('text/')) {
          possiblePaths.addAll([
            'OEBPS/Text/$filename',
            'Text/$filename',
            'OEBPS/text/$filename',
            'text/$filename',
            filename,
          ]);
        }

        // Try in Fonts folder variations (kể cả typo onts)
        if (normalizedHref.contains('fonts/') ||
            normalizedHref.contains('Fonts/') ||
            normalizedHref.contains('onts/') ||
            id.contains('fonts/') ||
            id.contains('Fonts/') ||
            id.contains('onts/')) {
          possiblePaths.addAll([
            'OEBPS/fonts/$filename',
            'fonts/$filename',
            'OEBPS/Fonts/$filename',
            'Fonts/$filename',
            'OEBPS/onts/$filename', // Fix typo
            'onts/$filename', // Fix typo
            // Thử cả path không có OEBPS prefix
            filename,
          ]);
        }

        // Always try just filename
        possiblePaths.add(filename);

        // ✅ Xử lý các file CSS và các file không có OEBPS prefix
        if (filename.endsWith('.css') ||
            filename.endsWith('.xhtml') ||
            filename.endsWith('.html') ||
            filename.endsWith('.ncx') ||
            filename.endsWith('.jpeg') ||
            filename.endsWith('.jpg') ||
            filename.endsWith('.png')) {
          // Thử tìm ở root level và trong OEBPS
          possiblePaths.addAll([
            filename, // Root level
            'OEBPS/$filename', // Trong OEBPS
            'OEBPS/Text/$filename', // Trong OEBPS/Text
            'OEBPS/text/$filename',
            'OEBPS/Contents/$filename', // Trong OEBPS/Contents
            'OEBPS/contents/$filename',
          ]);
        }

        // Also try searching by filename in common folders if not found
        if (!availableFiles.contains(normalizedHref)) {
          final commonFolders = [
            'fonts',
            'Fonts',
            'images',
            'Images',
            'css',
            'CSS',
            'Text',
            'text',
            'Contents',
            'contents',
            'Content',
            'content',
          ];
          for (final folder in commonFolders) {
            possiblePaths.addAll([
              'OEBPS/$folder/$filename',
              '$folder/$filename',
            ]);
          }
        }

        // Check if file exists in archive - TÌM ACTUAL PATH
        String? actualFilePath;
        for (final path in possiblePaths) {
          if (availableFiles.contains(path)) {
            actualFilePath = path;
            print('      ✅ Found file at: "$path"');
            break;
          }
        }

        // Also try case-insensitive matching for filename and full path
        if (actualFilePath == null) {
          final lowerFilename = filename.toLowerCase();
          final lowerHref = normalizedHref.toLowerCase();
          for (final availableFile in availableFiles) {
            final lowerAvailable = availableFile.toLowerCase();
            if (lowerAvailable.endsWith(lowerFilename) ||
                lowerAvailable == lowerHref ||
                lowerAvailable.contains(lowerFilename)) {
              actualFilePath = availableFile;
              print(
                '      ✅ Found file via case-insensitive: "$availableFile"',
              );
              break;
            }
          }
        }

        // Try matching by ID if it looks like a path
        if (actualFilePath == null && (id.contains('/') || id.contains('\\'))) {
          final idPath = id.replaceAll('\\', '/');
          final possibleIdPaths = [
            idPath,
            'OEBPS/$idPath',
            idPath.replaceFirst('OEBPS/', ''),
            'OEBPS/Images/${idPath.split('/').last}',
            'Images/${idPath.split('/').last}',
          ];
          for (final path in possibleIdPaths) {
            if (availableFiles.contains(path)) {
              actualFilePath = path;
              print('      ✅ Found file via ID path: "$id" -> "$path"');
              break;
            }
          }
        }

        // Try finding file by ID directly if ID is filename-like
        if (actualFilePath == null && !id.contains('/') && !id.contains('\\')) {
          // ID might be just the filename
          for (final availableFile in availableFiles) {
            if (availableFile.toLowerCase().endsWith(id.toLowerCase()) ||
                availableFile.toLowerCase().contains(id.toLowerCase())) {
              actualFilePath = availableFile;
              print(
                '      ✅ Found file via ID match: "$id" -> "$availableFile"',
              );
              break;
            }
          }
        }

        if (actualFilePath == null) {
          itemsToRemove.add(id);
          print('   🗑️ Will remove: ID="$id", href="$href" (file not found)');
          // Log some sample paths tried for debugging
          final samplePaths = possiblePaths.take(5).toList();
          print('      Sample paths tried: ${samplePaths.join(", ")}...');
        } else {
          // Lưu actual path để update href sau
          idToActualPath[id] = actualFilePath;
          // Calculate relative path from OEBPS folder for href (vì OPF nằm trong OEBPS)
          String relativePath = actualFilePath;
          if (relativePath.startsWith('OEBPS/')) {
            relativePath = relativePath.substring(7); // Remove OEBPS prefix
          }
          print(
            '   ✅ File exists: ID="$id" -> actual="$actualFilePath", href will be="$relativePath"',
          );
        }
      });

      if (itemsToRemove.isNotEmpty) {
        print(
          '   📊 Found ${itemData.length} manifest items, ${itemsToRemove.length} to remove:',
        );
        for (final id in itemsToRemove) {
          print('      - "$id"');
        }
      } else {
        print('   ℹ️ No invalid manifest items found to remove');
      }

      // Update href trong manifest items để match với actual file paths
      if (idToActualPath.isNotEmpty) {
        String updated = opfContent;

        idToActualPath.forEach((id, actualPath) {
          // Calculate relative path from OEBPS folder (vì OPF nằm trong OEBPS)
          String relativePath = actualPath;
          if (relativePath.startsWith('OEBPS/')) {
            relativePath = relativePath.substring(7); // Remove OEBPS prefix
          }

          final escapedId = RegExp.escape(id);

          // Nếu ID là path (chứa "/") và không match với actual path structure,
          // log warning vì có thể gây vấn đề với epub readers sử dụng ID để tìm file
          if ((id.contains('/') || id.contains('\\')) &&
              id != relativePath &&
              id != actualPath) {
            print(
              '      ⚠️ WARNING: ID "$id" is a path but doesn\'t match actual structure',
            );
            print(
              '         Actual file: "$actualPath", relative: "$relativePath"',
            );
            print(
              '         Some EPUB readers may fail to locate files using this ID.',
            );
          }

          // Tìm và update href trong manifest items
          // Pattern 1: id trước, href sau
          final updatePattern1 = RegExp(
            '''(<item[^>]+id=["']$escapedId["'][^>]+href=["'])([^"']+)(["'][^>]*>)''',
            caseSensitive: false,
          );
          updated = updated.replaceAllMapped(updatePattern1, (match) {
            final oldHref = match.group(2)!;
            if (oldHref != relativePath) {
              return '${match.group(1)}$relativePath${match.group(3)}';
            }
            return match.group(0)!;
          });

          // Pattern 2: href trước, id sau
          final updatePattern2 = RegExp(
            '''(<item[^>]+href=["'])([^"']+)(["'][^>]+id=["']$escapedId["'][^>]*>)''',
            caseSensitive: false,
          );
          updated = updated.replaceAllMapped(updatePattern2, (match) {
            final oldHref = match.group(2)!;
            if (oldHref != relativePath) {
              return '${match.group(1)}$relativePath${match.group(3)}';
            }
            return match.group(0)!;
          });

          // Pattern 3: multiline (id trước)
          final updatePattern3 = RegExp(
            '''(<item[^>]*id=["']$escapedId["'][\\s\\S]*?href=["'])([^"']+)(["'][^>]*>)''',
            caseSensitive: false,
            dotAll: true,
            multiLine: true,
          );
          updated = updated.replaceAllMapped(updatePattern3, (match) {
            final oldHref = match.group(2)!;
            if (oldHref != relativePath) {
              return '${match.group(1)}$relativePath${match.group(3)}';
            }
            return match.group(0)!;
          });

          // Pattern 4: multiline (href trước)
          final updatePattern4 = RegExp(
            '''(<item[^>]*href=["'])([^"']+)(["'][\\s\\S]*?id=["']$escapedId["'][^>]*>)''',
            caseSensitive: false,
            dotAll: true,
            multiLine: true,
          );
          updated = updated.replaceAllMapped(updatePattern4, (match) {
            final oldHref = match.group(2)!;
            if (oldHref != relativePath) {
              return '${match.group(1)}$relativePath${match.group(3)}';
            }
            return match.group(0)!;
          });
        });

        opfContent = updated;
      }

      if (itemsToRemove.isEmpty && idToActualPath.isEmpty) {
        result['cleaned'] = opfContent;
        result['idToActualPath'] = idToActualPath;
        return result; // No items to remove and no hrefs to update
      }

      print(
        '   🔧 Starting cleanup process for ${itemsToRemove.length} items...',
      );

      // Remove manifest items - multiple passes to ensure complete removal
      String cleaned = opfContent;
      int beforeLength = cleaned.length;

      for (final id in itemsToRemove) {
        final escapedId = RegExp.escape(id);

        // Multiple removal strategies to ensure complete removal
        // Strategy 1: Remove exact match if we have it
        final itemInfo = itemData[id];
        if (itemInfo != null) {
          final fullMatch = itemInfo['fullMatch'];
          if (fullMatch != null && cleaned.contains(fullMatch)) {
            cleaned = cleaned.replaceFirst(fullMatch, '');
          }
        }

        // Strategy 2: Remove using comprehensive regex patterns
        // Pattern 1: Complete item tag with closing tag (multiline)
        final itemRegex1Pattern =
            '<item[^>]*id\\s*=\\s*["\']$escapedId["\'][^>]*>.*?</item>';
        final itemRegex1 = RegExp(
          itemRegex1Pattern,
          caseSensitive: false,
          dotAll: true,
          multiLine: true,
        );
        cleaned = cleaned.replaceAll(itemRegex1, '');

        // Pattern 2: Self-closing item tag
        final itemRegex2Pattern =
            '<item[^>]*id\\s*=\\s*["\']$escapedId["\'][^>]*/>';
        final itemRegex2 = RegExp(
          itemRegex2Pattern,
          caseSensitive: false,
          multiLine: true,
        );
        cleaned = cleaned.replaceAll(itemRegex2, '');

        // Pattern 3: Opening tag only
        final itemRegex3Pattern =
            '<item[^>]*id\\s*=\\s*["\']$escapedId["\'][^>]*>';
        final itemRegex3 = RegExp(
          itemRegex3Pattern,
          caseSensitive: false,
          multiLine: true,
        );
        cleaned = cleaned.replaceAll(itemRegex3, '');

        // Pattern 4: Any line containing this ID as an item (fallback)
        final itemRegex4Pattern =
            '[^\\n]*<item[^>]*id\\s*=\\s*["\']$escapedId["\'][^\\n]*\\n?';
        final itemRegex4 = RegExp(
          itemRegex4Pattern,
          caseSensitive: false,
          multiLine: true,
        );
        cleaned = cleaned.replaceAll(itemRegex4, '');
      }

      // Clean up extra whitespace/newlines left after removal
      cleaned = cleaned.replaceAll(RegExp(r'\s*\n\s*\n\s*\n+'), '\n\n');

      final afterLength = cleaned.length;
      if (beforeLength != afterLength) {
        print(
          '   ✂️ Removed ${beforeLength - afterLength} characters from OPF',
        );
      }

      // Verify removal - check if any removed IDs still exist in cleaned OPF
      for (final id in itemsToRemove) {
        final escapedId = RegExp.escape(id);
        final checkPattern = '<item[^>]*id\\s*=\\s*["\']$escapedId["\']';
        final checkRegex = RegExp(checkPattern, caseSensitive: false);
        if (checkRegex.hasMatch(cleaned)) {
          print('   ⚠️ WARNING: ID "$id" still exists in OPF after cleanup!');
        } else {
          print('   ✅ Verified: ID "$id" successfully removed');
        }
      }

      // Remove spine itemrefs that reference removed manifest items
      for (final id in itemsToRemove) {
        final itemrefRegex = RegExp(
          '<itemref[^>]+idref=["\']${RegExp.escape(id)}["\'][^>]*>.*?</itemref>',
          caseSensitive: false,
          dotAll: true,
        );
        cleaned = cleaned.replaceAll(itemrefRegex, '');

        final itemrefRegex2 = RegExp(
          '<itemref[^>]+idref=["\']${RegExp.escape(id)}["\'][^>]*/>',
          caseSensitive: false,
        );
        cleaned = cleaned.replaceAll(itemrefRegex2, '');
      }

      // Remove guide references that point to removed items
      for (final id in itemsToRemove) {
        final guideRegex = RegExp(
          '<reference[^>]+href=["\'][^"\']*#?${RegExp.escape(id)}[^"\']*["\'][^>]*>.*?</reference>',
          caseSensitive: false,
          dotAll: true,
        );
        cleaned = cleaned.replaceAll(guideRegex, '');

        final guideRegex2 = RegExp(
          '<reference[^>]+href=["\'][^"\']*#?${RegExp.escape(id)}[^"\']*["\'][^>]*/>',
          caseSensitive: false,
        );
        cleaned = cleaned.replaceAll(guideRegex2, '');
      }

      result['cleaned'] = cleaned;
      result['idToActualPath'] = idToActualPath;
      return result;
    } catch (e) {
      result['cleaned'] = opfContent;
      return result;
    }
  }

  // Wrapper để maintain backward compatibility (có thể dùng trong tương lai)
  // ignore: unused_element
  static String _cleanupOpfManifest(
    String opfContent,
    Set<String> availableFiles,
  ) {
    final result = _cleanupOpfManifestWithInfo(opfContent, availableFiles);
    return result['cleaned'] as String;
  }

  // Helper để kiểm tra xem file có phải binary không
  static bool _isBinaryFile(String filename) {
    final lowerName = filename.toLowerCase();
    final binaryExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg',
      '.ttf',
      '.otf',
      '.woff',
      '.woff2',
      '.eot',
      '.mp3',
      '.mp4',
      '.ogg',
      '.wav',
      '.zip',
      '.rar',
      '.7z',
      '.pdf',
    ];
    return binaryExtensions.any((ext) => lowerName.endsWith(ext));
  }

  // Chuẩn hóa EPUB: loại bỏ các href có '../' gây lỗi parser, trả về bytes mới
  static Uint8List sanitizeEpubBytes(Uint8List originalBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(originalBytes);
      final Archive fixed = Archive();

      // Tạo map các file có sẵn trong archive để kiểm tra
      final availableFiles = <String>{};
      final processedFiles = <String>{}; // Track files đã được xử lý

      for (final file in archive) {
        if (file.isFile) {
          availableFiles.add(file.name);
        }
      }

      // Bước 1: Copy tất cả HTML files và assets từ root vào OEBPS nếu chưa có
      final rootAssets = <String>[];
      final assetExtensions = [
        '.html',
        '.xhtml',
        '.htm',
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.svg',
        '.webp',
        '.css',
        '.ttf',
        '.otf',
        '.woff',
        '.woff2',
        '.mp3',
        '.mp4',
        '.ogg',
        '.xml',
        '.js',
        '.ncx', // ✅ Thêm NCX files
      ];

      for (final file in archive) {
        if (file.isFile) {
          final name = file.name;
          // Tìm các file ở root level (không có folder prefix) và bỏ qua mimetype, META-INF
          if (!name.contains('/') &&
              name != 'mimetype' &&
              assetExtensions.any((ext) => name.toLowerCase().endsWith(ext))) {
            rootAssets.add(name);
            print('      📄 Found root asset: $name');
          }
        }
      }

      // ✅ Sao chép tất cả assets ở root vào OEBPS folder
      // Điều này đảm bảo các file như titlepage.xhtml, toc.ncx, CSS files có thể tìm thấy
      for (final rootFile in rootAssets) {
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
            processedFiles.add(targetPath); // Đánh dấu đã xử lý
            print(
              '      ✅ Copied root asset to OEBPS: $rootFile -> $targetPath',
            );
          }
        } else {
          print('      ℹ️ Root asset already exists in OEBPS: $targetPath');
        }
      }

      // ✅ QUAN TRỌNG: Giữ nguyên file ở root level để đảm bảo backward compatibility
      // Một số EPUB readers có thể tìm file ở root level
      for (final rootFile in rootAssets) {
        if (!processedFiles.contains(rootFile)) {
          final file = archive.findFile(rootFile);
          if (file != null && file.isFile) {
            fixed.addFile(
              ArchiveFile(
                rootFile,
                file.size,
                Uint8List.fromList(file.content as List<int>),
              ),
            );
            processedFiles.add(rootFile);
            print('      ✅ Kept root asset at root level: $rootFile');
          }
        }
      }

      // Bước 2: Xử lý và normalize tất cả các file
      for (final file in archive) {
        if (file.isFile) {
          final name = file.name;

          // Bỏ qua các file đã được copy (để tránh duplicate)
          if (processedFiles.contains(name)) {
            continue;
          }

          final data = file.content as List<int>;

          // Xử lý các file text cần normalize (OPF, NCX, HTML, XML, CSS)
          if (name.endsWith('.opf') ||
              name.endsWith('.ncx') ||
              name.endsWith('.xhtml') ||
              name.endsWith('.html') ||
              name.endsWith('.xml') ||
              name.endsWith('.css')) {
            // Try decode với UTF-8, cho phép malformed bytes để tránh crash
            String content;
            try {
              // ✅ QUAN TRỌNG: Luôn dùng allowMalformed: true để tránh FormatException
              // Điều này xử lý lỗi "Missing extension byte" khi decode UTF-8
              content = utf8.decode(data, allowMalformed: true);
            } catch (e) {
              // Nếu UTF-8 fail, thử Latin1
              try {
                content = latin1.decode(data);
                print(
                  '      ⚠️ File "$name" decoded as Latin1 instead of UTF-8: $e',
                );
              } catch (e2) {
                // Nếu cả 2 đều fail, dùng String.fromCharCodes (fallback)
                try {
                  // ✅ Filter out invalid characters để tránh FormatException
                  final validData = data
                      .where((byte) => byte >= 0 && byte <= 255)
                      .toList();
                  content = String.fromCharCodes(validData);
                  print(
                    '      ⚠️ File "$name" decoded with fromCharCodes (fallback)',
                  );
                } catch (e3) {
                  // Nếu vẫn fail, skip normalization cho file này
                  print(
                    '      ⚠️ Cannot decode file "$name" as text, skipping normalization: $e3',
                  );
                  if (!processedFiles.contains(name)) {
                    fixed.addFile(
                      ArchiveFile(name, data.length, Uint8List.fromList(data)),
                    );
                    processedFiles.add(name);
                  }
                  continue;
                }
              }
            }
            String normalized = content;

            // Helper function để normalize một path
            // isInOEBPS: true nếu file đang được normalize nằm trong OEBPS folder (như OPF, NCX)
            String normalizeFilePath(String path, {bool isInOEBPS = false}) {
              // Bỏ qua các URL absolute
              if (path.startsWith('http://') ||
                  path.startsWith('https://') ||
                  path.startsWith('data:') ||
                  path.startsWith('mailto:') ||
                  path.startsWith('#') ||
                  path.startsWith('javascript:')) {
                return path;
              }

              String normalizedPath = path;

              // Loại bỏ leading slash
              if (normalizedPath.startsWith('/')) {
                normalizedPath = normalizedPath.substring(1);
              }

              // Fix common typos in folder names
              // Trong hàm normalizeFilePath (khoảng dòng 867-890)
              normalizedPath = normalizedPath
                  .replaceAll('/onts/', '/fonts/') // Fix typo: onts -> fonts
                  .replaceAll(
                    '/mages/',
                    '/images/',
                  ) // Fix typo: mages -> images
                  .replaceAll(
                    'onts/',
                    'fonts/',
                  ) // Fix typo without leading slash
                  .replaceAll(
                    'mages/',
                    'images/',
                  ) // Fix typo without leading slash
                  .replaceAll(
                    'oc.ncx',
                    'toc.ncx',
                  ) // Fix typo: oc.ncx -> toc.ncx
                  .replaceAll(
                    'ttoc.ncx',
                    'toc.ncx',
                  ) // Fix typo: ttoc.ncx -> toc.ncx (THÊM DÒNG NÀY)
                  .replaceAll('/oc.ncx', '/toc.ncx') // Fix typo với slash
                  .replaceAll(
                    '/ttoc.ncx',
                    '/toc.ncx',
                  ) // Fix typo với slash (THÊM DÒNG NÀY)
                  .replaceAll(
                    'OEBPS/oc.ncx',
                    'OEBPS/toc.ncx',
                  ) // Fix typo với OEBPS
                  .replaceAll(
                    'OEBPS/ttoc.ncx',
                    'OEBPS/toc.ncx',
                  ); // Fix typo với OEBPS (THÊM DÒNG NÀY) // Fix typo without leading slash

              // Xử lý các pattern '../' - thay thế bằng empty trước
              normalizedPath = normalizedPath
                  .replaceAll('OEBPS/../', '')
                  .replaceAll('OPS/../', '')
                  .replaceAll('Text/../', '')
                  .replaceAll('Images/../', '')
                  .replaceAll('Styles/../', '')
                  .replaceAll('..//', '/');

              // Loại bỏ tất cả '../' còn lại
              while (normalizedPath.contains('../')) {
                normalizedPath = normalizedPath.replaceAll('../', '');
              }

              // QUAN TRỌNG: Nếu file đang normalize ở trong OEBPS folder (như OPF file),
              // thì paths trong đó phải là relative từ OEBPS folder, KHÔNG có OEBPS/ prefix
              if (isInOEBPS && normalizedPath.startsWith('OEBPS/')) {
                normalizedPath = normalizedPath.substring(
                  7,
                ); // Bỏ 'OEBPS/' prefix
              }

              // Loại bỏ duplicate OEBPS/ prefix
              while (normalizedPath.startsWith('OEBPS/OEBPS/')) {
                normalizedPath = normalizedPath.substring(7);
              }

              // Tìm file trong archive - KIỂM TRA THEO THỨ TỰ ĐÚNG
              String? foundPath;

              // Trường hợp 1: Path không có OEBPS prefix và tồn tại - GIỮ NGUYÊN
              if (!normalizedPath.startsWith('OEBPS/') &&
                  availableFiles.contains(normalizedPath)) {
                foundPath = normalizedPath;
              }
              // Trường hợp 2: Path có OEBPS prefix và tồn tại
              else if (normalizedPath.startsWith('OEBPS/') &&
                  availableFiles.contains(normalizedPath)) {
                // Nếu đang normalize trong OEBPS folder, bỏ prefix
                foundPath = isInOEBPS
                    ? normalizedPath.substring(7)
                    : normalizedPath;
              }
              // Trường hợp 3: Path không có prefix, thử thêm OEBPS prefix
              else if (!normalizedPath.startsWith('OEBPS/')) {
                if (availableFiles.contains('OEBPS/$normalizedPath')) {
                  // Nếu đang normalize trong OEBPS folder, giữ relative (không thêm prefix)
                  foundPath = isInOEBPS
                      ? normalizedPath
                      : 'OEBPS/$normalizedPath';
                }
              }
              // Trường hợp 4: Path có prefix nhưng không tìm thấy, thử bỏ prefix
              else if (normalizedPath.startsWith('OEBPS/')) {
                final withoutOEBPS = normalizedPath.substring(7);
                if (availableFiles.contains(withoutOEBPS)) {
                  foundPath = withoutOEBPS;
                } else if (availableFiles.contains('OEBPS/$withoutOEBPS')) {
                  foundPath = isInOEBPS ? withoutOEBPS : 'OEBPS/$withoutOEBPS';
                }
              }

              // Trường hợp 5: Tìm trong Images/Images folder
              if (foundPath == null) {
                if (!normalizedPath.startsWith('OEBPS/')) {
                  if (availableFiles.contains('OEBPS/Images/$normalizedPath')) {
                    foundPath = isInOEBPS
                        ? 'Images/$normalizedPath'
                        : 'OEBPS/Images/$normalizedPath';
                  } else if (availableFiles.contains(
                    'Images/$normalizedPath',
                  )) {
                    foundPath = 'Images/$normalizedPath';
                  }
                }
              }

              // Trường hợp 6: Tìm trong Fonts folder (fix typo onts -> fonts)
              if (foundPath == null) {
                final filename = normalizedPath.split('/').last;
                // Nếu path có "onts" hoặc "fonts", thử cả 2
                if (normalizedPath.contains('onts/') ||
                    normalizedPath.contains('fonts/')) {
                  final fontPaths = [
                    'OEBPS/fonts/$filename',
                    'fonts/$filename',
                    'OEBPS/Fonts/$filename',
                    'Fonts/$filename',
                  ];
                  for (final fontPath in fontPaths) {
                    if (availableFiles.contains(fontPath)) {
                      foundPath = isInOEBPS
                          ? fontPath.replaceFirst('OEBPS/', '')
                          : fontPath;
                      break;
                    }
                  }
                }
              }

              // Trường hợp 7: Tìm với filename trực tiếp trong các folders phổ biến
              if (foundPath == null) {
                final filename = normalizedPath.split('/').last;
                final commonFolders = [
                  'fonts',
                  'Fonts',
                  'images',
                  'Images',
                  'css',
                  'CSS',
                ];

                for (final folder in commonFolders) {
                  final testPaths = [
                    'OEBPS/$folder/$filename',
                    '$folder/$filename',
                  ];
                  for (final testPath in testPaths) {
                    if (availableFiles.contains(testPath)) {
                      foundPath = isInOEBPS ? '$folder/$filename' : testPath;
                      break;
                    }
                  }
                  if (foundPath != null) break;
                }
              }

              // Xác định final path
              String finalPath;
              if (foundPath != null) {
                finalPath = foundPath;
              } else {
                // Không tìm thấy, dùng normalized path (đã fix typo)
                finalPath = normalizedPath;
              }

              // ĐẢM BẢO không có duplicate prefix
              while (finalPath.startsWith('OEBPS/OEBPS/')) {
                finalPath = finalPath.substring(7);
              }

              // Nếu path gốc có typo và tìm thấy file với path đã sửa,
              // cần tạo duplicate tại path typo để epub reader tìm thấy
              if (foundPath != null && path != finalPath) {
                // Path gốc có typo
                final originalHasTypo =
                    path.contains('onts/') || path.contains('mages/');
                if (originalHasTypo) {
                  // Tạo duplicate tại path typo (sẽ được xử lý sau khi normalize tất cả)
                  // Đánh dấu để tạo duplicate sau
                }
              }

              return finalPath;
            }

            // Tìm tất cả href/src/content trong OPF và HTML
            // Thêm 'content' attribute cho OPF manifest items
            final regex = RegExp(
              r'''(href|src|content|full-path)=["']([^"'\s]+)["']''',
              caseSensitive: false,
            );

            // Xác định file này có nằm trong OEBPS folder không
            final isInOEBPS =
                name.startsWith('OEBPS/') ||
                name == 'content.opf' ||
                name == 'toc.ncx';

            // Track paths với typo để tạo duplicate sau
            final typoPathsToFix =
                <
                  Map<String, String>
                >[]; // [{originalPath, actualPath, typoPath}]

            normalized = normalized.replaceAllMapped(regex, (match) {
              final attr = match.group(1);
              final path = match.group(2);
              if (path == null) return match.group(0)!;

              final normalizedPath = normalizeFilePath(
                path,
                isInOEBPS: isInOEBPS,
              );

              // Nếu path gốc có typo (onts hoặc mages) và normalized path khác
              final hasTypo =
                  (path.contains('onts/') || path.contains('mages/')) &&
                  path != normalizedPath;
              if (hasTypo && normalizedPath != path) {
                // Tìm actual file từ normalized path
                String actualPath;
                if (normalizedPath.startsWith('OEBPS/')) {
                  actualPath = normalizedPath;
                } else {
                  actualPath = 'OEBPS/$normalizedPath';
                }

                // Tạo typo path (giữ nguyên typo như gốc)
                String typoPath = path;
                if (!typoPath.startsWith('OEBPS/') &&
                    !typoPath.startsWith('META-INF/')) {
                  typoPath = 'OEBPS/$typoPath';
                }

                // Chỉ thêm nếu actual file tồn tại và typo path chưa có
                final actualPathLower = actualPath.toLowerCase();
                if (availableFiles.any(
                      (f) =>
                          f == actualPath || f.toLowerCase() == actualPathLower,
                    ) &&
                    !availableFiles.contains(typoPath)) {
                  typoPathsToFix.add({
                    'originalPath': path,
                    'actualPath': actualPath,
                    'typoPath': typoPath,
                  });
                }
              }

              // Debug logging cho các path quan trọng - LOG TẤT CẢ liên quan đến toc.ncx
              if (path.contains('toc.ncx') ||
                  normalizedPath.contains('toc.ncx') ||
                  normalizedPath.contains('OEBPS/OEBPS')) {}

              return '$attr="$normalizedPath"';
            });

            // Nếu là CSS, normalize thêm tất cả url(...) bên trong CSS
            if (name.endsWith('.css')) {
              final cssUrlRegex = RegExp(
                'url\\(\\s*[\\\'\\\"]?([^\\) \\\'\\\"]+)[\\\'\\\"]?\\s*\\)',
                caseSensitive: false,
              );
              normalized = normalized.replaceAllMapped(cssUrlRegex, (match) {
                final rawPath = match.group(1);
                if (rawPath == null) return match.group(0)!;

                final normalizedCssPath = normalizeFilePath(
                  rawPath,
                  isInOEBPS: isInOEBPS,
                );

                return match.group(0)!.replaceFirst(rawPath, normalizedCssPath);
              });
            }

            // Tạo duplicate files cho các paths có typo
            if (typoPathsToFix.isNotEmpty) {
              print(
                '      🔄 Creating duplicate files for typo paths (onts/mages)...',
              );
              for (final fixInfo in typoPathsToFix) {
                final typoPath = fixInfo['typoPath']!;
                final actualPath = fixInfo['actualPath']!;

                // ✅ Tìm actual file trong archive hoặc fixed archive
                ArchiveFile? actualFile = archive.findFile(actualPath);
                if (actualFile == null || !actualFile.isFile) {
                  // Thử tìm trong fixed archive (có thể đã được copy)
                  actualFile = fixed.findFile(actualPath);
                }

                if (actualFile == null || !actualFile.isFile) {
                  // Thử tìm với case-insensitive trong archive
                  final actualPathLower = actualPath.toLowerCase();
                  for (final archiveFile in archive) {
                    if (archiveFile.isFile &&
                        archiveFile.name.toLowerCase() == actualPathLower) {
                      actualFile = archiveFile;
                      break;
                    }
                  }

                  // Nếu vẫn không tìm thấy, thử trong fixed archive
                  if (actualFile == null) {
                    for (final fixedFile in fixed) {
                      if (fixedFile.isFile &&
                          fixedFile.name.toLowerCase() == actualPathLower) {
                        actualFile = fixedFile;
                        break;
                      }
                    }
                  }
                }

                if (actualFile != null && actualFile.isFile) {
                  if (!availableFiles.contains(typoPath) &&
                      !processedFiles.contains(typoPath)) {
                    fixed.addFile(
                      ArchiveFile(
                        typoPath,
                        actualFile.size,
                        Uint8List.fromList(actualFile.content as List<int>),
                      ),
                    );
                    availableFiles.add(typoPath);
                    processedFiles.add(typoPath);
                    print(
                      '         ✅ Created duplicate: "$typoPath" from "$actualPath"',
                    );
                  } else {
                    print(
                      '         ℹ️ Duplicate already exists or processed: "$typoPath"',
                    );
                  }
                } else {
                  print(
                    '         ⚠️ Cannot find actual file for typo path: "$actualPath" (typo: "$typoPath")',
                  );
                }
              }
            }

            // Encode lại với UTF-8 (EPUB standard yêu cầu UTF-8 cho text files)
            Uint8List encodedContent;
            try {
              encodedContent = Uint8List.fromList(utf8.encode(normalized));
            } catch (e) {
              // Fallback nếu UTF-8 encode fail
              encodedContent = Uint8List.fromList(normalized.codeUnits);
              print('      ⚠️ File "$name" encoded with codeUnits fallback');
            }

            fixed.addFile(
              ArchiveFile(name, encodedContent.length, encodedContent),
            );
            processedFiles.add(name);
          } else {
            // Copy các file khác (ảnh, CSS, fonts, mimetype, etc.) vào archive mới
            // Bỏ qua nếu đã được copy ở bước 1
            if (!processedFiles.contains(name)) {
              fixed.addFile(
                ArchiveFile(name, data.length, Uint8List.fromList(data)),
              );
              processedFiles.add(name);
              // ✅ Tự động tạo duplicate cho typo paths (onts <-> fonts, mages <-> images)
              // Điều này đảm bảo epub reader tìm thấy file dù path có typo
              final lowerName = name.toLowerCase();
              String? typoPath;

              // ✅ QUAN TRỌNG: Nếu file trong fonts/, tạo duplicate tại onts/
              // Điều này đảm bảo TẤT CẢ files trong fonts/ đều có duplicate tại onts/
              // Xử lý cả OEBPS/fonts/ và fonts/ (không có OEBPS prefix)
              if (lowerName.contains('/fonts/') ||
                  lowerName.contains('oebps/fonts/') ||
                  lowerName.startsWith('fonts/')) {
                // Xử lý OEBPS/fonts/ -> OEBPS/onts/ trước
                if (name.contains('OEBPS/fonts/') ||
                    lowerName.contains('oebps/fonts/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'OEBPS[/\\]fonts[/\\]', caseSensitive: false),
                    'OEBPS/onts/',
                  );
                } else if (lowerName.contains('/fonts/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'[/\\]fonts[/\\]', caseSensitive: false),
                    '/onts/',
                  );
                } else if (lowerName.startsWith('fonts/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'^fonts[/\\]', caseSensitive: false),
                    'onts/',
                  );
                }
              }

              // Nếu file trong onts/, tạo duplicate tại fonts/
              if (typoPath == null) {
                if (lowerName.contains('/onts/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'[/\\]onts[/\\]', caseSensitive: false),
                    '/fonts/',
                  );
                } else if (lowerName.startsWith('onts/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'^onts[/\\]', caseSensitive: false),
                    'fonts/',
                  );
                } else if (lowerName.contains('oebps/onts/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'oebps[/\\]onts[/\\]', caseSensitive: false),
                    'OEBPS/fonts/',
                  );
                }
              }

              // Tương tự cho images <-> mages
              if (typoPath == null) {
                if (lowerName.contains('/images/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'[/\\]images[/\\]', caseSensitive: false),
                    '/mages/',
                  );
                } else if (lowerName.startsWith('images/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'^images[/\\]', caseSensitive: false),
                    'mages/',
                  );
                } else if (lowerName.contains('oebps/images/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'oebps[/\\]images[/\\]', caseSensitive: false),
                    'OEBPS/mages/',
                  );
                }
              }

              if (typoPath == null) {
                if (lowerName.contains('/mages/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'[/\\]mages[/\\]', caseSensitive: false),
                    '/images/',
                  );
                } else if (lowerName.startsWith('mages/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'^mages[/\\]', caseSensitive: false),
                    'images/',
                  );
                } else if (lowerName.contains('oebps/mages/')) {
                  typoPath = name.replaceFirst(
                    RegExp(r'oebps[/\\]mages[/\\]', caseSensitive: false),
                    'OEBPS/images/',
                  );
                }
              }

              // Tạo duplicate nếu có typo path và chưa tồn tại
              if (typoPath != null && !processedFiles.contains(typoPath)) {
                fixed.addFile(
                  ArchiveFile(typoPath, data.length, Uint8List.fromList(data)),
                );
                processedFiles.add(typoPath);
                availableFiles.add(typoPath);
                print(
                  '      ✅ Auto-created typo duplicate: "$typoPath" from "$name"',
                );
              }

              // ✅ QUAN TRỌNG: Tạo duplicate tại cả path không có OEBPS prefix
              // Ví dụ: Nếu có OEBPS/fonts/bookerlyItalic.ttf, tạo cả onts/bookerlyItalic.ttf
              // (không có OEBPS prefix) vì có thể có reference đến path này
              // Xử lý cả fonts/ và Fonts/ (case-insensitive)
              if (name.contains('OEBPS/fonts/') ||
                  name.contains('OEBPS/Fonts/') ||
                  name.contains('fonts/') ||
                  name.contains('Fonts/')) {
                final filename = name.split('/').last;
                // Tạo cả onts/ và OEBPS/onts/ để đảm bảo tìm thấy
                final typoPaths = [
                  'onts/$filename', // Không có OEBPS prefix
                  'OEBPS/onts/$filename', // Có OEBPS prefix
                ];
                for (final typoPathNoOEBPS in typoPaths) {
                  if (!processedFiles.contains(typoPathNoOEBPS) &&
                      !availableFiles.contains(typoPathNoOEBPS)) {
                    fixed.addFile(
                      ArchiveFile(
                        typoPathNoOEBPS,
                        data.length,
                        Uint8List.fromList(data),
                      ),
                    );
                    processedFiles.add(typoPathNoOEBPS);
                    availableFiles.add(typoPathNoOEBPS);
                    print(
                      '      ✅ Auto-created typo duplicate: "$typoPathNoOEBPS" from "$name"',
                    );
                  }
                }
              }

              // Tương tự cho images
              if (name.contains('OEBPS/images/') ||
                  name.contains('OEBPS/Images/')) {
                final filename = name.split('/').last;
                final typoPathNoOEBPS = 'mages/$filename';
                if (!processedFiles.contains(typoPathNoOEBPS) &&
                    !availableFiles.contains(typoPathNoOEBPS)) {
                  fixed.addFile(
                    ArchiveFile(
                      typoPathNoOEBPS,
                      data.length,
                      Uint8List.fromList(data),
                    ),
                  );
                  processedFiles.add(typoPathNoOEBPS);
                  availableFiles.add(typoPathNoOEBPS);
                  print(
                    '      ✅ Auto-created typo duplicate (no OEBPS): "$typoPathNoOEBPS" from "$name"',
                  );
                }
              }
            }
          }
        }
      }

      // Pass thứ 2: Clean up OPF manifest sau khi đã có tất cả files
      final allAvailableFiles = <String>{
        ...availableFiles,
        ...fixed.map((f) => f.name),
      };

      // Log available files for debugging
      print(
        '📋 Total available files after processing: ${allAvailableFiles.length}',
      );
      // Log some sample file names for debugging (especially Images folder)
      final imageFiles = allAvailableFiles
          .where(
            (f) =>
                f.toLowerCase().contains('image') ||
                f.toLowerCase().contains('cover'),
          )
          .take(10)
          .toList();
      if (imageFiles.isNotEmpty) {
        print('   🖼️ Sample image/cover files: ${imageFiles.join(", ")}');
      }

      // Pass thứ 3: Clean up OPF manifest và tạo placeholder files cho missing items
      final finalArchive = Archive();
      final processedOpfFiles = <String>{};
      final missingFiles =
          <String>[]; // Track files we need to create placeholders for

      // First, identify missing files from OPF
      for (final file in fixed) {
        if (file.name.endsWith('.opf') &&
            !processedOpfFiles.contains(file.name)) {
          try {
            // Decode OPF content với UTF-8, cho phép malformed bytes
            String opfContent;
            try {
              // ✅ QUAN TRỌNG: Luôn dùng allowMalformed: true để tránh FormatException
              opfContent = utf8.decode(
                file.content as List<int>,
                allowMalformed: true,
              );
            } catch (e) {
              try {
                opfContent = latin1.decode(file.content as List<int>);
                print(
                  '      ⚠️ OPF file decoded as Latin1 instead of UTF-8: $e',
                );
              } catch (e2) {
                // ✅ Filter out invalid characters để tránh FormatException
                final validData = (file.content as List<int>)
                    .where((byte) => byte >= 0 && byte <= 255)
                    .toList();
                opfContent = String.fromCharCodes(validData);
                print(
                  '      ⚠️ OPF file decoded with fromCharCodes (may have encoding issues)',
                );
              }
            }
            print('🔍 Cleaning OPF file: ${file.name}');

            // Get list of items to remove before cleanup và info về IDs cần duplicate
            final cleanupResult = _cleanupOpfManifestWithInfo(
              opfContent,
              allAvailableFiles,
            );
            final tempCleaned = cleanupResult['cleaned'] as String;
            final idToActualPathMap =
                cleanupResult['idToActualPath'] as Map<String, String>;

            // Fix NCX/TOC file references - tìm và sửa các reference sai
            String cleanedOpfContent = tempCleaned;
            try {
              print('   🔍 Checking NCX/TOC file references...');

              // Tìm tất cả NCX references trong OPF (spine toc attribute và guide)
              final ncxPatterns = [
                // Spine toc attribute
                RegExp(
                  r'''<spine[^>]+toc=["']([^"']+\.ncx)["']''',
                  caseSensitive: false,
                ),
                RegExp(r'''toc=["']([^"']+\.ncx)["']''', caseSensitive: false),
                // Guide reference
                RegExp(
                  r'''<reference[^>]+href=["']([^"']+\.ncx)["']''',
                  caseSensitive: false,
                ),
                // OPF metadata
                RegExp(
                  r'''<meta[^>]+content=["']([^"']+\.ncx)["']''',
                  caseSensitive: false,
                ),
              ];

              final ncxReferences = <String>[];
              for (final pattern in ncxPatterns) {
                pattern.allMatches(cleanedOpfContent).forEach((match) {
                  if (match.groupCount > 0 && match.group(1) != null) {
                    final ncxPath = match.group(1)!;
                    ncxReferences.add(ncxPath);
                    print('      📑 Found NCX reference: "$ncxPath"');
                  }
                });
              }

              // Tìm actual NCX file trong archive
              String? actualNcxFile;
              for (final file in fixed) {
                if (file.name.toLowerCase().endsWith('.ncx')) {
                  actualNcxFile = file.name;
                  print('      ✅ Found NCX file in archive: "$actualNcxFile"');
                  break;
                }
              }

              // Nếu không tìm thấy trong fixed, tìm trong original archive
              if (actualNcxFile == null) {
                for (final file in archive) {
                  if (file.isFile && file.name.toLowerCase().endsWith('.ncx')) {
                    actualNcxFile = file.name;
                    print(
                      '      ✅ Found NCX file in original: "$actualNcxFile"',
                    );
                    // Copy vào fixed archive
                    fixed.addFile(
                      ArchiveFile(
                        actualNcxFile,
                        file.size,
                        Uint8List.fromList(file.content as List<int>),
                      ),
                    );
                    allAvailableFiles.add(actualNcxFile);
                    break;
                  }
                }
              }

              // Fix các NCX references nếu sai
              if (actualNcxFile != null && ncxReferences.isNotEmpty) {
                for (final ref in ncxReferences) {
                  // Normalize ref path
                  String normalizedRef = ref;
                  if (normalizedRef.startsWith('/')) {
                    normalizedRef = normalizedRef.substring(1);
                  }

                  // Calculate relative path từ OEBPS
                  String relativeNcxPath = actualNcxFile;
                  if (relativeNcxPath.startsWith('OEBPS/')) {
                    relativeNcxPath = relativeNcxPath.substring(7);
                  }

                  // Nếu reference không match với actual file, fix nó
                  if (ref != relativeNcxPath && ref != actualNcxFile) {
                    print(
                      '      🔄 Fixing NCX reference: "$ref" -> "$relativeNcxPath"',
                    );

                    // Tạo duplicate file tại path của reference nếu cần
                    String? refPath = ref;
                    if (refPath.startsWith('/')) {
                      refPath = refPath.substring(1);
                    }
                    // Đảm bảo có OEBPS prefix
                    String targetRefPath = refPath;
                    if (!targetRefPath.startsWith('OEBPS/') &&
                        !targetRefPath.startsWith('META-INF/')) {
                      targetRefPath = 'OEBPS/$targetRefPath';
                    }

                    // Nếu target path khác với actual file, tạo duplicate
                    if (targetRefPath != actualNcxFile &&
                        !allAvailableFiles.contains(targetRefPath)) {
                      // Ưu tiên lấy từ original archive để tránh encoding issues
                      var ncxFile = archive.findFile(actualNcxFile);
                      if (ncxFile == null || !ncxFile.isFile) {
                        ncxFile = fixed.findFile(actualNcxFile);
                      }
                      if (ncxFile != null && ncxFile.isFile) {
                        // Copy nguyên bytes từ file gốc, không decode/encode
                        fixed.addFile(
                          ArchiveFile(
                            targetRefPath,
                            ncxFile.size,
                            Uint8List.fromList(ncxFile.content as List<int>),
                          ),
                        );
                        allAvailableFiles.add(targetRefPath);
                        _epubRepairLog(
                          '      ✅ Created duplicate NCX file: "$targetRefPath" from "$actualNcxFile"',
                        );
                      }
                    }

                    // Replace trong tất cả contexts
                    cleanedOpfContent = cleanedOpfContent.replaceAll(
                      RegExp(RegExp.escape(ref), caseSensitive: false),
                      relativeNcxPath,
                    );
                  }
                }
              } else if (actualNcxFile == null && ncxReferences.isNotEmpty) {
                _epubRepairLog(
                  '      ⚠️ WARNING: NCX file referenced but not found in archive!',
                );
                _epubRepairLog(
                  '         References: ${ncxReferences.join(", ")}',
                );
              }
            } catch (e) {
              _epubRepairLog('      ⚠️ Error checking NCX references: $e');
            }

            // Tạo duplicate files cho các IDs là path không hợp lệ
            if (idToActualPathMap.isNotEmpty) {
              _epubRepairLog(
                '   🔄 Creating duplicate files for IDs with path issues...',
              );
              idToActualPathMap.forEach((id, actualPath) {
                // Nếu ID là path (chứa "/") và không match với actual path
                if ((id.contains('/') || id.contains('\\')) &&
                    id != actualPath) {
                  // Tạo file tại path của ID bằng cách copy từ actual file
                  final idPath = id.replaceAll('\\', '/');
                  // Đảm bảo có OEBPS prefix nếu cần
                  String targetPath = idPath;
                  if (!targetPath.startsWith('OEBPS/') &&
                      !targetPath.startsWith('META-INF/')) {
                    targetPath = 'OEBPS/$targetPath';
                  }

                  // Chỉ tạo nếu chưa tồn tại
                  if (!allAvailableFiles.contains(targetPath) &&
                      !allAvailableFiles.contains(idPath)) {
                    // Tìm actual file trong fixed archive
                    final actualFile = fixed.findFile(actualPath);
                    if (actualFile != null && actualFile.isFile) {
                      fixed.addFile(
                        ArchiveFile(
                          targetPath,
                          actualFile.size,
                          Uint8List.fromList(actualFile.content as List<int>),
                        ),
                      );
                      allAvailableFiles.add(targetPath);
                      _epubRepairLog(
                        '      ✅ Created duplicate file: "$targetPath" from "$actualPath"',
                      );
                    }
                  }
                }
              });
            }

            // Extract missing file paths from items that will be removed
            // (We'll get this info from cleanup function's logging, but we can also parse it here)
            final itemsToRemoveInfo = _getItemsToRemove(
              opfContent,
              allAvailableFiles,
            );
            for (final itemInfo in itemsToRemoveInfo) {
              final href = itemInfo['href'];
              if (href != null) {
                // Normalize the href path
                String normalizedPath = href;
                if (normalizedPath.startsWith('/')) {
                  normalizedPath = normalizedPath.substring(1);
                }
                if (!normalizedPath.startsWith('OEBPS/')) {
                  normalizedPath = 'OEBPS/$normalizedPath';
                }
                if (!allAvailableFiles.contains(normalizedPath) &&
                    !missingFiles.contains(normalizedPath)) {
                  missingFiles.add(normalizedPath);
                  _epubRepairLog(
                    '   📝 Will create placeholder for: $normalizedPath',
                  );
                }
              }
            }

            final cleaned = cleanedOpfContent;
            if (cleaned != opfContent) {
              _epubRepairLog('✅ OPF manifest cleaned: ${file.name}');
            }
            processedOpfFiles.add(file.name);
            // Encode lại với UTF-8 (EPUB standard yêu cầu UTF-8 cho OPF files)
            Uint8List encodedCleaned;
            try {
              encodedCleaned = Uint8List.fromList(utf8.encode(cleaned));
            } catch (e) {
              // Fallback nếu UTF-8 encode fail
              encodedCleaned = Uint8List.fromList(cleaned.codeUnits);
              _epubRepairLog(
                '      ⚠️ OPF file encoded with codeUnits fallback',
              );
            }
            finalArchive.addFile(
              ArchiveFile(file.name, encodedCleaned.length, encodedCleaned),
            );
          } catch (e) {
            _epubRepairLog('⚠️ Error cleaning OPF file ${file.name}: $e');
            // Nếu có lỗi, thêm file gốc
            finalArchive.addFile(file);
          }
        } else if (!processedOpfFiles.contains(file.name)) {
          // Thêm các file khác - đảm bảo binary files được copy đúng
          try {
            // Kiểm tra xem file có phải binary không
            final isBinaryFile = _isBinaryFile(file.name);
            if (isBinaryFile) {
              // Binary files: copy nguyên bytes
              finalArchive.addFile(
                ArchiveFile(
                  file.name,
                  file.size,
                  Uint8List.fromList(file.content as List<int>),
                ),
              );
            } else {
              // Text files: có thể cần kiểm tra encoding
              finalArchive.addFile(file);
            }
          } catch (e) {
            _epubRepairLog(
              '⚠️ Error adding file ${file.name} to final archive: $e',
            );
            // Fallback: copy nguyên
            finalArchive.addFile(file);
          }
        }
      }

      // Create placeholder files for missing images
      for (final missingPath in missingFiles) {
        if (missingPath.toLowerCase().endsWith('.jpg') ||
            missingPath.toLowerCase().endsWith('.jpeg') ||
            missingPath.toLowerCase().endsWith('.png') ||
            missingPath.toLowerCase().endsWith('.gif') ||
            missingPath.toLowerCase().endsWith('.webp')) {
          // Create a minimal 1x1 transparent PNG as placeholder
          final placeholderPng = Uint8List.fromList([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
            0x08,
            0x06,
            0x00,
            0x00,
            0x00,
            0x1F,
            0x15,
            0xC4,
            0x89, // color type, etc.
            0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, // IDAT chunk
            0x78,
            0x9C,
            0x63,
            0x00,
            0x01,
            0x00,
            0x00,
            0x05,
            0x00,
            0x01, // minimal data
            0x0D,
            0x0A,
            0x2D,
            0xB4,
            0x00,
            0x00,
            0x00,
            0x00,
            0x49,
            0x45,
            0x4E,
            0x44, // IEND
            0xAE, 0x42, 0x60, 0x82,
          ]);

          // Convert to appropriate format if needed
          Uint8List placeholderBytes;
          if (missingPath.toLowerCase().endsWith('.jpg') ||
              missingPath.toLowerCase().endsWith('.jpeg')) {
            // For JPEG, we'll use PNG and rename, or create minimal JPEG
            // For simplicity, use PNG for all
            placeholderBytes = placeholderPng;
          } else {
            placeholderBytes = placeholderPng;
          }

          finalArchive.addFile(
            ArchiveFile(missingPath, placeholderBytes.length, placeholderBytes),
          );
          _epubRepairLog('   ✅ Created placeholder file: $missingPath');
        }
      }

      // Ensure NCX file aliases exist for readers expecting specific paths
      try {
        // Find any NCX file present in the final archive
        String? ncxPathInArchive;
        for (final f in finalArchive) {
          if (f.name.toLowerCase().endsWith('.ncx')) {
            ncxPathInArchive = f.name;
            break;
          }
        }
        // If not found in finalArchive yet, try from earlier processed lists
        if (ncxPathInArchive == null) {
          for (final f in fixed) {
            if (f.name.toLowerCase().endsWith('.ncx')) {
              ncxPathInArchive = f.name;
              // add to finalArchive to ensure presence
              finalArchive.addFile(
                ArchiveFile(
                  f.name,
                  f.size,
                  Uint8List.fromList(f.content as List<int>),
                ),
              );
              break;
            }
          }
        }

        if (ncxPathInArchive != null) {
          // Preferred alias paths some readers may require
          final aliasPaths = <String>{'OEBPS/oc.ncx', 'oc.ncx'};

          // Collect existing file names for quick contains check
          final existingNames = finalArchive.map((f) => f.name).toSet();

          // Get source NCX bytes
          ArchiveFile? sourceFile = finalArchive.findFile(ncxPathInArchive);
          sourceFile ??= fixed.findFile(ncxPathInArchive);

          if (sourceFile != null) {
            for (final alias in aliasPaths) {
              if (!existingNames.contains(alias)) {
                finalArchive.addFile(
                  ArchiveFile(
                    alias,
                    sourceFile.size,
                    Uint8List.fromList(sourceFile.content as List<int>),
                  ),
                );
                existingNames.add(alias);
                _epubRepairLog(
                  '✅ Added NCX alias: $alias -> $ncxPathInArchive',
                );
              }
            }
          }
        }
      } catch (e) {
        _epubRepairLog('⚠️ Error while ensuring NCX aliases: $e');
      }

      // Create alias duplicates for common folder typos (fonts <-> onts, images <-> mages)
      // ✅ Xử lý CẢ HAI CHIỀU để đảm bảo file tìm thấy dù path có typo hay không
      try {
        final existingNames = finalArchive.map((f) => f.name).toSet();
        final toAdd = <ArchiveFile>[];

        for (final f in finalArchive) {
          final name = f.name;
          final lower = name.toLowerCase();

          // Tạo alias cho fonts -> onts
          String? aliasPath;
          // Xử lý OEBPS/fonts/ -> OEBPS/onts/ trước (case-sensitive)
          if (name.contains('OEBPS/fonts/') || lower.contains('oebps/fonts/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'OEBPS[/\\]fonts[/\\]', caseSensitive: false),
              'OEBPS/onts/',
            );
          }
          // Xử lý fonts/ -> onts/ (không có OEBPS prefix)
          else if (lower.contains('/fonts/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'[/\\]fonts[/\\]', caseSensitive: false),
              '/onts/',
            );
          } else if (lower.startsWith('fonts/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'^fonts[/\\]', caseSensitive: false),
              'onts/',
            );
          }
          // Tạo alias cho onts -> fonts (CHIỀU NGƯỢC LẠI)
          else if (name.contains('OEBPS/onts/') ||
              lower.contains('oebps/onts/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'OEBPS[/\\]onts[/\\]', caseSensitive: false),
              'OEBPS/fonts/',
            );
          } else if (lower.contains('/onts/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'[/\\]onts[/\\]', caseSensitive: false),
              '/fonts/',
            );
          } else if (lower.startsWith('onts/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'^onts[/\\]', caseSensitive: false),
              'fonts/',
            );
          }
          // Tạo alias cho images -> mages
          else if (name.contains('OEBPS/images/') ||
              lower.contains('oebps/images/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'OEBPS[/\\]images[/\\]', caseSensitive: false),
              'OEBPS/mages/',
            );
          } else if (lower.contains('/images/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'[/\\]images[/\\]', caseSensitive: false),
              '/mages/',
            );
          } else if (lower.startsWith('images/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'^images[/\\]', caseSensitive: false),
              'mages/',
            );
          }
          // Tạo alias cho mages -> images (CHIỀU NGƯỢC LẠI)
          else if (name.contains('OEBPS/mages/') ||
              lower.contains('oebps/mages/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'OEBPS[/\\]mages[/\\]', caseSensitive: false),
              'OEBPS/images/',
            );
          } else if (lower.contains('/mages/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'[/\\]mages[/\\]', caseSensitive: false),
              '/images/',
            );
          } else if (lower.startsWith('mages/')) {
            aliasPath = name.replaceFirst(
              RegExp(r'^mages[/\\]', caseSensitive: false),
              'images/',
            );
          }

          if (aliasPath != null && !existingNames.contains(aliasPath)) {
            toAdd.add(
              ArchiveFile(
                aliasPath,
                f.size,
                Uint8List.fromList(f.content as List<int>),
              ),
            );
            existingNames.add(aliasPath);
            _epubRepairLog(
              '   ✅ Added typo alias (bidirectional): $aliasPath <-> ${f.name}',
            );
          }
        }

        for (final nf in toAdd) {
          finalArchive.addFile(nf);
        }

        _epubRepairLog(
          '   ✅ Finished creating typo aliases. Total aliases created: ${toAdd.length}',
        );
      } catch (e) {
        _epubRepairLog('⚠️ Error while creating folder typo aliases: $e');
      }

      // Reorder and enforce EPUB container rules: 'mimetype' first and uncompressed,
      // ensure META-INF/container.xml exists pointing to detected OPF.
      Archive orderedArchive = Archive();

      // 1) Ensure 'mimetype' is present and first, uncompressed
      const mimetypeName = 'mimetype';
      final existingMimetype = finalArchive.findFile(mimetypeName);
      Uint8List mimetypeBytes;
      if (existingMimetype != null) {
        // Use existing content as-is
        mimetypeBytes = Uint8List.fromList(
          existingMimetype.content as List<int>,
        );
      } else {
        // Create standard mimetype content
        mimetypeBytes = Uint8List.fromList('application/epub+zip'.codeUnits);
      }
      orderedArchive.addFile(
        ArchiveFile.noCompress(
          mimetypeName,
          mimetypeBytes.length,
          mimetypeBytes,
        ),
      );

      // 2) Copy all other files except 'mimetype' into orderedArchive
      for (final f in finalArchive) {
        if (f.name == mimetypeName) continue;
        orderedArchive.addFile(
          ArchiveFile(
            f.name,
            f.size,
            Uint8List.fromList(f.content as List<int>),
          ),
        );
      }

      // 3) Ensure META-INF/container.xml exists and references an OPF
      const containerPath = 'META-INF/container.xml';
      final hasContainer = orderedArchive.files.any(
        (f) => f.name == containerPath,
      );
      if (!hasContainer) {
        // Try to locate an OPF file
        String opfPath = 'OEBPS/content.opf';
        for (final f in orderedArchive) {
          if (f.name.toLowerCase().endsWith('.opf')) {
            opfPath = f.name;
            break;
          }
        }
        final containerXml =
            '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="$opfPath" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
        final containerBytes = Uint8List.fromList(utf8.encode(containerXml));
        orderedArchive.addFile(
          ArchiveFile(containerPath, containerBytes.length, containerBytes),
        );
      }

      final encoded = ZipEncoder().encode(orderedArchive);
      if (encoded == null || encoded.isEmpty) {
        print(
          '⚠️ WARNING: Encoded archive is null or empty, returning original',
        );
        return originalBytes;
      }

      // Kiểm tra encoded archive có hợp lệ không (phải lớn hơn một ngưỡng tối thiểu)
      if (encoded.length < 100) {
        print(
          '⚠️ WARNING: Encoded archive is too small (${encoded.length} bytes), returning original',
        );
        return originalBytes;
      }

      return Uint8List.fromList(encoded);
    } catch (e) {
      // Nếu có lỗi, trả lại bytes gốc để không chặn luồng
      print('❌ Error in sanitizeEpubBytes: $e');
      print('   Returning original EPUB bytes as fallback');
      return originalBytes;
    }
  }

  static Future<List<EbookChapter>> loadEpubChaptersFromFile(
    String filePath, {
    EbookSettings? settings,
  }) async {
    try {
      final fileBytes = await File(filePath).readAsBytes();
      return _parseEpubChapters(
        fileBytes,
        settings: settings,
        sourceDescription: 'file: $filePath',
      );
    } catch (e) {
      throw Exception('Không thể tải chương EPUB: $e');
    }
  }

  static Future<List<EbookChapter>> loadEpubChaptersFromUrl(
    String url, {
    EbookSettings? settings,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (response.bodyBytes.isEmpty) {
        throw Exception('Dữ liệu EPUB trống.');
      }
      return _parseEpubChapters(
        response.bodyBytes,
        settings: settings,
        sourceDescription: 'url: $url',
      );
    } catch (e) {
      throw Exception('Không thể tải chương EPUB từ URL: $e');
    }
  }

  static Future<List<EbookChapter>> _parseEpubChapters(
    Uint8List originalBytes, {
    EbookSettings? settings,
    String? sourceDescription,
  }) async {
    Uint8List sanitizedBytes;
    try {
      sanitizedBytes = sanitizeEpubBytes(originalBytes);
    } catch (e) {
      print(
        '⚠️ sanitizeEpubBytes failed (${sourceDescription ?? 'unknown source'}): $e',
      );
      sanitizedBytes = originalBytes;
    }

    epubx.EpubBook epubBook;
    try {
      epubBook = await epubx.EpubReader.readBook(sanitizedBytes);
    } on FormatException catch (e) {
      print(
        '⚠️ readBook failed with sanitized bytes (${sourceDescription ?? 'unknown source'}): ${e.message}. Retrying with original bytes.',
      );
      epubBook = await epubx.EpubReader.readBook(originalBytes);
    }
    final chapterEntities = epubBook.Chapters;

    final chapters = <EbookChapter>[];

    Future<void> extractChapters(List<epubx.EpubChapter>? refs) async {
      if (refs == null || refs.isEmpty) {
        return;
      }
      for (final chapter in refs) {
        final title = (chapter.Title?.trim().isNotEmpty ?? false)
            ? chapter.Title!.trim()
            : 'Chương ${chapters.length + 1}';
        final rawId = [chapter.Anchor, chapter.ContentFileName].firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );
        final id = (rawId?.trim().isNotEmpty ?? false)
            ? rawId!.trim()
            : 'chapter_${chapters.length + 1}';
        final rawHtml = (chapter.HtmlContent?.trim().isNotEmpty ?? false)
            ? chapter.HtmlContent!.trim()
            : '<p>(Không có nội dung)</p>';
        final processedHtml = settings != null
            ? _applyReaderSettingsToHtml(rawHtml, settings)
            : _normalizeChapterHtml(rawHtml);
        chapters.add(
          EbookChapter(
            id: id,
            title: title,
            pageNumber: chapters.length + 1,
            content: processedHtml,
          ),
        );
        await extractChapters(chapter.SubChapters);
      }
    }

    await extractChapters(chapterEntities);

    if (chapters.isEmpty) {
      throw Exception('EPUB không chứa chương hợp lệ.');
    }
    return chapters;
  }
}
