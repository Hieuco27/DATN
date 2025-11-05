import 'package:flutter/material.dart';

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, this.onSelectDemo});

  final VoidCallback? onSelectDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.menu_book, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Chưa có file. Hãy truyền 1 file PDF/EPUB vào ReadBook hoặc chỉnh main.dart để chọn đường dẫn thử nghiệm.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSelectDemo,
              icon: const Icon(Icons.file_open),
              label: const Text('Hướng dẫn chạy thử'),
            ),
          ],
        ),
      ),
    );
  }
}


