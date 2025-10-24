class DocumentAuthorMapEntity {
  final int documentId;
  final int authorId;
  final String? role; // default 'main'
  final int? ord;     // default 1
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentAuthorMapEntity({
    required this.documentId,
    required this.authorId,
    this.role,
    this.ord,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}