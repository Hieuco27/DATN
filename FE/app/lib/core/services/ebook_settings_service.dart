import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';

class EbookSettingsService {
  static const String _settingsKey = 'ebook_settings';
  static const String _highlightsKey = 'ebook_highlights';

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
}
