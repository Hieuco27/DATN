import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';

class EbookSettingsService {
  static const String _settingsKey = 'ebook_settings';
  static const String _highlightsKey = 'ebook_highlights';
  static const String _progressKey = 'ebook_progress';

  // Settings
  static Future<EbookSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      final settingsMap = json.decode(settingsJson);
      return EbookSettings(
        fontSize: settingsMap['fontSize'] is num
            ? (settingsMap['fontSize'] as num).toDouble()
            : 16.0,
        fontFamily: settingsMap['fontFamily'] ?? 'Roboto',
        lineHeight: settingsMap['lineHeight'] is num
            ? (settingsMap['lineHeight'] as num).toDouble()
            : 1.5,
        theme: settingsMap['theme'] ?? 'light',
        eyeComfortEnabled: settingsMap['eyeComfortEnabled'] ?? true,
        warmth: settingsMap['warmth'] is num
            ? (settingsMap['warmth'] as num).toDouble()
            : 0.35,
        brightness: settingsMap['brightness'] is num
            ? (settingsMap['brightness'] as num).toDouble()
            : 0.85,
        restReminderEnabled: settingsMap['restReminderEnabled'] ?? true,
        restReminderMinutes: settingsMap['restReminderMinutes'] is num
            ? (settingsMap['restReminderMinutes'] as num).round()
            : 30,
        highlightColor: settingsMap['highlightColor'] is String
            ? settingsMap['highlightColor'] as String
            : '#FFF59D',
        scrollDirection: settingsMap['scrollDirection'] ?? 'vertical',
      );
    }

    return EbookSettings();
  }

  static Future<void> saveSettings(EbookSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsMap = {
      'fontSize': settings.fontSize,
      'fontFamily': settings.fontFamily,
      'lineHeight': settings.lineHeight,
      'theme': settings.theme,
      'eyeComfortEnabled': settings.eyeComfortEnabled,
      'warmth': settings.warmth,
      'brightness': settings.brightness,
      'restReminderEnabled': settings.restReminderEnabled,
      'restReminderMinutes': settings.restReminderMinutes,
      'highlightColor': settings.highlightColor,
      'scrollDirection': settings.scrollDirection,
    };
    await prefs.setString(_settingsKey, json.encode(settingsMap));
  }

  // Highlights
  static Future<List<EbookHighlight>> getHighlights(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = prefs.getString('${_highlightsKey}_$bookId');

    if (highlightsJson != null) {
      final List<dynamic> highlightsList = json.decode(highlightsJson);
      return highlightsList
          .map(
            (json) => EbookHighlight(
              id: json['id'],
              text: json['text'],
              pageNumber: json['pageNumber'],
              note: json['note'],
              createdAt: DateTime.parse(json['createdAt']),
              color: json['color'] ?? '#FFFF00',
            ),
          )
          .toList();
    }

    return [];
  }

  static Future<void> saveHighlight(
    String bookId,
    EbookHighlight highlight,
  ) async {
    final highlights = await getHighlights(bookId);
    highlights.add(highlight);

    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = json.encode(
      highlights
          .map(
            (h) => {
              'id': h.id,
              'text': h.text,
              'pageNumber': h.pageNumber,
              'note': h.note,
              'createdAt': h.createdAt.toIso8601String(),
              'color': h.color,
            },
          )
          .toList(),
    );

    await prefs.setString('${_highlightsKey}_$bookId', highlightsJson);
  }

  static Future<void> updateHighlight(
    String bookId,
    EbookHighlight highlight,
  ) async {
    final highlights = await getHighlights(bookId);
    final index = highlights.indexWhere((h) => h.id == highlight.id);
    
    if (index != -1) {
      highlights[index] = highlight;
      
      final prefs = await SharedPreferences.getInstance();
      final highlightsJson = json.encode(
        highlights
            .map(
              (h) => {
                'id': h.id,
                'text': h.text,
                'pageNumber': h.pageNumber,
                'note': h.note,
                'createdAt': h.createdAt.toIso8601String(),
                'color': h.color,
              },
            )
            .toList(),
      );

      await prefs.setString('${_highlightsKey}_$bookId', highlightsJson);
    }
  }

  static Future<void> deleteHighlight(String bookId, String highlightId) async {
    final highlights = await getHighlights(bookId);
    highlights.removeWhere((h) => h.id == highlightId);

    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = json.encode(
      highlights
          .map(
            (h) => {
              'id': h.id,
              'text': h.text,
              'pageNumber': h.pageNumber,
              'note': h.note,
              'createdAt': h.createdAt.toIso8601String(),
              'color': h.color,
            },
          )
          .toList(),
    );

    await prefs.setString('${_highlightsKey}_$bookId', highlightsJson);
  }

  static Future<String> exportHighlightsToJson(String bookId) async {
    final highlights = await getHighlights(bookId);
    
    final exportData = {
      'bookId': bookId,
      'exportDate': DateTime.now().toIso8601String(),
      'totalHighlights': highlights.length,
      'highlights': highlights
          .map(
            (h) => {
              'id': h.id,
              'text': h.text,
              'pageNumber': h.pageNumber,
              'note': h.note,
              'createdAt': h.createdAt.toIso8601String(),
              'color': h.color,
            },
          )
          .toList(),
    };
    
    return json.encode(exportData);
  }

  static Future<String> exportHighlightsToText(String bookId) async {
    final highlights = await getHighlights(bookId);
    
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('HIGHLIGHTS EXPORT');
    buffer.writeln('Book: $bookId');
    buffer.writeln('Date: ${DateTime.now().toString()}');
    buffer.writeln('Total: ${highlights.length} highlights');
    buffer.writeln('═══════════════════════════════════════\n');
    
    for (var i = 0; i < highlights.length; i++) {
      final h = highlights[i];
      buffer.writeln('${i + 1}. [Page ${h.pageNumber}] - ${h.color}');
      buffer.writeln('   "${h.text}"');
      if (h.note != null && h.note!.isNotEmpty) {
        buffer.writeln('   Note: ${h.note}');
      }
      buffer.writeln('   Created: ${h.createdAt}');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  // Reading progress
  static Future<EbookReadingProgress?> getReadingProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('${_progressKey}_$bookId');

    if (progressJson == null) {
      return null;
    }

    try {
      final progressMap = json.decode(progressJson);
      final pageNumber = progressMap['pageNumber'] is num
          ? (progressMap['pageNumber'] as num).round()
          : 1;
      final chapterIndex = progressMap['chapterIndex'] is num
          ? (progressMap['chapterIndex'] as num).round()
          : null;
      final updatedAt = progressMap['updatedAt'] is String
          ? DateTime.tryParse(progressMap['updatedAt'] as String) ??
                DateTime.now()
          : DateTime.now();

      return EbookReadingProgress(
        pageNumber: pageNumber > 0 ? pageNumber : 1,
        chapterIndex: chapterIndex,
        updatedAt: updatedAt,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveReadingProgress(
    String bookId,
    EbookReadingProgress progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode({
      'pageNumber': progress.pageNumber,
      'chapterIndex': progress.chapterIndex,
      'updatedAt': progress.updatedAt.toIso8601String(),
    });

    await prefs.setString('${_progressKey}_$bookId', data);
  }
}
