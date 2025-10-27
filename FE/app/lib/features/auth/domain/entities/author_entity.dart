class AuthorEntity {
  final int authorId;
  final String fullName;
  final String? note;
  final String? role;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthorEntity({
    required this.authorId,
    required this.fullName,
    this.note,
    this.role,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}
