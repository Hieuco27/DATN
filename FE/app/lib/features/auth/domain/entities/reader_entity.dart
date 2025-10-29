class ReaderEntity {
  final int readerId;
  final int accountId;
  final String? fullName;
  final String? phoneNumber;
  final String? address;
  final DateTime? dateOfBirth;
  final String? cccd;
  final int? totolBorrow;
  final String? gender;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReaderEntity({
    required this.readerId,
    required this.accountId,
    this.fullName,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.cccd,
    this.gender,
    this.totolBorrow,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderEntity &&
        other.readerId == readerId &&
        other.accountId == accountId &&
        other.fullName == fullName &&
        other.phoneNumber == phoneNumber &&
        other.address == address &&
        other.dateOfBirth == dateOfBirth &&
        other.cccd == cccd &&
        other.createdAt == createdAt &&
        other.gender == gender &&
        other.updatedAt == updatedAt &&
        other.totolBorrow == totolBorrow &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(
      readerId,
      accountId,
      fullName,
      phoneNumber,
      address,
      gender,
      dateOfBirth,
      cccd,
      totolBorrow,
      note,
      createdAt,
      updatedAt,
    );
  }

  // Copy with method cho updates
  ReaderEntity copyWith({
    int? readerId,
    int? accountId,
    String? fullName,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? cccd,
    int? totolBorrow,
    String? gender,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReaderEntity(
      readerId: readerId ?? this.readerId,
      accountId: accountId ?? this.accountId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cccd: cccd ?? this.cccd,
      gender: gender ?? this.gender,

      totolBorrow: totolBorrow ?? this.totolBorrow,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // To JSON cho API calls
  Map<String, dynamic> toJson() {
    return {
      'readerId': readerId,
      'accountId': accountId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'cccd': cccd,
      'totolBorrow': totolBorrow,
      'gender': gender,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ReaderEntity(readerId: $readerId, accountId: $accountId, fullName: $fullName, phoneNumber: $phoneNumber, address: $address, dateOfBirth: $dateOfBirth, cccd: $cccd, gender: $gender, totolBorrow: $totolBorrow, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
