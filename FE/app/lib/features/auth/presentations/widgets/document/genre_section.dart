import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/presentations/providers/document_provider.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_book_page.dart';
import 'package:book_tech/features/auth/presentations/pages/document_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
// dang sách sách trong trang chủ 
class GenreSectionWidget extends StatefulWidget {
  final GenreModel genre;
  final DocumentProvider documentProvider;

  const GenreSectionWidget({
    Key? key,
    required this.genre,
    required this.documentProvider,
  }) : super(key: key);

  @override
  State<GenreSectionWidget> createState() => _GenreSectionWidgetState();
}

class _GenreSectionWidgetState extends State<GenreSectionWidget> {
  List<DocumentEntity> _documents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_documents.isEmpty && !_isLoading) {
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authBloc = context.read<AuthBloc>();
      if (authBloc.state is AuthAuthenticated) {
        final authState = authBloc.state as AuthAuthenticated;
        _documents = await widget.documentProvider.getDocumentsByGenre(
          accessToken: authState.account.accessToken!,
          genreId: widget.genre.genreId,
          limit: 10, // Lấy 10 sách đầu tiên
        );
      }
    } catch (e) {
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với tên genre và nút "Tất cả"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.genre.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E1E),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenreBooksPage(
                      genreName: widget.genre.name,
                      genreId: widget.genre.genreId,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: const Color(0xFFFF1744),
                backgroundColor: const Color(0x1AFF1744),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tất cả',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFFFF1744),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Color(0xFFFF1744),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Danh sách sách ngang
        SizedBox(
          height: 208,
          child: _isLoading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                )
              : _documents.isEmpty
              ? const Center(
                  child: Text(
                    'Không có tài liệu nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _documents.length > 6 ? 6 : _documents.length,
                  itemBuilder: (context, index) {
                    final document = _documents[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentDetailPage(
                              documentId: document.documentId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Hình ảnh sách
                            Hero(
                              tag:
                                  'g${widget.genre.genreId}_doc_${document.documentId}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 140,
                                  width: 124,
                                  decoration: const BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x11000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: document.coverPhoto == null
                                      ? Container(
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.book_rounded,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: document.coverPhoto!,
                                          cacheKey:
                                              '${document.documentId}_${document.coverPhoto}',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                                baseColor: Colors.grey.shade300,
                                                highlightColor:
                                                    Colors.grey.shade100,
                                                child: Container(
                                                  color: Colors.white,
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Tên sách
                            Text(
                              document.title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1E1E),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
