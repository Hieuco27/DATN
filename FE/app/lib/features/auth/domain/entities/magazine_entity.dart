class MagazineEntity {
  final int documentId;
  final String? issn;
  final int? volume;
  final int? issue;
  final String? period;
  final DateTime? coverDate;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MagazineEntity({
    required this.documentId,
    this.issn,
    this.volume,
    this.issue,
    this.period,
    this.coverDate,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}