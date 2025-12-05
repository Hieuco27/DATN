import 'package:book_tech/features/auth/presentations/pages/ebook_reader_page.dart';
import 'package:book_tech/features/auth/data/models/document_detail_model.dart';
import 'package:book_tech/features/auth/presentations/widgets/document/similar_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/auth/domain/repositories/document_repository.dart';
import '../bloc/auth_bloc.dart';
import 'package:provider/provider.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/core/ui/notification_service.dart';
import '../bloc/reading_bloc.dart';
import '../bloc/reading_event.dart';
import '../providers/reading_provider.dart'; // For ReadingItem model
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/wishlist_bloc.dart';
import '../bloc/wishlist_event.dart';
import '../bloc/wishlist_state.dart';
import 'package:book_tech/features/auth/presentations/providers/document_detail_view_model.dart';
import 'package:book_tech/features/reviews/presentation/bloc/review_bloc.dart'; // Import for ReviewBloc and events
import 'package:book_tech/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:book_tech/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:book_tech/features/reviews/data/datasources/review_remote_data_source.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:book_tech/main.dart' show routeObserver;

class DocumentDetailPage extends StatefulWidget {
  final int documentId;

  const DocumentDetailPage({super.key, required this.documentId});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> with RouteAware {
  // Theme colors (keep consistent with other redesigned pages)
  static const Color _primaryColor = Color(0xFFFF6B35);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF1A202C);
  late final DocumentDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    final repository = Provider.of<DocumentRepository>(context, listen: false);
    _vm = DocumentDetailViewModel(repository: repository);
    _vm.addListener(_onVmChanged);
    _loadDocumentDetail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to global route observer
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadDocumentDetail();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadDocumentDetail() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated ||
          authState.account.accessToken?.isEmpty == true) {
        throw Exception('User not authenticated');
      }
      final wishlistState = context.read<WishlistBloc>().state;
      await _vm.load(
        accessToken: authState.account.accessToken!,
        documentId: widget.documentId,
        wishlistState: wishlistState,
      );
      await _vm.loadSimilar(
        accessToken: authState.account.accessToken!,
        documentId: widget.documentId,
      );
    } catch (e) {
      NotificationService.showInfo(context, message: e.toString());
    }
  }

  // Thêm method để load similar books
  // removed: handled inside view model

  @override
  Widget build(BuildContext context) {
    // Wrap with Review Provider & Bloc to share state between Header and ReviewsSection
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final accessToken = (authState is AuthAuthenticated) ? authState.account.accessToken ?? '' : '';
        
        return RepositoryProvider(
          create: (context) => ReviewRepositoryImpl(
            remoteDataSource: ReviewRemoteDataSourceImpl(
              client: http.Client(),
            ),
          ),
          child: BlocProvider(
            create: (context) => ReviewBloc(
              repository: context.read<ReviewRepositoryImpl>(),
            )..add(LoadReviews(documentId: widget.documentId, accessToken: accessToken)),
            child: Scaffold(
              backgroundColor: _backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: _textColor,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _vm.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                actions: [
                  if (_vm.ebookUrl != null)
                    IconButton(
                      tooltip: 'Tải ebook',
                      icon: const Icon(
                        Icons.download_for_offline_outlined,
                        color: _textColor,
                        size: 22,
                      ),
                      onPressed: _downloadEbook,
                    ),
                  IconButton(
                    tooltip: 'Chia sẻ',
                    icon: const Icon(Icons.ios_share, color: _textColor, size: 20),
                    onPressed: _shareDocument,
                  ),
                  BlocBuilder<WishlistBloc, WishlistState>(
                    builder: (context, wishlistState) {
                      final isBookmarked = _vm.documentId > 0 && 
                          wishlistState is WishlistData && 
                          wishlistState.contains(_vm.documentId);
                      
                      return IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.favorite : Icons.favorite_border,
                          color: isBookmarked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          final item = _vm.getWishlistItem();
                          if (item != null) {
                            final wasBookmarked = isBookmarked;
                            context.read<WishlistBloc>().add(WishlistItemToggled(item));
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              if (wasBookmarked) {
                                NotificationService.showInfo(context, message: 'Đã bỏ khỏi yêu thích');
                              } else {
                                NotificationService.showSuccess(context, message: 'Đã thêm vào yêu thích');
                              }
                            });
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  await _loadDocumentDetail();
                  // Refresh reviews too
                  if (context.mounted) {
                    context.read<ReviewBloc>().add(LoadReviews(documentId: widget.documentId, accessToken: accessToken));
                  }
                },
                color: _primaryColor,
                child: _buildBody(),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildBody() {
    const SizedBox(height: 30);
    if (_vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải thông tin tài liệu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _vm.error!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDocumentDetail,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Thử lại',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: _primaryColor.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_vm.title.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildDetails(),
          const SizedBox(height: 16),
          _buildDescription(),
          const SizedBox(height: 16),
          // Thêm ReviewsSection
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              int? currentReaderId;
              String accessToken = '';
              
              if (authState is AuthAuthenticated) {
                accessToken = authState.account.accessToken ?? '';
                currentReaderId = authState.account.readerId;
              }
              
              return ReviewsSection(
                documentId: widget.documentId,
                accessToken: accessToken,
                currentUserId: currentReaderId,
              );
            },
          ),
          const SizedBox(height: 16),
          // Thêm widget hiển thị sách tương tự
          SimilarBooksModelWidget(
            similarBooks: _vm.similarBooks,
            isLoading: _vm.isSimilarLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child, String? title, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 90,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),  
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _vm.coverPhoto,
                    fit: BoxFit.cover,
                    cacheKey: 'doc_detail_${_vm.documentId}',
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.book, color: _primaryColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vm.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _vm.authors
                          .where((author) => author['role'] == 'main')
                          .map((author) => '${author['fullName'] ?? ''} ')
                          .firstOrNull ??
                      'Không có tác giả chính',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 113, 113, 113),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Rating and Availability Row
                Row(
                  children: [
                    // Sẵn có
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sẵn có: ${_vm.availableCopies}/${_vm.totalCopies}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rating from Bloc
                    BlocBuilder<ReviewBloc, ReviewState>(
                      builder: (context, state) {
                        if (state is ReviewLoaded) {
                          return Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                state.stats.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                ),
                              ),
                              Text(
                                ' (${state.stats.totalReviews})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_vm.ebookUrl != null || _vm.availableCopies > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (_vm.ebookUrl != null)
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: _readNow,
                                label: const Text(
                                  'Đọc ngay', 
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 53, 110, 255),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        if (_vm.ebookUrl != null && _vm.availableCopies > 0)
                          const SizedBox(width: 8),
                        if (_vm.availableCopies > 0)
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: _addToCart,
                                icon: const Icon(Icons.add_shopping_cart_rounded, size: 12),
                                label: const Text(
                                  'Thêm sách', 
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 5, 97, 63),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDescription() {
    return _buildSection(
      title: 'Mô tả nội dung',
      child: Text(
        _vm.description,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.6,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
    
  Widget _buildDetails() {
    return _buildSection(
      child: Column(
        children: [
          _buildDetailRow('Nhà xuất bản:', _vm.publisher['name'] ?? ''),
          _buildDetailRow('Năm xuất bản:', _vm.publicationYear.toString()),
          _buildDetailRow('Thể loại:', _vm.category['name'] ?? ''),
          _buildDetailRow('Ngôn ngữ:', _vm.language),
          if (_vm.minDeposit != null && _vm.maxDeposit != null)
            _buildDetailRow(
              'Tiền cọc',
              '${_formatCurrency(_vm.minDeposit!)} - ${_formatCurrency(_vm.maxDeposit!)}',
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: _textColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadEbook() async {
    if (_vm.ebookUrl == null) return;
    final uri = Uri.tryParse(_vm.ebookUrl!);
    if (uri == null) return;
    final can = await canLaunchUrl(uri);
    if (can) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationService.showInfo(
        context,
        message: 'Không mở được liên kết tải xuống',
      );
    }
  }

  void _shareDocument() async {
    final title = _vm.title;
    final link = _vm.ebookUrl ?? '';
    final shareText = link.isNotEmpty ? '$title\n$link' : title;
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    NotificationService.showSuccess(context, message: 'Đã sao chép để chia sẻ');
  }

  // Thay thế method _readNow hiện tại
  void _readNow() {
    if (_vm.ebookUrl == null) {
      NotificationService.showInfo(
        context,
        message: 'Tài liệu này không có phiên bản điện tử',
      );
      return;
    }

    // Lưu vào danh sách đang đọc
    context.read<ReadingBloc>().add(
      ReadingItemAddedOrUpdated(
        ReadingItem(
          documentId: _vm.documentId,
          title: _vm.title,
          coverPhoto: _vm.coverPhoto,
          ebookUrl: _vm.ebookUrl!,
          startedAt: DateTime.now(),
        ),
      ),
    );

    // Navigate trực tiếp đến EbookReaderPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EbookReaderPage(
          document: DocumentDetailModel(
            documentId: _vm.documentId,
            documentType: 'book',
            title: _vm.title,
            language: _vm.language,
            publicationYear: _vm.publicationYear,
            coverPrice: 0,
            description: _vm.description,
            coverPhoto: _vm.coverPhoto,
            ebookUrl: _vm.ebookUrl,
            numberOfCopy: _vm.totalCopies,
            category: _vm.category,
            publisher: _vm.publisher,
            book: null,
            magazine: null,
            newspaper: null,
            authors: _vm.authors,
            genres: const [],
            copies: const [],
            totalCopies: _vm.totalCopies,
            availableCopies: _vm.availableCopies,
            availableCopiesEffective: _vm.availableCopies,
            minDeposit: _vm.minDeposit,
            maxDeposit: _vm.maxDeposit,
            shelfLocation: null,
          ),
          ebookUrl: _vm.ebookUrl!,
        ),
      ),
    );
  }

  void _addToCart() {
    final cartState = context.read<CartBloc>().state;
    final cartItem = _vm.getCartItem(cartState);
    
    if (cartItem == null) {
      NotificationService.showInfo(
        context,
        message: 'Sách đã có trong giỏ hàng',
      );
      return;
    }
    
    context.read<CartBloc>().add(CartItemAdded(cartItem));
    _vm.resetQuantity();
    
    NotificationService.showSuccess(
      context,
      message: 'Đã thêm sách vào giỏ',
    );
  }
}

String _formatCurrency(int amount) {
  return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} đ';
}

// removed unused extension helpers
