import '../core/result.dart';
import '../core/failure.dart';
import '../core/usecase.dart';
import '../entities/login_response.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<Result<LoginResponse>, LoginParams> {
  final AuthenticationRepository repository;
  LoginUseCase(this.repository);

  @override
  Future<Result<LoginResponse>> call(LoginParams params) async {
    // Basic validation at domain boundary
    if (params.email.trim().isEmpty || params.password.isEmpty) {
      return Result.fail(ValidationFailure('Email và mật khẩu không được trống'));
    }
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailPattern.hasMatch(params.email.trim())) {
      return Result.fail(ValidationFailure('Email không hợp lệ'));
    }

    try {
      final response = await repository.login(
        params.email.trim(),
        params.password,
      );
      return Result.ok(response);
    } catch (e) {
      // Map errors to Failure types if needed
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}


