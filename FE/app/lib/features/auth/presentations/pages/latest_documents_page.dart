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

class LatestDocumentsPage extends StatefulWidget {
  const LatestDocumentsPage({super.key});

  @override
  State<LatestDocumentsPage> createState() => _LatestDocumentsPageState();
}

class _LatestDocumentsPageState extends State<LatestDocumentsPage> {
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
        _error = 'Vui lòng đăng nhập để xem sách mới nhất';
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
      final newDocuments = await repository.getNewDocuments(
        accessToken: authState.account.accessToken!,
        page: _page,
        limit: _limit,
        documentType: 'book',
      );

      setState(() {
        if (refresh) {
          _documents = newDocuments;
        } else {
          _documents.addAll(newDocuments);
        }
        _hasMore = newDocuments.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách sách mới nhất: ${e.toString()}';
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
          'Sách Mới Nhất',
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
                    'Chưa có sách mới',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenWidth < 360;
              
              // Responsive values
              final padding = isSmallScreen ? 12.0 : 16.0;
              final crossAxisSpacing = isSmallScreen ? 12.0 : 16.0;
              final mainAxisSpacing = isSmallScreen ? 16.0 : 20.0;
              final crossAxisCount = isSmallScreen ? 2 : 2; // Keep 2 columns for better card display
              final childAspectRatio = isSmallScreen ? 0.65 : 0.64;
              
              return RefreshIndicator(
                onRefresh: _refresh,
                color: const Color(0xFFFF1744),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(padding),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: childAspectRatio,
                              crossAxisSpacing: crossAxisSpacing,
                              mainAxisSpacing: mainAxisSpacing,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index >= _documents.length) {
                            return _hasMore
                                ? _buildLoadingCard()
                                : const SizedBox.shrink();
                          }
                          return _buildDocumentCard(_documents[index]);
                        }, childCount: _documents.length + (_hasMore ? 2 : 0)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(DocumentEntity document) {
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
            // Cover Image
            Expanded(
              flex: 4,
              child: ClipRRect(
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
                            size: 54,
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
                              size: 54,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // Title
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              alignment: Alignment.topLeft,
              child: Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E1E),
                  height: 1.3,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        
        final padding = isSmallScreen ? 12.0 : 16.0;
        final crossAxisSpacing = isSmallScreen ? 12.0 : 16.0;
        final mainAxisSpacing = isSmallScreen ? 16.0 : 20.0;
        final childAspectRatio = isSmallScreen ? 0.65 : 0.64;
        
        return GridView.builder(
          padding: EdgeInsets.all(padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => _buildLoadingCard(),
        );
      },
    );
  }
}
