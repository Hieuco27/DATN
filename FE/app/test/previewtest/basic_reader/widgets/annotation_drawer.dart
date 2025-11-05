import 'package:flutter/material.dart';

import '../types.dart';

class AnnotationDrawer extends StatelessWidget {
  const AnnotationDrawer({super.key, required this.annotations});

  final List<AnnotationItem> annotations;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chú thích',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            if (annotations.isEmpty)
              const Expanded(child: Center(child: Text('Chưa có chú thích.')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: annotations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ann = annotations[index];
                    return ListTile(
                      leading: Icon(
                        ann.type == AnnotationType.highlight
                            ? Icons.highlight
                            : Icons.format_underline,
                      ),
                      title: Text(
                        ann.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(context).maybePop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đi đến vị trí chú thích chưa được gắn kết.',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AnnotationItem {
  AnnotationItem({required this.type, required this.text});

  final AnnotationType type;
  final String text;
}


