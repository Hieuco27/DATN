import 'package:flutter/foundation.dart';

import '../types.dart';

class ReaderState extends ChangeNotifier {
  ReaderState({
    required DisplayMode initialDisplayMode,
    required ReadingMode initialReadingMode,
    VoidCallback? onExternalToggleDisplayMode,
  })  : _displayMode = initialDisplayMode,
        _readingMode = initialReadingMode,
        _onExternalToggle = onExternalToggleDisplayMode;

  DisplayMode _displayMode;
  ReadingMode _readingMode;
  final VoidCallback? _onExternalToggle;

  DisplayMode get displayMode => _displayMode;
  ReadingMode get readingMode => _readingMode;

  void setDisplayMode(DisplayMode mode) {
    if (_displayMode == mode) return;
    _displayMode = mode;
    notifyListeners();
  }

  void cycleDisplayMode() {
    switch (_displayMode) {
      case DisplayMode.light:
        _displayMode = DisplayMode.dark;
        break;
      case DisplayMode.dark:
        _displayMode = DisplayMode.night;
        break;
      case DisplayMode.night:
        _displayMode = DisplayMode.light;
        break;
    }
    _onExternalToggle?.call();
    notifyListeners();
  }

  void setReadingMode(ReadingMode mode) {
    if (_readingMode == mode) return;
    _readingMode = mode;
    notifyListeners();
  }

  void toggleReadingMode() {
    _readingMode = _readingMode == ReadingMode.continuous
        ? ReadingMode.singlePage
        : ReadingMode.continuous;
    notifyListeners();
  }
}


