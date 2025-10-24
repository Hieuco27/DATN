// lib/features/auth/presentations/widgets/home/category_section.dart
import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/domain/entities/genre_entity.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';
import 'package:book_tech/features/auth/presentations/widgets/document/document_item.dart';

class CategorySection extends StatelessWidget {
  final GenreEntity genre;
  final List<DocumentEntity> documents;
  final VoidCallback? onViewAll;

  const CategorySection({
    super.key,
    required this.genre,
    required this.documents,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với tên thể loại và nút "Tất cả"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                genre.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'Tất cả >',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(135, 0, 0, 0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Danh sách sách ngang
        SizedBox(
          height: 100, // Chiều cao cho mỗi item
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return DocumentItem(document: documents[index]);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
