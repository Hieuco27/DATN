import '../../domain/entities/member_card_entity.dart';

class MemberCardModel extends MemberCardEntity {
  const MemberCardModel({
    required super.memberCardId,
    required super.readerId,
    required super.cardNumber,
    required super.cardTypeId,
    required super.balance,
    super.issueDate,
    super.expiryDate,
    required super.status,
    super.note,
    required super.deleted,
    super.createdAt,
    super.updatedAt,
    super.cardType,
  });

  factory MemberCardModel.fromJson(Map<String, dynamic> json) {
    return MemberCardModel(
      memberCardId: _parseInt(json['memberCardId']),
      readerId: _parseInt(json['readerId']),
      cardNumber: json['cardNumber'] as String? ?? '',
      cardTypeId: _parseInt(json['cardTypeId']),
      balance: json['balance'] as String? ?? '0.00',
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'])
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'])
          : null,
      status: json['status'] as String? ?? 'INACTIVE',
      note: json['note'] as String?,
      deleted: json['deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      cardType: json['cardType'] != null
          ? CardTypeModel.fromJson(json['cardType'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class CardTypeModel extends CardTypeEntity {
  const CardTypeModel({
    required super.cardTypeId,
    required super.typeName,
    required super.price,
    required super.duration,
    required super.canBorrowHome,
    required super.maxBorrowLimit,
    required super.borrowDuration,
    required super.canReadOnsite,
    required super.canSearchCatalog,
    required super.canReadEbook,
    required super.description,
    required super.deleted,
    super.createdAt,
    super.updatedAt,
  });

  factory CardTypeModel.fromJson(Map<String, dynamic> json) {
    return CardTypeModel(
      cardTypeId: _parseInt(json['cardTypeId']),
      typeName: json['typeName'] as String? ?? '',
      price: json['price'] as String? ?? '0.00',
      duration: _parseInt(json['duration']),
      canBorrowHome: json['canBorrowHome'] as bool? ?? false,
      maxBorrowLimit: _parseInt(json['maxBorrowLimit']),
      borrowDuration: _parseInt(json['borrowDuration']),
      canReadOnsite: json['canReadOnsite'] as bool? ?? false,
      canSearchCatalog: json['canSearchCatalog'] as bool? ?? false,
      canReadEbook: json['canReadEbook'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      deleted: json['deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
