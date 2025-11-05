import 'package:flutter/material.dart';

class EpubDarkThemed extends StatelessWidget {
  const EpubDarkThemed({super.key, required this.enabled, required this.epubWidget});

  final bool enabled;
  final Widget epubWidget;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return epubWidget;
    final base = Theme.of(context);
    final dark = base.copyWith(
      brightness: Brightness.dark,
      colorScheme: base.colorScheme.copyWith(brightness: Brightness.dark),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
    return Theme(data: dark, child: epubWidget);
  }
}


