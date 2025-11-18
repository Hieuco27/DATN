class EbookChapter {
  final String id;
  final String title;
  final int pageNumber;
  final String? content;

  EbookChapter({
    required this.id,
    required this.title,
    required this.pageNumber,
    this.content,
  });
}

class EbookReadingProgress {
  final int pageNumber;
  final int? chapterIndex;
  final DateTime updatedAt;

  EbookReadingProgress({
    required this.pageNumber,
    this.chapterIndex,
    required this.updatedAt,
  });

  EbookReadingProgress copyWith({
    int? pageNumber,
    int? chapterIndex,
    DateTime? updatedAt,
  }) {
    return EbookReadingProgress(
      pageNumber: pageNumber ?? this.pageNumber,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EbookHighlight {
  final String id;
  final String text;
  final int pageNumber;
  final String? note;
  final DateTime createdAt;
  final String color;

  EbookHighlight({
    required this.id,
    required this.text,
    required this.pageNumber,
    this.note,
    required this.createdAt,
    this.color = '#FFFF00',
  });
}

class EbookSettings {
  final double fontSize;
  final String fontFamily;
  final double lineHeight;
  final String theme;
  final bool eyeComfortEnabled;
  final double warmth;
  final double brightness;
  final bool restReminderEnabled;
  final int restReminderMinutes;
  final String highlightColor;

  EbookSettings({
    this.fontSize = 16.0,
    this.fontFamily = 'Roboto',
    this.lineHeight = 1.5,
    this.theme = 'light',
    this.eyeComfortEnabled = true,
    this.warmth = 0.35,
    this.brightness = 0.85,
    this.restReminderEnabled = true,
    this.restReminderMinutes = 30,
    this.highlightColor = '#FFF59D',
  });

  EbookSettings copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    String? theme,
    bool? eyeComfortEnabled,
    double? warmth,
    double? brightness,
    bool? restReminderEnabled,
    int? restReminderMinutes,
    String? highlightColor,
  }) {
    return EbookSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      theme: theme ?? this.theme,
      eyeComfortEnabled: eyeComfortEnabled ?? this.eyeComfortEnabled,
      warmth: warmth ?? this.warmth,
      brightness: brightness ?? this.brightness,
      restReminderEnabled: restReminderEnabled ?? this.restReminderEnabled,
      restReminderMinutes: restReminderMinutes ?? this.restReminderMinutes,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }
}
