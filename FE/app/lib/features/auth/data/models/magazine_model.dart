import '../../domain/entities/magazine_entity.dart';

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

class MagazineModel extends MagazineEntity {
  const MagazineModel({
    required super.documentId,
    super.issn,
    super.volume,
    super.issue,
    super.period,
    super.coverDate,
    super.deleted = false,
    super.createdAt,
    super.updatedAt,
  });

  factory MagazineModel.fromJson(Map<String, dynamic> json) => MagazineModel(
        documentId: _toInt(json['documentId']) ?? 0,
        issn: json['issn'],
        volume: _toInt(json['volume']),
        issue: _toInt(json['issue']),
        period: json['period'],
        coverDate: _parseDateTime(json['coverDate']),
        deleted: _toBool(json['deleted'] ?? 0),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'issn': issn,
        'volume': volume,
        'issue': issue,
        'period': period,
        'coverDate': coverDate?.toIso8601String(),
        'deleted': deleted ? 1 : 0,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}