import '../../domain/entities/document_entity.dart';

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

class DocumentModel extends DocumentEntity {
  const DocumentModel({
    required super.documentId,
    required super.categoryId,
    super.publisherId,
    required super.title,
    super.language,
    super.publicationYear,
    super.coverPrice,
    super.description,
    super.coverPhoto,
    super.ebookUrl,
    super.numberOfCopy = 0,
    super.deleted = false,
    super.createdAt,
    super.updatedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) => DocumentModel(
        documentId: _toInt(json['documentId']) ?? 0,
        categoryId: _toInt(json['categoryId']) ?? 0,
        publisherId: _toInt(json['publisherId']),
        title: json['title'] ?? '',
        language: json['language'],
        publicationYear: _toInt(json['publicationYear']),
        coverPrice: _toInt(json['coverPrice']),
        description: json['description'],
        coverPhoto: json['coverPhoto'],
        ebookUrl: json['ebookUrl'],
        numberOfCopy: _toInt(json['numberOfCopy']) ?? 0,
        deleted: _toBool(json['deleted'] ?? 0),
        createdAt: _parseDateTime(json['created_at']),
        updatedAt: _parseDateTime(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'categoryId': categoryId,
        'publisherId': publisherId,
        'title': title,
        'language': language,
        'publicationYear': publicationYear,
        'coverPrice': coverPrice,
        'description': description,
        'coverPhoto': coverPhoto,
        'ebookUrl': ebookUrl,
        'numberOfCopy': numberOfCopy,
        'deleted': deleted ? 1 : 0,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}