// lib/features/auth/presentations/pages/book_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../widgets/document/document_item.dart';

class BookPage extends StatelessWidget {
  const BookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sách riêng biệtbiệt'),
        backgroundColor: const Color.fromARGB(255, 34, 133, 225),
        foregroundColor: Colors.white,
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, child) {
          // Thêm debug log
          print('📚 BookPage - Total books: ${provider.books.length}');
          for (var book in provider.books) {
            print('📚 Book: ${book.title} - Type: ${book.documentType}');
          }
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Lỗi: ${provider.error}'));
          }

          final books = provider.books;
          if (books.isEmpty) {
            return const Center(child: Text('Không có sách nào'));
          }

          // Group by category
          final grouped = provider.groupByCategoryName(books);
          print('📚 Grouped categories: ${grouped.keys.toList()}');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              final categoryName = entry.key;
              final categoryBooks = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryBooks.length,
                      itemBuilder: (context, bookIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: DocumentItem.fromReader(
                            categoryBooks[bookIndex],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
