class Account {
  final int? accountId;
  final int? readerId; // Added for review ownership check
  final String email;
  final String phoneNumber;
  final int? roleId;
  final String? fullName;
  final String? status;
  final String? accessToken;
  final String? refreshToken;

  const Account({
    this.accountId,
    this.readerId,
    required this.email,
    required this.phoneNumber,
    this.fullName,
    this.roleId,
    this.status,
    this.accessToken,
    this.refreshToken,
  });

  Account copyWith({
    int? accountId,
    int? readerId,
    String? email,
    String? phoneNumber,
    int? roleId,
    String? fullName,
    String? status,
    String? accessToken,
    String? refreshToken,
  }) {
    return Account(
      accountId: accountId ?? this.accountId,
      readerId: readerId ?? this.readerId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Account &&
        other.accountId == accountId &&
        other.readerId == readerId &&
        other.email == email &&
        other.fullName == fullName &&
        other.phoneNumber == phoneNumber &&
        other.status == status &&
        other.roleId == roleId &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return accountId.hashCode ^
        readerId.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        roleId.hashCode ^
        fullName.hashCode ^
        status.hashCode ^
        accessToken.hashCode ^
        refreshToken.hashCode;
  }
}
