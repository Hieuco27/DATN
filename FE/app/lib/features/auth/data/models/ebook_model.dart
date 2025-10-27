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

  EbookSettings({
    this.fontSize = 16.0,
    this.fontFamily = 'Roboto',
    this.lineHeight = 1.5,
    this.theme = 'light',
  });

  EbookSettings copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    String? theme,
  }) {
    return EbookSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      theme: theme ?? this.theme,
    );
  }
}
