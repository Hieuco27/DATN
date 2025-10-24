import '../../domain/entities/document_copy_entity.dart';
import '../../domain/entities/document_copy_status_entity.dart';

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

class DocumentCopyModel extends DocumentCopyEntity {
  const DocumentCopyModel({
    required super.documentCopyId,
    required super.documentId,
    required super.barCode,
    super.shelfLocation,
    super.status = DocumentCopyStatus.AVAILABLE,
    super.conditionNote,
    super.entryDate,
    super.conditionGrade,
    super.numberBorrow = 0,
    super.deleted = false,
    super.createdAt,
    super.updatedAt,
  });

  factory DocumentCopyModel.fromJson(Map<String, dynamic> json) =>
      DocumentCopyModel(
        documentCopyId: _toInt(json['documentCopyId']) ?? 0,
        documentId: _toInt(json['documentId']) ?? 0,
        barCode: json['barCode'] ?? '',
        shelfLocation: json['shelfLocation'],
        status: documentCopyStatusFrom(json['status']),
        conditionNote: json['conditionNote'],
        entryDate: _parseDateTime(json['entryDate']),
        conditionGrade: json['conditionGrade'],
        numberBorrow: _toInt(json['numberBorrow']) ?? 0,
        deleted: _toBool(json['deleted'] ?? 0),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'documentCopyId': documentCopyId,
        'documentId': documentId,
        'barCode': barCode,
        'shelfLocation': shelfLocation,
        'status': documentCopyStatusTo(status),
        'conditionNote': conditionNote,
        'entryDate': entryDate?.toIso8601String(),
        'conditionGrade': conditionGrade,
        'numberBorrow': numberBorrow,
        'deleted': deleted ? 1 : 0,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}