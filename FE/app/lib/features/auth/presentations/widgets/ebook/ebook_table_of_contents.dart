import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';

class EbookTableOfContents extends StatelessWidget {
  final List<EbookChapter> chapters;
  final int currentPage;
  final Function(EbookChapter) onChapterSelected;

  const EbookTableOfContents({
    super.key,
    required this.chapters,
    required this.currentPage,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mục lục',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrentChapter = chapter.pageNumber <= currentPage;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isCurrentChapter ? Colors.blue.withOpacity(0.1) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentChapter
                          ? Colors.blue
                          : Colors.grey,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontWeight: isCurrentChapter
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentChapter ? Colors.blue : null,
                      ),
                    ),
                    subtitle: Text('Trang ${chapter.pageNumber}'),
                    trailing: isCurrentChapter
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                      onChapterSelected(chapter);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
