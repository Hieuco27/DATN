import '../../domain/entities/reader_entity.dart';
import 'member_card_model.dart';

class ReaderModel extends ReaderEntity {
  const ReaderModel({
    required super.readerId,
    required super.accountId,
    super.fullName,
    super.phoneNumber,
    super.address,
    super.dateOfBirth,
    super.cccd,
    super.gender, 
    super.totalBorrow,
    super.note,
    super.avatarUrl,
    super.createdAt,
    super.updatedAt,
    super.email,
    super.memberCard,
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
    // json ở đây chính là data['reader'] từ API
    final reader = json; // json chính là reader data
    final account = json['account'] as Map<String, dynamic>? ?? {};
    final memberCard = json['memberCard'] as Map<String, dynamic>?;

    // print('🔍 Reader data: $reader');
    // print('🔍 Account data: $account');
    // print('🔍 MemberCard data: $memberCard');

    return ReaderModel(
      readerId: _parseInt(reader['readerId']),
      accountId: _parseInt(reader['accountId']),
      fullName: reader['fullName'] as String?,
      phoneNumber: account['phoneNumber'] as String?,
      address: reader['address'] as String?,
      dateOfBirth: reader['dateOfBirth'] != null
          ? DateTime.tryParse(reader['dateOfBirth'])
          : null,
      gender: reader['gender'] as String?,
      cccd: reader['cccd'] as String?,
      totalBorrow: _parseInt(reader['totalBorrow']),
      note: reader['note'] as String?,
      avatarUrl: reader['avatarUrl'] as String?,
      createdAt: reader['created_at'] != null
          ? DateTime.tryParse(reader['created_at'])
          : null,
      updatedAt: reader['updated_at'] != null
          ? DateTime.tryParse(reader['updated_at'])
          : null,
      email: account['email'] as String?,
      memberCard: memberCard != null
          ? MemberCardModel.fromJson(memberCard)
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
      'totalBorrow': totalBorrow,
      'avatarUrl': avatarUrl,
      'gender': gender,
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
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateOfBirth'])
          : null,
      cccd: json['cccd'] as String?,
      totalBorrow: json['totalBorrow'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
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
