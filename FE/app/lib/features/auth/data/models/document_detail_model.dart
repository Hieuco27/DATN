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
  final String? shelfLocation;
  final String coverPhoto;
  final String? ebookUrl;
  final int numberOfCopy;

  // đối tượng map
  final Map<String, dynamic> category;
  final Map<String, dynamic> publisher;
  final Map<String, dynamic>? book;
  final Map<String, dynamic>? magazine;
  final Map<String, dynamic>? newspaper;
  final List<Map<String, dynamic>> authors;
  final List<Map<String, dynamic>> genres;
  final List<Map<String, dynamic>> copies;

  final int totalCopies;
  final int availableCopies;
  final int availableCopiesEffective;

  // deposit (flatten)
  final int? minDeposit;
  final int? maxDeposit;

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
    required this.availableCopiesEffective,
    this.minDeposit,
    this.maxDeposit,
    this.shelfLocation,
  });

  factory DocumentDetailModel.fromJson(Map<String, dynamic> json) {
    final deposit = json['deposit'] as Map<String, dynamic>?;

    return DocumentDetailModel(
      documentId: json['documentId'] as int,
      documentType: json['documentType'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      publicationYear: json['publicationYear'] as int,
      coverPrice: (json['coverPrice'] ?? 0) as int,
      description: json['description'] as String,
      coverPhoto: json['coverPhoto'] as String,
      ebookUrl: json['ebookUrl'] as String?,
      shelfLocation: json['shelfLocation'] as String?,
      numberOfCopy: (json['numberOfCopy'] ?? json['totalCopies']) as int,
      category: (json['category'] ?? const {}) as Map<String, dynamic>,
      publisher: (json['publisher'] ?? const {}) as Map<String, dynamic>,
      book: json['book'] as Map<String, dynamic>?,
      magazine: json['magazine'] as Map<String, dynamic>?,
      newspaper: json['newspaper'] as Map<String, dynamic>?,
      authors: ((json['authors'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
      genres: ((json['genres'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
      copies: ((json['copies'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList(),
      totalCopies: json['totalCopies'] as int,
      availableCopies: json['availableCopies'] as int,
      availableCopiesEffective:
          (json['availableCopiesEffective'] ?? json['availableCopies']) as int,
      minDeposit: deposit?['minDeposit'] as int?,
      maxDeposit: deposit?['maxDeposit'] as int?,
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
