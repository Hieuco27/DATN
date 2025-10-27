import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/data/models/ebook_model.dart';

class EbookHighlightsPanel extends StatelessWidget {
  final List<EbookHighlight> highlights;
  final Function(EbookHighlight) onHighlightTap;
  final Function(String) onDeleteHighlight;

  const EbookHighlightsPanel({
    super.key,
    required this.highlights,
    required this.onHighlightTap,
    required this.onDeleteHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh dấu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${highlights.length} đánh dấu',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: highlights.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.highlight_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có đánh dấu nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chọn văn bản để tạo đánh dấu',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: highlights.length,
                    itemBuilder: (context, index) {
                      final highlight = highlights[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _parseColor(highlight.color),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(
                            highlight.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Trang ${highlight.pageNumber}'),
                              if (highlight.note != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  highlight.note!,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                onDeleteHighlight(highlight.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Xóa'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => onHighlightTap(highlight),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.yellow;
    }
  }
}
