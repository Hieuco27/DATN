import 'package:equatable/equatable.dart';
import '../../domain/entities/account_entity.dart';

class AccountModel extends Equatable {
  final int? accountId;
  final int? readerId; // Added for review ownership check
  final String? fullName;
  final String email;
  final String phoneNumber;
  final String? password;
  final int? roleId;
  final String accessToken;
  final String refreshToken;

  const AccountModel({
    this.accountId,
    this.readerId,
    this.fullName,
    required this.email,
    required this.phoneNumber,
    this.password,
    this.roleId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    // Backend trả về { account: {...}, profile: {...}, accessToken, refreshToken }
    // Cần merge dữ liệu từ account object với tokens ở root level
    final accountData = json['account'] as Map<String, dynamic>?;
    final profileData = json['profile'] as Map<String, dynamic>?;
    
    // Handle roleId conversion
    int? parsedRoleId;
    var rawRoleId = accountData?['roleId'] ?? json['roleId'];
    if (rawRoleId != null) {
      if (rawRoleId is int) {
        parsedRoleId = rawRoleId;
      } else if (rawRoleId is String) {
        parsedRoleId = int.tryParse(rawRoleId) ?? 3;
      } else if (rawRoleId is List) {
        parsedRoleId = 3; // Default for reader if it's a list
      } else {
        parsedRoleId = 3; // Default for any other type
      }
    }

    return AccountModel(
      accountId: accountData?['accountId'] ?? json['accountId'] ?? json['id'],
      readerId: profileData?['readerId'] ?? json['readerId'],
      email: accountData?['email'] ?? json['email'] ?? '',
      fullName: accountData?['fullName'] ?? json['fullName'] ?? '',
      phoneNumber: accountData?['phoneNumber'] ?? json['phoneNumber'] ?? '',
      password: accountData?['password'] ?? json['password'],
      roleId: parsedRoleId ?? 3, // Default to reader if null
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (accountId != null) 'accountId': accountId,
      if (readerId != null) 'readerId': readerId,
      'email': email,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      if (password != null) 'password': password,
      'roleId': roleId,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  // Convert to Entity
  Account toEntity() {
    return Account(
      accountId: accountId,
      readerId: readerId,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      roleId: roleId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  List<Object?> get props => [
    accountId,
    readerId,
    email,
    fullName,
    phoneNumber,
    password,
    roleId,
    accessToken,
    refreshToken,
  ];
}
