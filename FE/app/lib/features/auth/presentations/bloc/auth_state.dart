import 'package:equatable/equatable.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/reader_entity.dart';

class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Account account;
  const AuthAuthenticated({required this.account});

  @override
  List<Object?> get props => [account];
}

// chưa xác thực - chưa đăng nhập
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// Đăng nhập thành công
class AuthLoginSuccess extends AuthState {
  final Account account;
  const AuthLoginSuccess({required this.account});

  @override
  List<Object?> get props => [account];
}

// đăng ký thành công
class AuthRegisterSuccess extends AuthState {
  final Account account;
  const AuthRegisterSuccess({required this.account});
  @override
  List<Object?> get props => [account];
}

// Đăng xuất thành công
class AuthLogoutSuccess extends AuthState {
  const AuthLogoutSuccess();
}

// Xảy ra lỗi
class AuthError extends AuthState {
  final String message;
  final AuthState? previousState; //Lưu state trước khi xảy ra lỗi

  const AuthError({required this.message, this.previousState});

  @override
  List<Object?> get props => [message];
}
