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
    return Scaffold(
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
              // Check bookmarked status directly from Bloc state for real-time UI update
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
                    // Lưu trạng thái trước khi toggle
                    final wasBookmarked = isBookmarked;
                    
                    context.read<WishlistBloc>().add(WishlistItemToggled(item));
                    
                    // Hiển thị thông báo sau khi build phase hoàn thành
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (wasBookmarked) {
                        NotificationService.showInfo(
                          context,
                          message: 'Đã bỏ khỏi yêu thích',
                        );
                      } else {
                        NotificationService.showSuccess(
                          context,
                          message: 'Đã thêm vào yêu thích',
                        );
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
        onRefresh: _loadDocumentDetail,
        color: _primaryColor,
        child: _buildBody(),
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          _buildInfo(),
          _buildActions(),
          _buildDescription(),
          _buildDetails(),
          // Thêm widget hiển thị sách tương tự
          SimilarBooksModelWidget(
            similarBooks: _vm.similarBooks,
            isLoading: _vm.isSimilarLoading,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _vm.coverPhoto,
                fit: BoxFit.cover,
                cacheKey: 'doc_detail_${_vm.documentId}',
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryColor.withOpacity(0.1),
                        _primaryColor.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryColor.withOpacity(0.25),
                          _primaryColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.book_rounded,
                      size: 42,
                      color: _primaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _vm.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textColor,
                    height: 1.35,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Debug: Hiển thị trạng thái ebook (có thể ẩn sau khi debug xong)
                // if (_document!.ebookUrl == null || _document!.ebookUrl!.isEmpty)
                //   Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 8,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.orange.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(6),
                //       border: Border.all(color: Colors.orange, width: 1),
                //     ),
                //     child: const Text(
                //       '⚠️ Không có phiên bản điện tử',
                //       style: TextStyle(
                //         fontSize: 11,
                //         color: Colors.orange,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   )
                // else
                //   Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 8,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Colors.green.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(6),
                //       border: Border.all(color: Colors.green, width: 1),
                //     ),
                //     child: Text(
                //       '✓ Có ebook: ${_document!.ebookUrl!.substring(0, _document!.ebookUrl!.length > 40 ? 40 : _document!.ebookUrl!.length)}${_document!.ebookUrl!.length > 40 ? '...' : ''}',
                //       style: const TextStyle(
                //         fontSize: 11,
                //         color: Colors.green,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //   ),
                // const SizedBox(height: 8),
                Text(
                  _vm.authors
                          .where((author) => author['role'] == 'main')
                          .map((author) => '${author['fullName'] ?? ''} ')
                          .firstOrNull ??
                      'Không có tác giả chính',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isVerySmallScreen = screenWidth < 250;
                    final isSmallScreen = screenWidth < 300;
                    final isMediumScreen = screenWidth < 350;
                    
                    // Responsive values
                    final iconSize = isVerySmallScreen ? 15.0 : (isSmallScreen ? 16.0 : 18.0);
                    final fontSize = isVerySmallScreen ? 10.0 : (isSmallScreen ? 11.0 : (isMediumScreen ? 11.5 : 12.0));
                    final verticalPadding = isVerySmallScreen ? 6.0 : (isSmallScreen ? 7.0 : 9.0);
                    final horizontalPadding = isVerySmallScreen ? 8.0 : (isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0));
                    final spacing = isVerySmallScreen ? 5.0 : (isSmallScreen ? 6.0 : 10.0);
                    
                    return Row(
                      children: [
                        Flexible(
                          flex: _vm.ebookUrl != null ? 1 : 1,
                          child: ElevatedButton.icon(
                            onPressed: _vm.ebookUrl != null ? _readNow : null,
                            icon: Icon(Icons.play_arrow, size: iconSize),
                            label: Text(
                              'ĐỌC NGAY',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: verticalPadding,
                                horizontal: horizontalPadding,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: _primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        SizedBox(width: spacing),
                        if (_vm.ebookUrl != null)
                          Flexible(
                            flex: 1,
                            child: OutlinedButton.icon(
                              onPressed: _downloadEbook,
                              icon: Icon(Icons.download_outlined, size: iconSize),
                              label: Text(
                                isVerySmallScreen ? 'TẢI' : 'TẢI EBOOK',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(
                                  color: _primaryColor,
                                  width: 1.5,
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: verticalPadding,
                                  horizontal: horizontalPadding * 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final horizontalPadding = isSmallScreen ? 8.0 : 12.0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _buildInfoItem('Tổng', '${_vm.totalCopies}', isSmallScreen)),
              Container(width: 1, height: 34, color: Colors.grey[200]),
              Expanded(child: _buildInfoItem('Hiện có', '${_vm.availableCopies}', isSmallScreen)),
              Container(width: 1, height: 34, color: Colors.grey[200]),
              Expanded(
                child: _buildInfoItem(
                  'Cho mượn',
                  '${_vm.totalCopies - _vm.availableCopies}',
                  isSmallScreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 17 : 19,
            fontWeight: FontWeight.w800,
            color: _primaryColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Expanded(
          //   child: ElevatedButton.icon(
          //     onPressed: _document!.ebookUrl != null ? _downloadEbook : null,
          //     icon: const Icon(Icons.download, size: 20),
          //     label: const Text('Tải xuống'),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppPalette.gradient1,
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //   ),
          // ),
          // Expanded(
          //   child: ElevatedButton.icon(
          //     onPressed: _document!.ebookUrl != null ? _readNow : null,
          //     icon: const Icon(Icons.play_arrow, size: 20),
          //     label: const Text('Đọc ngay'),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.green,
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 12),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            padding: const EdgeInsets.all(14),
            child: Text(
              _vm.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      margin: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_vm.availableCopies > 0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                label: const Text('Thêm vào giỏ sách'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: _primaryColor.withOpacity(0.3),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Nhà xuất bản', _vm.publisher['name'] ?? ''),
          _buildDetailRow('Năm xuất bản', _vm.publicationYear.toString()),
          _buildDetailRow('Thể loại', _vm.category['name'] ?? ''),
          _buildDetailRow('Ngôn ngữ', _vm.language),
          if (_vm.minDeposit != null && _vm.maxDeposit != null)
            _buildDetailRow(
              'Tiền cọc',
              '${_formatCurrency(_vm.minDeposit!)} - ${_formatCurrency(_vm.maxDeposit!)}',
            ),

          // _buildDetailRow(
          //   'Giá bìa',
          //   '${_document!.coverPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ',
          // ),
          // if (_document!.book != null) ...[
          //   _buildDetailRow('ISBN', _document!.book!['isbn'] ?? ''),
          //   _buildDetailRow(
          //     'Số trang',
          //     '${_document!.book!['pageCount'] ?? 0}',
          //   ),
          //   _buildDetailRow(
          //     'Lần tái bản',
          //     '${_document!.book!['edition'] ?? 0}',
          //   ),
          // ],
          // _buildDetailRow(
          //   'Thể loại con',
          //   _document!.genres.map((g) => g['name'] ?? '').join(', '),
          // ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
