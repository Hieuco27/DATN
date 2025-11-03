import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
// Removed unused viewer imports
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

enum EbookFormat { pdf, epub, mobi, txt, html }

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

    final directory = await getTemporaryDirectory();
    var fileName = url.split('/').last;

    // ✅ Xử lý trường hợp fileName rỗng hoặc không hợp lệ
    if (fileName.isEmpty || !fileName.contains('.')) {
      // Tạo tên file mặc định dựa trên format
      final format = await detectFormat(url);
      fileName = 'ebook.${format.name}';
    }

    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
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
            filename,
          ]);
        }

        // Always try just filename
        possiblePaths.add(filename);

        // Also try searching by filename in common folders if not found
        if (!availableFiles.contains(normalizedHref)) {
          final commonFolders = [
            'fonts',
            'Fonts',
            'images',
            'Images',
            'css',
            'CSS',
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
        print(
          '   🔄 Updating href in manifest items to match actual file paths...',
        );
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
              print(
                '      🔄 Updating href for ID="$id": "$oldHref" -> "$relativePath"',
              );
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
              print(
                '      🔄 Updating href for ID="$id": "$oldHref" -> "$relativePath"',
              );
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
              print(
                '      🔄 Updating href for ID="$id" (multiline): "$oldHref" -> "$relativePath"',
              );
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
              print(
                '      🔄 Updating href for ID="$id" (multiline): "$oldHref" -> "$relativePath"',
              );
              return '${match.group(1)}$relativePath${match.group(3)}';
            }
            return match.group(0)!;
          });
        });

        opfContent = updated;
        print('   ✅ Finished updating href in manifest items');
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
      ];

      for (final file in archive) {
        if (file.isFile) {
          final name = file.name;
          // Tìm các file ở root level (không có folder prefix) và bỏ qua mimetype, META-INF
          if (!name.contains('/') &&
              name != 'mimetype' &&
              assetExtensions.any((ext) => name.toLowerCase().endsWith(ext))) {
            rootAssets.add(name);
          }
        }
      }

      // Sao chép tất cả assets ở root vào OEBPS folder
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

          // Xử lý các file text cần normalize (OPF, NCX, HTML, XML)
          if (name.endsWith('.opf') ||
              name.endsWith('.ncx') ||
              name.endsWith('.xhtml') ||
              name.endsWith('.html') ||
              name.endsWith('.xml')) {
            // Try decode với UTF-8, cho phép malformed bytes để tránh crash
            String content;
            try {
              // Cho phép malformed bytes để tránh FormatException
              content = utf8.decode(data, allowMalformed: true);
            } catch (e) {
              // Nếu UTF-8 fail, thử Latin1
              try {
                content = latin1.decode(data);
                print(
                  '      ⚠️ File "$name" decoded as Latin1 instead of UTF-8',
                );
              } catch (e2) {
                // Nếu cả 2 đều fail, dùng String.fromCharCodes với allowMalformed
                try {
                  content = String.fromCharCodes(data);
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

            // Tạo duplicate files cho các paths có typo
            if (typoPathsToFix.isNotEmpty) {
              print(
                '      🔄 Creating duplicate files for typo paths (onts/mages)...',
              );
              for (final fixInfo in typoPathsToFix) {
                final typoPath = fixInfo['typoPath']!;
                final actualPath = fixInfo['actualPath']!;

                // Tìm actual file trong archive
                final actualFile = archive.findFile(actualPath);
                if (actualFile == null || !actualFile.isFile) {
                  // Thử tìm với case-insensitive
                  final actualPathLower = actualPath.toLowerCase();
                  for (final archiveFile in archive) {
                    if (archiveFile.isFile &&
                        archiveFile.name.toLowerCase() == actualPathLower) {
                      final foundFile = archive.findFile(archiveFile.name);
                      if (foundFile != null && foundFile.isFile) {
                        fixed.addFile(
                          ArchiveFile(
                            typoPath,
                            foundFile.size,
                            Uint8List.fromList(foundFile.content as List<int>),
                          ),
                        );
                        availableFiles.add(typoPath);
                        print(
                          '         ✅ Created duplicate: "$typoPath" from "${foundFile.name}"',
                        );
                        break;
                      }
                    }
                  }
                  continue;
                }

                if (!availableFiles.contains(typoPath)) {
                  fixed.addFile(
                    ArchiveFile(
                      typoPath,
                      actualFile.size,
                      Uint8List.fromList(actualFile.content as List<int>),
                    ),
                  );
                  availableFiles.add(typoPath);
                  print(
                    '         ✅ Created duplicate: "$typoPath" from "$actualPath"',
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
              // Cho phép malformed bytes để tránh FormatException
              opfContent = utf8.decode(
                file.content as List<int>,
                allowMalformed: true,
              );
            } catch (e) {
              try {
                opfContent = latin1.decode(file.content as List<int>);
                print('      ⚠️ OPF file decoded as Latin1 instead of UTF-8');
              } catch (e2) {
                opfContent = String.fromCharCodes(file.content as List<int>);
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
                        print(
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
                print(
                  '      ⚠️ WARNING: NCX file referenced but not found in archive!',
                );
                print('         References: ${ncxReferences.join(", ")}');
              }
            } catch (e) {
              print('      ⚠️ Error checking NCX references: $e');
            }

            // Tạo duplicate files cho các IDs là path không hợp lệ
            if (idToActualPathMap.isNotEmpty) {
              print(
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
                      print(
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
                  print('   📝 Will create placeholder for: $normalizedPath');
                }
              }
            }

            final cleaned = cleanedOpfContent;
            if (cleaned != opfContent) {
              print('✅ OPF manifest cleaned: ${file.name}');
            }
            processedOpfFiles.add(file.name);
            // Encode lại với UTF-8 (EPUB standard yêu cầu UTF-8 cho OPF files)
            Uint8List encodedCleaned;
            try {
              encodedCleaned = Uint8List.fromList(utf8.encode(cleaned));
            } catch (e) {
              // Fallback nếu UTF-8 encode fail
              encodedCleaned = Uint8List.fromList(cleaned.codeUnits);
              print('      ⚠️ OPF file encoded with codeUnits fallback');
            }
            finalArchive.addFile(
              ArchiveFile(file.name, encodedCleaned.length, encodedCleaned),
            );
          } catch (e) {
            print('⚠️ Error cleaning OPF file ${file.name}: $e');
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
            print('⚠️ Error adding file ${file.name} to final archive: $e');
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
          print('   ✅ Created placeholder file: $missingPath');
        }
      }

      final encoded = ZipEncoder().encode(finalArchive);
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
}
