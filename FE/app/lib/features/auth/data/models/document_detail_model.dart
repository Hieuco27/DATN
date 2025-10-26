// lib/features/auth/data/models/document_detail_model.dart
import 'package:book_tech/features/auth/domain/entities/document_entity.dart';

class DocumentDetailModel {
  final int documentId;
  final String documentType;
  final String title;
  final String language;
  final int publicationYear;
  final int coverPrice;
  final String description;
  final String coverPhoto;
  final String? ebookUrl;
  final int numberOfCopy;
  final int totalCopies;
  final int availableCopies;

  // Simplified fields to avoid circular dependency
  final Map<String, dynamic> category;
  final Map<String, dynamic> publisher;
  final Map<String, dynamic>? book;
  final Map<String, dynamic>? magazine;
  final Map<String, dynamic>? newspaper;
  final List<Map<String, dynamic>> authors;
  final List<Map<String, dynamic>> genres;
  final List<Map<String, dynamic>> copies;

  DocumentDetailModel({
    required this.documentId,
    required this.documentType,
    required this.title,
    required this.language,
    required this.publicationYear,
    required this.coverPrice,
    required this.description,
    required this.coverPhoto,
    this.ebookUrl,
    required this.numberOfCopy,
    required this.category,
    required this.publisher,
    this.book,
    this.magazine,
    this.newspaper,
    required this.authors,
    required this.genres,
    required this.copies,
    required this.totalCopies,
    required this.availableCopies,
  });

  factory DocumentDetailModel.fromJson(Map<String, dynamic> json) {
    return DocumentDetailModel(
      documentId: json['documentId'],
      documentType: json['documentType'],
      title: json['title'],
      language: json['language'],
      publicationYear: json['publicationYear'],
      coverPrice: json['coverPrice'],
      description: json['description'],
      coverPhoto: json['coverPhoto'],
      ebookUrl: json['ebookUrl'],
      numberOfCopy: json['numberOfCopy'],
      category: json['category'] as Map<String, dynamic>,
      publisher: json['publisher'] as Map<String, dynamic>,
      book: json['book'] as Map<String, dynamic>?,
      magazine: json['magazine'] as Map<String, dynamic>?,
      newspaper: json['newspaper'] as Map<String, dynamic>?,
      authors: (json['authors'] as List).cast<Map<String, dynamic>>(),
      genres: (json['genres'] as List).cast<Map<String, dynamic>>(),
      copies: (json['copies'] as List).cast<Map<String, dynamic>>(),
      totalCopies: json['totalCopies'],
      availableCopies: json['availableCopies'],
    );
  }

  DocumentEntity toEntity() {
    return DocumentEntity(
      documentId: documentId,
      categoryId: category['categoryId'] ?? 0,
      publisherId: publisher['publisherId'],
      title: title,
      language: language,
      publicationYear: publicationYear,
      coverPrice: coverPrice,
      description: description,
      coverPhoto: coverPhoto,
      ebookUrl: ebookUrl,
      numberOfCopy: numberOfCopy,
    );
  }
}
