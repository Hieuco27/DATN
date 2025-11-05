import '../../domain/entities/document_entity.dart';
import '../../domain/entities/genre_entity.dart';

class DocumentResponseModel {
  final int documentId;
  final String title;
  final String? coverPhoto;
  final int minDeposit;
  final int maxDeposit;
  final int coverPrice;
  final String categoryName;
  final double depositRate;
  final int totalCopies;
  final int availableCopies;
  final String documentType;
  final int borrowCount; // hoặc totalBorrows
  DocumentResponseModel({
    required this.documentId,
    required this.title,
    this.coverPhoto,
    required this.minDeposit,
    required this.maxDeposit,
    required this.coverPrice,
    required this.categoryName,
    required this.depositRate,
    required this.totalCopies,
    required this.availableCopies,
    required this.documentType,
    required this.borrowCount,
  });

  factory DocumentResponseModel.fromJson(Map<String, dynamic> json) {
    return DocumentResponseModel(
      documentId: json['documentId'] ?? 0,
      title: json['title'] ?? '',
      coverPhoto: json['coverPhoto'],
      minDeposit: json['minDeposit'] ?? 0,
      maxDeposit: json['maxDeposit'] ?? 0,
      coverPrice: json['coverPrice'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      depositRate: (json['depositRate'] ?? 0.0).toDouble(),
      totalCopies: json['totalCopies'] ?? 0,
      availableCopies: json['availableCopies'] ?? 0,
      documentType: json['documentType'] ?? 'book',
      borrowCount: json['totalBorrow'] ?? 0, // API trả về totalBorrow
    );
  }

  // Thêm method này để convert sang DocumentEntity
  DocumentEntity toEntity() {
    return DocumentEntity(
      documentId: documentId,
      categoryId: 0, // Không có trong API response
      title: title,
      coverPhoto: coverPhoto,
      coverPrice: coverPrice,
      numberOfCopy: totalCopies,
      borrowCount: borrowCount,
      // Truyền borrowCount vào Entity
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'title': title,
      'coverPhoto': coverPhoto,
      'minDeposit': minDeposit,
      'maxDeposit': maxDeposit,
      'coverPrice': coverPrice,
      'categoryName': categoryName,
      'depositRate': depositRate,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'documentType': documentType,
      'borrowCount': borrowCount,
    };
  }

  // Thêm constructor từ DocumentEntity
  factory DocumentResponseModel.fromEntity(
    DocumentEntity entity, {
    String categoryName = '',
    int minDeposit = 0,
    int maxDeposit = 0,
    double depositRate = 0.0,
    int totalCopies = 0,
    int availableCopies = 0,
    String documentType = 'book',
    int borrowCount = 0,
  }) {
    return DocumentResponseModel(
      documentId: entity.documentId,
      title: entity.title,
      coverPhoto: entity.coverPhoto,
      minDeposit: minDeposit,
      maxDeposit: maxDeposit,
      coverPrice: entity.coverPrice ?? 0,
      categoryName: categoryName,
      depositRate: depositRate,
      totalCopies: totalCopies > 0 ? totalCopies : entity.numberOfCopy,
      availableCopies: availableCopies > 0
          ? availableCopies
          : entity.numberOfCopy,
      documentType: documentType,
      borrowCount: borrowCount,
    );
  }
}
