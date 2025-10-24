import '../entities/document_copy_status_entity.dart';

class DocumentCopyEntity {
  final int documentCopyId;
  final int documentId;
  final String barCode;
  final String? shelfLocation;
  final DocumentCopyStatus status;
  final String? conditionNote;
  final DateTime? entryDate; // date
  final String? conditionGrade;
  final int numberBorrow;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DocumentCopyEntity({
    required this.documentCopyId,
    required this.documentId,
    required this.barCode,
    this.shelfLocation,
    this.status = DocumentCopyStatus.AVAILABLE,
    this.conditionNote,
    this.entryDate,
    this.conditionGrade,
    this.numberBorrow = 0,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
  });
}
