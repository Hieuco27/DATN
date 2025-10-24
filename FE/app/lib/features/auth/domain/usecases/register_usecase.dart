import '../core/result.dart';
import '../core/failure.dart';
import '../core/usecase.dart';
import '../entities/register_response.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String name;
  final String email;
  final String password;
  final String phone;
  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });
}

class RegisterUseCase
    implements UseCase<Result<RegisterResponse>, RegisterParams> {
  final AuthenticationRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Result<RegisterResponse>> call(RegisterParams params) async {
    print(
      '🔍 RegisterUseCase validation - Name: "${params.name}", Email: "${params.email}", Phone: "${params.phone}", Password length: ${params.password.length}',
    );

    if (params.name.trim().isEmpty) {
      print('❌ Validation failed: Tên không được trống');
      return Result.fail(ValidationFailure('Tên không được trống'));
    }
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailPattern.hasMatch(params.email.trim())) {
      print('❌ Validation failed: Email không hợp lệ');
      return Result.fail(ValidationFailure('Email không hợp lệ'));
    }
    if (params.password.length < 6) {
      print('❌ Validation failed: Mật khẩu phải có ít nhất 6 ký tự');
      return Result.fail(ValidationFailure('Mật khẩu phải có ít nhất 6 ký tự'));
    }
    if (params.phone.trim().isEmpty) {
      print('❌ Validation failed: Số điện thoại không được trống');
      return Result.fail(ValidationFailure('Số điện thoại không được trống'));
    }

    // Validation số điện thoại Việt Nam
    final phonePattern = RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$');
    if (!phonePattern.hasMatch(params.phone.trim())) {
      print('❌ Validation failed: Số điện thoại không hợp lệ');
      return Result.fail(
        ValidationFailure(
          'Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam',
        ),
      );
    }

    print('✅ All validations passed, calling repository...');

    try {
      final response = await repository.register({
        'username': params.email.trim(), // Sử dụng email làm username
        'email': params.email.trim(),
        'password': params.password,
        'phoneNumber': params.phone
            .trim(), // Sử dụng phoneNumber theo database schema
        'fullName': params.name.trim(), // Sử dụng fullName theo database schema
        'roleId': 1, // 1 = doc_gia (reader) theo database schema
      });
      return Result.ok(response);
    } catch (e) {
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}
