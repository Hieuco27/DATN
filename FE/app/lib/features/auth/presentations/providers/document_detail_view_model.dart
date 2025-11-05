import 'package:flutter/foundation.dart';

import '../../domain/repositories/document_repository.dart';
import '../../data/models/document_detail_model.dart';
import '../../data/models/document_response_model.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../../data/models/cart_item_model.dart';

class DocumentDetailViewModel extends ChangeNotifier {
  DocumentDetailViewModel({required this.repository});

  final DocumentRepository repository;

  bool _isLoading = true;
  bool _isSimilarLoading = false;
  String? _error;
  DocumentDetailModel? _document;
  List<DocumentResponseModel> _similarBooks = <DocumentResponseModel>[];
  bool _isBookmarked = false;
  int _quantity = 1;

  bool get isLoading => _isLoading;
  bool get isSimilarLoading => _isSimilarLoading;
  String? get error => _error;
  bool get isBookmarked => _isBookmarked;
  int get quantity => _quantity;

  // Expose only the fields UI needs, not the whole data model
  String get title => _document?.title ?? '';
  String get coverPhoto => _document?.coverPhoto ?? '';
  int get documentId => _document?.documentId ?? 0;
  int get totalCopies => _document?.totalCopies ?? 0;
  int get availableCopies => _document?.availableCopies ?? 0;
  String? get ebookUrl => _document?.ebookUrl;
  String get description => _document?.description ?? '';
  Map<String, dynamic> get publisher => _document?.publisher ?? const {};
  int get publicationYear => _document?.publicationYear ?? 0;
  Map<String, dynamic> get category => _document?.category ?? const {};
  String get language => _document?.language ?? '';
  int? get minDeposit => _document?.minDeposit;
  int? get maxDeposit => _document?.maxDeposit;
  List<Map<String, dynamic>> get authors => _document?.authors ?? const [];

  List<DocumentResponseModel> get similarBooks => _similarBooks;

  Future<void> load({
    required String accessToken,
    required int documentId,
    required WishlistProvider wishlist,
  }) async {
    _isLoading = true;
    _error = null;
    _similarBooks = <DocumentResponseModel>[];
    notifyListeners();
    try {
      final doc = await repository.getDocumentDetail(
        accessToken: accessToken,
        documentId: documentId,
      );
      _document = doc;
      _isBookmarked = wishlist.contains(doc.documentId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSimilar({
    required String accessToken,
    required int documentId,
  }) async {
    _isSimilarLoading = true;
    notifyListeners();
    try {
      final entities = await repository.getSimilarDocuments(
        accessToken: accessToken,
        documentId: documentId,
        limit: 10,
      );
      _similarBooks = entities
          .map(
            (e) => DocumentResponseModel(
              documentId: e.documentId,
              title: e.title,
              coverPhoto: e.coverPhoto,
              minDeposit: 0,
              maxDeposit: 0,
              coverPrice: e.coverPrice ?? 0,
              categoryName: '',
              depositRate: 0.0,
              totalCopies: e.numberOfCopy,
              availableCopies: e.numberOfCopy,
              documentType: 'book',
              borrowCount: 0,
            ),
          )
          .toList();
    } catch (_) {
      // ignore errors for similar list
    } finally {
      _isSimilarLoading = false;
      notifyListeners();
    }
  }

  void toggleWishlist(WishlistProvider wishlist) {
    if (_document == null) return;
    wishlist.toggle(
      WishlistItem(
        documentId: _document!.documentId,
        title: _document!.title,
        coverPhoto: _document!.coverPhoto,
      ),
    );
    _isBookmarked = wishlist.contains(_document!.documentId);
    notifyListeners();
  }

  bool addToCart(CartProvider cart) {
    if (_document == null) return false;
    final id = _document!.documentId;
    if (cart.hasItem(id)) return false;
    cart.addItem(
      CartItemModel(
        documentId: id,
        title: _document!.title,
        coverPhoto: _document!.coverPhoto,
        quantity: _quantity,
        minDeposit: _document!.minDeposit,
        maxDeposit: _document!.maxDeposit,
      ),
    );
    _quantity = 1;
    notifyListeners();
    return true;
  }

  void setQuantity(int value) {
    _quantity = value < 1 ? 1 : value;
    notifyListeners();
  }
}
