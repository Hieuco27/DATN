import 'package:equatable/equatable.dart';
import '../../domain/entities/account_entity.dart';

class AccountModel extends Equatable {
  final int? accountId;
  final String? fullName;
  final String email;
  final String phoneNumber;
  final String? password;
  final int? roleId;
  final String accessToken;
  final String refreshToken;

  const AccountModel({
    this.accountId,
    this.fullName,
    required this.email,
    required this.phoneNumber,
    this.password,
    this.roleId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {

    // Handle roleId conversion
    int? parsedRoleId;
    var rawRoleId = json['roleId'];
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
      accountId: json['accountId'] ?? json['id'],
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      password: json['password'],
      roleId: parsedRoleId ?? 3, // Default to reader if null
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (accountId != null) 'accountId': accountId,
      'email': email,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      if (password != null) 'password': password,
      'roleId': roleId ?? 3,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  // Convert to Entity
  Account toEntity() {
    return Account(
      accountId: accountId,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      roleId: roleId ?? 3, 
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  List<Object?> get props => [
    accountId,
    email,
    fullName,
    phoneNumber,
    password,
    roleId,
    accessToken,
    refreshToken,
  ];
}
