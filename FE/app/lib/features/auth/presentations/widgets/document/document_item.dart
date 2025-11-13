// lib/features/auth/presentations/widgets/document/document_item.dart
import 'package:book_tech/features/auth/presentations/pages/document_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';
import 'package:book_tech/features/auth/data/models/document_response_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DocumentItem extends StatelessWidget {
  final DocumentEntity document;

  const DocumentItem({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Trong onTap của document item
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DocumentDetailPage(documentId: document.documentId),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh bìa sách
            Container(
              height: 150,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    document.coverPhoto != null &&
                        document.coverPhoto!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: document.coverPhoto!,
                        fit: BoxFit.cover,
                        cacheKey: 'doc_item_${document.documentId}',
                        placeholder: (context, url) => _buildLoadingImage(),
                        errorWidget: (context, url, error) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            const SizedBox(height: 8),

            // Tên sách
            Text(
              document.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color.fromARGB(255, 30, 30, 30),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // // Giá tiền (nếu có)
            // if (document.coverPrice != null && document.coverPrice! > 0)
            //   Text(
            //     '${document.coverPrice!.toString().replaceAllMapped(
            //       RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            //       (Match m) => '${m[1]},',
            //     )} VNĐ',
            //     style: const TextStyle(
            //       fontSize: 10,
            //       color: Colors.green,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.book, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  factory DocumentItem.fromReader(DocumentResponseModel m) {
    return DocumentItem(
      document: DocumentEntity(
        documentId: m.documentId,
        categoryId: 0,
        title: m.title,
        coverPhoto: m.coverPhoto,
        coverPrice: m.coverPrice,
        numberOfCopy: m.totalCopies,
      ),
    );
  }
}
