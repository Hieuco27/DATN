class DocumentGenreMapEntity {
  final int documentId;
  final int genreId;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentGenreMapEntity({
    required this.documentId,
    required this.genreId,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}