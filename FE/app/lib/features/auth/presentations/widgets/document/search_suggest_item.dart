import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';

class SearchSuggestionItem extends StatelessWidget {
  final DocumentEntity document;
  final VoidCallback onTap;

  const SearchSuggestionItem({
    super.key,
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          document.title,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
