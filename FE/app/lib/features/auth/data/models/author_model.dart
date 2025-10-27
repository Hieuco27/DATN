import '../../domain/entities/author_entity.dart';

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

class AuthorModel extends AuthorEntity {
  const AuthorModel({
    required super.authorId,
    required super.fullName,
    super.note,
    super.role,
    super.deleted = false,
    super.createdAt,
    super.updatedAt,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) => AuthorModel(
    authorId: _toInt(json['authorId']) ?? 0,
    fullName: json['fullName'] ?? '',
    note: json['note'],
    role: json['role'],
    deleted: _toBool(json['deleted'] ?? 0),
    createdAt: _parseDateTime(json['created_at']),
    updatedAt: _parseDateTime(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'authorId': authorId,
    'fullName': fullName,
    'note': note,
    'role': role,
    'deleted': deleted ? 1 : 0,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
