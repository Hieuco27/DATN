import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';
import 'package:book_tech/features/auth/data/models/genre_model.dart';
import 'package:book_tech/features/auth/presentations/providers/document_provider.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/presentations/pages/genres_book_page.dart';
import 'package:book_tech/features/auth/presentations/pages/document_detail_page.dart';

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
      print('❌ Error loading documents for genre ${widget.genre.name}: $e');
    } finally {
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
            Text(
              widget.genre.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 30, 30, 30),
              ),
            ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tất cả',
                    style: TextStyle(
                      color: Color.fromARGB(255, 79, 79, 79),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color.fromARGB(255, 81, 81, 81),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Danh sách sách ngang
        SizedBox(
          height: 200,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _documents.isEmpty
              ? const Center(
                  child: Text(
                    'Không có tài liệu nào',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _documents.length,
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
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hình ảnh sách
                            Container(
                              height: 150,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.grey[200],
                                image: document.coverPhoto != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          document.coverPhoto!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: document.coverPhoto == null
                                  ? const Icon(
                                      Icons.book,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            // Tên sách
                            Text(
                              document.title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 30, 30, 30),
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
