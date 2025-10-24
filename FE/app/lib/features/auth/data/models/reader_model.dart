import '../../domain/entities/reader_entity.dart';

class ReaderModel extends ReaderEntity {
  const ReaderModel({
    required super.readerId,
    required super.accountId,
    super.fullName,
    super.phoneNumber,
    super.address,
    super.dateOfBirth,
    super.cccd,
    super.totolBorrow,
    super.note,
    super.createdAt,
    super.updatedAt,
  });

  // factory ReaderModel.fromJson(Map<String, dynamic> json) {
  

  //   return ReaderModel(
  //     readerId: _parseInt(json['readerId']),
  //     accountId: _parseInt(json['accountId']),
  //     fullName: json['fullName'] as String?,
  //     phoneNumber: json['phoneNumber'] as String?,
  //     address: json['address'] as String?,
  //     dateOfBirth: json['dateOfBirth'] != null
  //         ? DateTime.tryParse(json['dateOfBirth'])
  //         : null,
  //     cccd: json['cccd'] as String?,
  //     totolBorrow: _parseInt(json['totolBorrow']),
  //     note: json['note'] as String?,
  //     createdAt: json['created_at'] != null
  //         ? DateTime.tryParse(json['created_at'])
  //         : null,
  //     updatedAt: json['updated_at'] != null
  //         ? DateTime.tryParse(json['updated_at'])
  //         : null,
  //   );
  // }
  factory ReaderModel.fromJson(Map<String, dynamic> json) {
    print('🔍 ReaderModel.fromJson input: $json');

    // Extract profile and account data
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    final account = json['account'] as Map<String, dynamic>? ?? {};

    print('🔍 Profile data: $profile');
    print('🔍 Account data: $account');

    return ReaderModel(
      readerId: _parseInt(profile['readerId']),
      accountId: _parseInt(profile['accountId']),
      fullName: profile['fullName'] as String?,
      phoneNumber:
          account['phoneNumber'] as String?, // phoneNumber is in account
      address: profile['address'] as String?,
      dateOfBirth: profile['dateOfBirth'] != null
          ? DateTime.tryParse(profile['dateOfBirth'])
          : null,
      cccd: profile['cccd'] as String?,
      totolBorrow: _parseInt(profile['totolBorrow']),
      note: profile['note'] as String?,
      createdAt: profile['created_at'] != null
          ? DateTime.tryParse(profile['created_at'])
          : null,
      updatedAt: profile['updated_at'] != null
          ? DateTime.tryParse(profile['updated_at'])
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Cache key cho local storage
  String get cacheKey => 'reader_${accountId}';

  // Serialize cho local storage
  Map<String, dynamic> toCacheJson() {
    return {
      'readerId': readerId,
      'accountId': accountId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'cccd': cccd,
      'totolBorrow': totolBorrow,
      'note': note,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory ReaderModel.fromCacheJson(Map<String, dynamic> json) {
    return ReaderModel(
      readerId: json['readerId'] as int,
      accountId: json['accountId'] as int,
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateOfBirth'])
          : null,
      cccd: json['cccd'] as String?,
      totolBorrow: json['totolBorrow'] as int? ?? 0,
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
    );
  }
}
