import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import 'document_detail_page.dart';

class MostBorrowedDocumentsPage extends StatefulWidget {
  const MostBorrowedDocumentsPage({super.key});

  @override
  State<MostBorrowedDocumentsPage> createState() =>
      _MostBorrowedDocumentsPageState();
}

class _MostBorrowedDocumentsPageState extends State<MostBorrowedDocumentsPage> {
  List<DocumentEntity> _documents = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreDocuments();
    }
  }

  Future<void> _loadDocuments({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _documents = [];
      });
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated ||
        authState.account.accessToken?.isEmpty == true) {
      setState(() {
        _error = 'Vui lòng đăng nhập để xem sách được mượn nhiều nhất';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = Provider.of<DocumentRepository>(
        context,
        listen: false,
      );
      final documents = await repository.getMostBorrowedDocuments(
        accessToken: authState.account.accessToken!,
        page: _page,
        limit: _limit,
        documentType: 'book',
      );

      setState(() {
        if (refresh) {
          _documents = documents;
        } else {
          _documents.addAll(documents);
        }
        _hasMore = documents.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'Không thể tải danh sách sách được mượn nhiều nhất: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreDocuments() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _page++;
    });

    await _loadDocuments();
  }

  Future<void> _refresh() async {
    await _loadDocuments(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sách Được Mượn Nhiều Nhất',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (_error != null && _documents.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1744),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Thử lại',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_isLoading && _documents.isEmpty) {
            return _buildLoadingGrid();
          }

          if (_documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFFFF1744),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index >= _documents.length) {
                        return _hasMore
                            ? _buildLoadingCard()
                            : const SizedBox.shrink();
                      }
                      return _buildDocumentCard(_documents[index], index + 1);
                    }, childCount: _documents.length + (_hasMore ? 2 : 0)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(DocumentEntity document, int rank) {
    // Sử dụng borrowCount từ Entity (đã được map từ API)
    final borrowCount = document.borrowCount ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DocumentDetailPage(documentId: document.documentId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Rank Badge
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.purple[100]!, Colors.blue[100]!],
                        ),
                      ),
                      child:
                          document.coverPhoto == null ||
                              document.coverPhoto!.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.book_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: document.coverPhoto!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Rank Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? const Color(0xFFFFD700) // Gold for top 3
                            : Colors.orange[300]!,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '#$rank',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3 ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title and Borrow Count
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E1E1E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Borrow Count
                    Row(
                      children: [
                        Icon(
                          Icons.local_library_rounded,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$borrowCount lượt mượn',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildLoadingCard(),
    );
  }
}
