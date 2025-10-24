class DocumentEntity {
  final int documentId;
  final int categoryId;
  final int? publisherId;
  final String title;
  final String? language;
  final int? publicationYear;
  final int? coverPrice;
  final String? description;
  final String? coverPhoto;
  final String? ebookUrl;
  final int numberOfCopy;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentEntity({
    required this.documentId,
    required this.categoryId,
    this.publisherId,
    required this.title,
    this.language,
    this.publicationYear,
    this.coverPrice,
    this.description,
    this.coverPhoto,
    this.ebookUrl,
    this.numberOfCopy = 0,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}