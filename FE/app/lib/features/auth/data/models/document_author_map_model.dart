import '../../domain/entities/document_author_map_entity.dart';

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase();
  return s == '1' || s == 'true' || s == 't' || s == 'yes';
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

class DocumentAuthorMapModel extends DocumentAuthorMapEntity {
  const DocumentAuthorMapModel({
    required super.documentId,
    required super.authorId,
    super.role,
    super.ord,
    super.deleted = false,
    super.createdAt,
    super.updatedAt,
  });

  factory DocumentAuthorMapModel.fromJson(Map<String, dynamic> json) =>
      DocumentAuthorMapModel(
        documentId: _toInt(json['documentId']) ?? 0,
        authorId: _toInt(json['authorId']) ?? 0,
        role: json['role'],
        ord: _toInt(json['ord']),
        deleted: _toBool(json['deleted'] ?? 0),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'authorId': authorId,
    'role': role,
    'ord': ord,
    'deleted': deleted ? 1 : 0,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
