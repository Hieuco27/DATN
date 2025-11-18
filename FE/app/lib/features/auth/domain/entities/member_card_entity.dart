class MemberCardEntity {
  final int memberCardId;
  final int readerId;
  final String cardNumber;
  final int cardTypeId;
  final String balance;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String status;
  final String? note;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CardTypeEntity? cardType;

  const MemberCardEntity({
    required this.memberCardId,
    required this.readerId,
    required this.cardNumber,
    required this.cardTypeId,
    required this.balance,
    this.issueDate,
    this.expiryDate,
    required this.status,
    this.note,
    required this.deleted,
    this.createdAt,
    this.updatedAt,
    this.cardType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberCardEntity &&
        other.memberCardId == memberCardId &&
        other.readerId == readerId &&
        other.cardNumber == cardNumber &&
        other.cardTypeId == cardTypeId &&
        other.balance == balance &&
        other.issueDate == issueDate &&
        other.expiryDate == expiryDate &&
        other.status == status &&
        other.note == note &&
        other.deleted == deleted &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.cardType == cardType;
  }

  @override
  int get hashCode {
    return Object.hash(
      memberCardId,
      readerId,
      cardNumber,
      cardTypeId,
      balance,
      issueDate,
      expiryDate,
      status,
      note,
      deleted,
      createdAt,
      updatedAt,
      cardType,
    );
  }
}

class CardTypeEntity {
  final int cardTypeId;
  final String typeName;
  final String price;
  final int duration;
  final bool canBorrowHome;
  final int maxBorrowLimit;
  final int borrowDuration;
  final bool canReadOnsite;
  final bool canSearchCatalog;
  final bool canReadEbook;
  final String description;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CardTypeEntity({
    required this.cardTypeId,
    required this.typeName,
    required this.price,
    required this.duration,
    required this.canBorrowHome,
    required this.maxBorrowLimit,
    required this.borrowDuration,
    required this.canReadOnsite,
    required this.canSearchCatalog,
    required this.canReadEbook,
    required this.description,
    required this.deleted,
    this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardTypeEntity &&
        other.cardTypeId == cardTypeId &&
        other.typeName == typeName &&
        other.price == price &&
        other.duration == duration &&
        other.canBorrowHome == canBorrowHome &&
        other.maxBorrowLimit == maxBorrowLimit &&
        other.borrowDuration == borrowDuration &&
        other.canReadOnsite == canReadOnsite &&
        other.canSearchCatalog == canSearchCatalog &&
        other.canReadEbook == canReadEbook &&
        other.description == description &&
        other.deleted == deleted &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      cardTypeId,
      typeName,
      price,
      duration,
      canBorrowHome,
      maxBorrowLimit,
      borrowDuration,
      canReadOnsite,
      canSearchCatalog,
      canReadEbook,
      description,
      deleted,
      createdAt,
      updatedAt,
    );
  }
}
