import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';

/// Wrapper widget để giữ lại font và eye comfort cho bất kỳ widget đọc EPUB
class EpubCustomizedWrapper extends StatelessWidget {
  final EbookSettings settings;
  final Widget child;

  const EpubCustomizedWrapper({
    super.key,
    required this.settings,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _applyEyeComfortFilters(_applyTheme(context, child));
  }

  /// Apply theme và font customization
  Widget _applyTheme(BuildContext context, Widget child) {
    final baseTheme = Theme.of(context);

    // Tạo theme mới với font và màu sắc tùy chỉnh
    final customTheme = baseTheme.copyWith(
      // Dark/Light mode
      brightness: settings.theme == 'dark' ? Brightness.dark : Brightness.light,

      // Text theme với font family và size
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: TextStyle(
          fontFamily: settings.fontFamily,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          color: settings.theme == 'dark' ? Colors.white : Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontFamily: settings.fontFamily,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          color: settings.theme == 'dark' ? Colors.white : Colors.black87,
        ),
        bodySmall: TextStyle(
          fontFamily: settings.fontFamily,
          fontSize: settings.fontSize * 0.9,
          height: settings.lineHeight,
          color: settings.theme == 'dark' ? Colors.white70 : Colors.black54,
        ),
      ),

      // Color scheme
      colorScheme: baseTheme.colorScheme.copyWith(
        brightness: settings.theme == 'dark'
            ? Brightness.dark
            : Brightness.light,
        surface: settings.theme == 'dark' ? Colors.grey[900]! : Colors.white,
      ),
    );

    return Theme(data: customTheme, child: child);
  }

  /// Apply eye comfort filters (warmth + brightness overlay)
  /// Giống như implementation hiện tại trong universal_ebook_reader.dart
  Widget _applyEyeComfortFilters(Widget child) {
    if (!settings.eyeComfortEnabled) {
      return child;
    }

    final warmth = settings.warmth.clamp(0.0, 1.0);
    final brightness = settings.brightness.clamp(0.0, 1.0);
    final warmOverlayOpacity = (warmth * 0.8).clamp(0.0, 0.85);
    final dimOpacity = ((1 - brightness) * 0.9).clamp(0.0, 0.85);

    return Stack(
      children: [
        child,
        // Warmth overlay (vàng ấm)
        if (warmOverlayOpacity > 0)
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: warmOverlayOpacity,
              duration: const Duration(milliseconds: 250),
              child: Container(color: const Color(0xFFF4E1A1)),
            ),
          ),
        // Brightness overlay (làm tối)
        if (dimOpacity > 0)
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: dimOpacity,
              duration: const Duration(milliseconds: 250),
              child: Container(color: Colors.black),
            ),
          ),
      ],
    );
  }
}
