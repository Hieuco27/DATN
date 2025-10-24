// lib/features/auth/presentations/pages/type_categories_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentations/providers/document_provider.dart';
import '../../data/models/document_response_model.dart';
import '../widgets/document/document_item.dart';

class TypeCategoriesPage extends StatelessWidget {
  final String type; // 'book' | 'magazine' | 'newspaper'
  const TypeCategoriesPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DocumentProvider>();
    final list = switch (type) {
      'book' => p.books,
      'magazine' => p.magazines,
      _ => p.newspapers,
    };
    final grouped = p.groupByCategoryName(list);

    return Scaffold(
      appBar: AppBar(title: Text(_title(type))),
      body: grouped.isEmpty
          ? const Center(child: Text('Không có dữ liệu'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.map((e) {
                final catName = e.key;
                final items = e.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(catName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.58,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (_, i) =>
                          DocumentItem.fromReader(items[i]),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
            ),
    );
  }

  String _title(String t) =>
      t == 'book' ? 'Sách' : t == 'magazine' ? 'Tạp chí' : 'Báo';
}