import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/account_entity.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_event.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/core/result.dart';
import '../../domain/core/failure.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  DateTime? _lastLoginAttempt;

  AuthBloc({
    required AuthenticationRepository authRepository,
    LoginUseCase? loginUseCase,
    RegisterUseCase? registerUseCase,
  }) : _authRepository = authRepository,
       _loginUseCase = loginUseCase ?? LoginUseCase(authRepository),
       _registerUseCase = registerUseCase ?? RegisterUseCase(authRepository),
       super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthTokenRefreshRequested>(_onTokenRefreshRequested);
    on<AuthCheckLoginStatus>(_onCheckLoginStatus);
    on<AuthClearError>(_onClearError);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      final result = await _loginUseCase(
        LoginParams(email: event.email.trim(), password: event.password),
      );
      if (result.isSuccess && result.value != null) {
        final response = result.value!;
        if (response.success && response.data != null) {
          // ✅ KIỂM TRA ROLEID TRƯỚC KHI XỬ LÝ
          if (response.data!.roleId == 3) {
            print(
              '✅ [AuthBloc] RoleId check passed, user is a reader. Allowing login.',
            );
            emit(AuthAuthenticated(account: response.data!));
          } else {
            print(
              '❌ [AuthBloc] RoleId check failed (roleId=${response.data!.roleId}). User is not a reader. Blocking login.',
            );
            emit(AuthError(message: "Ứng dụng này chỉ dành cho độc giả"));
          }
        } else {
          print('❌ [AuthBloc] Response failed or data is null');
          emit(AuthError(message: response.message));
        }
      } else {
        final err = result.error;
        final message = err is Failure ? err.message : err.toString();
        emit(AuthError(message: message));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      final data = event.registerData;
      final params = RegisterParams(
        name: (data['fullName'] ?? data['name'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        password: (data['password'] ?? '').toString(),
        phone: (data['phoneNumber'] ?? data['phone'] ?? '').toString(),
        registerAsMember: data['registerAsMember'] as bool? ?? false,
      );

      final result = await _registerUseCase(params);

      if (result.isSuccess && result.value != null) {
        final response = result.value!;
        if (response.success && response.data != null) {
          emit(AuthAuthenticated(account: response.data!));
        } else {
          emit(AuthError(message: response.message));
        }
      } else {
        final err = result.error;
        final message = err is Failure ? err.message : err.toString();
        emit(AuthError(message: message));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.logout();
    } catch (e) {
      print('Logout error: $e');
    }
    // Luôn chuyển về unauthenticated ngay
    emit(const AuthUnauthenticated());
  }

  Future<void> _onTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Không emit loading để tránh flicker UI
      final response = await _authRepository.refreshToken();

      if (response != null && response.success && response.data != null) {
        // ✅ KIỂM TRA ROLEID KHI REFRESH TOKEN
        if (response.data!.roleId == 3) {
          emit(AuthAuthenticated(account: response.data!));
        } else {
          print(
            '❌ [AuthBloc] Token refresh for non-reader (roleId=${response.data!.roleId}). Clearing data.',
          );
          await _authRepository.logout();
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onCheckLoginStatus(
    AuthCheckLoginStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Không emit loading state ở đây
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final account = await _authRepository.getCurrentUser();
        if (account != null) {
          // ✅ KIỂM TRA ROLEID KHI CHECK LOGIN STATUS
          if (account.roleId == 3) {
            emit(AuthAuthenticated(account: account));
          } else {
            print(
              '❌ [AuthBloc] Saved user is not a reader (roleId=${account.roleId}). Clearing data.',
            );
            await _authRepository.logout(); // Clear data của non-reader
            emit(const AuthUnauthenticated());
          }
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  void _onClearError(AuthClearError event, Emitter<AuthState> emit) {
    if (state is AuthError) {
      //  Quay lại state trước đó khi clear error
      final previousState = (state as AuthError).previousState;
      if (previousState != null) {
        emit(previousState);
      } else {
        emit(const AuthUnauthenticated());
      }
    }
  }
}

String? _validateLoginForm(String email, String password) {
  if (email.isEmpty || password.isEmpty) {
    return 'Vui lòng nhập đầy đủ email và mật khẩu';
  }

  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
    return 'Email không hợp lệ';
  }

  if (password.length < 6) {
    return 'Mật khẩu phải có ít nhất 6 ký tự';
  }

  return null;
}
