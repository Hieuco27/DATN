import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/core/widgets/gradient_background.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_in.dart';
import 'package:book_tech/features/auth/presentations/pages/otp_verification_page.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/presentations/widgets/auth_field.dart';
import 'package:book_tech/features/auth/presentations/widgets/auth_gradient_button.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/core/ui/notification_service.dart';
import 'package:book_tech/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/authentication_remote_data_source.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            _handleAuthState(context, state);
          },
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildNameField(),
                  const SizedBox(height: 15),
                  _buildEmailField(),
                  const SizedBox(height: 15),
                  _buildPasswordField(),
                  const SizedBox(height: 15),
                  _buildPhoneField(),
                  const SizedBox(height: 20),
                  _buildSignUpButton(),
                  const SizedBox(height: 15),
                  _buildSignInNavigation(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AuthField(
          hintText: 'Họ và tên',
          controller: _nameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập họ tên';
            }
            if (value.length < 2) {
              return 'Họ tên phải có ít nhất 2 ký tự';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildEmailField() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AuthField(
          hintText: 'Email',
          controller: _emailController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildPhoneField() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AuthField(
          hintText: 'Số điện thoại',
          controller: _phoneController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập số điện thoại';
            }
            if (!RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$').hasMatch(value)) {
              return 'Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AuthField(
          hintText: 'Mật khẩu',
          obsecureText: true,
          controller: _passwordController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildSignUpButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AuthGradientButton(
          buttonText: 'Đăng ký',
          onPressed: state is AuthLoading ? null : _register,
          isLoading: _isLoading,
        );
      },
    );
  }

  Widget _buildSignInNavigation(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInPage()),
        );
      },
      child: RichText(
        text: TextSpan(
          text: 'Bạn đã có tài khoản? ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color.fromARGB(221, 45, 45, 45),
          ),
          children: [
            TextSpan(
              text: 'Đăng nhập',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPalette.gradient2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final repository = AuthenticationRepositoryImpl(
          remoteDataSource: AuthenticationRemoteDataSourceImpl(),
          localStorageDataSource: LocalStorageDataSourceImpl(),
        );

        // Bước 1: Gửi OTP
        await repository.registerInit(_emailController.text.trim());

        // Lưu thông tin đăng ký để dùng cho bước verify
        final registerData = {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'phoneNumber': _phoneController.text.trim(),
          'fullName': _nameController.text.trim(),
          'dateOfBirth': '2000-01-01', // Có thể thêm date picker sau
          'gender': 'nam', // Có thể thêm gender picker sau
          'cccd': '', // Có thể thêm CCCD field sau
          'address': '', // Có thể thêm address field sau
        };

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Chuyển đến trang OTP verification
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationPage(
                email: _emailController.text.trim(),
                registerData: registerData,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          NotificationService.showError(
            context,
            message: e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    // Flow mới không cần xử lý state ở đây vì đã chuyển sang OTP page
    // Giữ lại để tránh lỗi nếu có listener khác
  }
}
