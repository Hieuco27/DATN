class AuthorEntity {
  final int authorId;
  final String fullName;
  final String? note;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthorEntity({
    required this.authorId,
    required this.fullName,
    this.note,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}