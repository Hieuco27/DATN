class NewspaperEntity {
  final int documentId;
  final String? issn;
  final DateTime? issueDate;
  final int? issueNumber;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NewspaperEntity({
    required this.documentId,
    this.issn,
    this.issueDate,
    this.issueNumber,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}