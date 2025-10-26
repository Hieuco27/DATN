class PublisherEntity {
  final int publisherId;
  final String name;
  final String note;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PublisherEntity({
    required this.publisherId,
    required this.name,
    required this.note,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });

  PublisherEntity copyWith({
    int? publisherId,
    String? name,
    String? note,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PublisherEntity(
      publisherId: publisherId ?? this.publisherId,
      name: name ?? this.name,
      note: note ?? this.note,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PublisherEntity &&
        other.publisherId == publisherId &&
        other.name == name &&
        other.note == note &&
        other.deleted == deleted &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return publisherId.hashCode ^
        name.hashCode ^
        note.hashCode ^
        deleted.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'PublisherEntity(publisherId: $publisherId, name: $name, note: $note, deleted: $deleted, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
