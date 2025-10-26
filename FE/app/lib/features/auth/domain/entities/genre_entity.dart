class GenreEntity {
  final int genreId;
  final String name;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GenreEntity({
    required this.genreId,
    required this.name,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}