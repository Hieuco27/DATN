// lib/features/auth/presentations/widgets/document/type_section.dart
import 'package:flutter/material.dart';
import '../../../data/models/document_response_model.dart';
import 'document_item.dart';

class TypeSection extends StatelessWidget {
  final String title;
  final List<DocumentResponseModel> items;
  final VoidCallback onViewAll;

  const TypeSection({
    super.key,
    required this.title,
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: onViewAll,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Tất cả >',
                      style: TextStyle(color: Colors.black54)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => DocumentItem.fromReader(items[i]),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.length.clamp(0, 10), // preview tối đa 10
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}