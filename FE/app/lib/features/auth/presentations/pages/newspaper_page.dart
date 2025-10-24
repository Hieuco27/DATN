// lib/features/auth/presentations/pages/newspaper_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../widgets/document/document_item.dart';

class NewspaperPage extends StatelessWidget {
  const NewspaperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo'),
        backgroundColor: const Color.fromARGB(255, 34, 133, 225),
        foregroundColor: Colors.white,
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(child: Text('Lỗi: ${provider.error}'));
          }

          final newspapers = provider.newspapers;
          if (newspapers.isEmpty) {
            return const Center(child: Text('Không có báo nào'));
          }

          // Group by category
          final grouped = provider.groupByCategoryName(newspapers);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              final categoryName = entry.key;
              final categoryNewspapers = entry.value;

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
                      itemCount: categoryNewspapers.length,
                      itemBuilder: (context, newspaperIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: DocumentItem.fromReader(categoryNewspapers[newspaperIndex]),
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