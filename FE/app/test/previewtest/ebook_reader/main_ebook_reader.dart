import 'package:e_book_reader/config.dart';
import 'package:e_book_reader/e_book_reader.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pref = await SharedPreferences.getInstance();
  runApp(_EBookReaderApp(pref: pref));
}

class _EBookReaderApp extends StatelessWidget {
  const _EBookReaderApp({super.key, required this.pref});
  final SharedPreferences pref;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Book Reader Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: _EBookReaderHome(pref: pref),
    );
  }
}

class _EBookReaderHome extends StatefulWidget {
  const _EBookReaderHome({required this.pref});
  final SharedPreferences pref;

  @override
  State<_EBookReaderHome> createState() => _EBookReaderHomeState();
}

class _EBookReaderHomeState extends State<_EBookReaderHome> {
  late final ReaderController _controller;
  final Map<String, String> _chapters = {
    'Chapter 1': _sampleText,
    'Chapter 2': _sampleText,
    'Chapter 3': _sampleText,
  };
  late MapEntry<String, String> _current;
  bool _showSheet = false;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(config: ReaderConfig(axis: Axis.horizontal));
    _current = _chapters.entries.first;
    _controller.load(_current.value);
    _controller.jumpToPage(0);
  }

  void _setChapter(MapEntry<String, String> entry) {
    setState(() => _current = entry);
    _controller.load(entry.value);
    _controller.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ReaderConfig>(
      valueListenable: _controller,
      builder: (context, config, _) {
        return AnimatedBuilder(
          animation: _controller.scrollNotifier,
          builder: (context, __) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: config.backgroundColor,
                foregroundColor: config.foregroundColor,
                title: const Text('E-Book Reader'),
                actions: [
                  Row(
                    children: [
                      Text('${(_controller.rate * 100).toStringAsFixed(0)}%'),
                      const SizedBox(width: 8),
                      Text(
                        '${_controller.currentPage} / ${_controller.totalPage}',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
              drawer: Drawer(
                backgroundColor: config.backgroundColor,
                child: ListView(
                  children: _chapters.entries
                      .map(
                        (e) => ListTile(
                          title: Text(e.key),
                          onTap: () {
                            _setChapter(e);
                            Navigator.of(context).maybePop();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              backgroundColor: config.backgroundColor,
              body: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => _showSheet = !_showSheet),
                  child: ReaderContent(
                    controller: _controller,
                    coverPageBuilder: (context) => Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _controller.jumpToPage(1),
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Start Reading'),
                      ),
                    ),
                    previousPageBuilder: _current.key == _chapters.keys.first
                        ? null
                        : (context) => Center(
                            child: ElevatedButton(
                              onPressed: () {
                                final keys = _chapters.keys.toList();
                                final idx = keys.indexOf(_current.key) - 1;
                                _setChapter(_chapters.entries.elementAt(idx));
                              },
                              child: const Text('Previous Chapter'),
                            ),
                          ),
                    nextPageBuilder: (context) => Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final keys = _chapters.keys.toList();
                          final idx = keys.indexOf(_current.key) + 1;
                          if (idx < keys.length) {
                            _setChapter(_chapters.entries.elementAt(idx));
                          }
                        },
                        child: const Text('Next Chapter'),
                      ),
                    ),
                  ),
                ),
              ),
              bottomSheet: _buildSheet(config),
            );
          },
        );
      },
    );
  }

  Widget? _buildSheet(ReaderConfig config) {
    if (!_showSheet) return null;
    return Container(
      color: config.backgroundColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Axis toggle
          IconButton(
            onPressed: () => _controller.setAxis(
              config.axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
            ),
            icon: Icon(
              config.axis == Axis.horizontal
                  ? Icons.swap_vert
                  : Icons.swap_horiz,
            ),
          ),
          // Font size +/-
          IconButton(
            onPressed: () => _controller.setFontSize(config.fontSize - 1),
            icon: const Icon(Icons.text_decrease),
          ),
          IconButton(
            onPressed: () => _controller.setFontSize(config.fontSize + 1),
            icon: const Icon(Icons.text_increase),
          ),
          // Line height +/-
          IconButton(
            onPressed: () => _controller.setLineHeight(config.lineHeight - 0.1),
            icon: const Icon(Icons.format_line_spacing),
          ),
          IconButton(
            onPressed: () => _controller.setLineHeight(config.lineHeight + 0.1),
            icon: const Icon(Icons.format_line_spacing),
          ),
        ],
      ),
    );
  }
}

const String _sampleText = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. 

Suspendisse potenti. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; 
Integer non libero at sapien aliquet cursus. Curabitur nec vestibulum lorem. 
Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. 
Fusce pharetra, turpis in facilisis semper, lectus odio efficitur leo, at euismod massa magna id nisl. 
Maecenas vitae massa ut nisl fermentum porttitor.
''';
