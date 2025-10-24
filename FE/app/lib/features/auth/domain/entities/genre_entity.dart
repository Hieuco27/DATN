class GenreEntity {
  final int genreId;
  final String name;
  final String? documentType;
  final String? description;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GenreEntity({
    required this.genreId,
    required this.name,
    this.documentType,
    this.description,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}