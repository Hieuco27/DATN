import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_in.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/presentations/widgets/auth_field.dart';
import 'package:book_tech/features/auth/presentations/widgets/auth_gradient_button.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_event.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/core/ui/notification_service.dart';

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
      body: BlocListener<AuthBloc, AuthState>(
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
                    color: Colors.white,
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
                const SizedBox(height: 15),
                _buildSignUpButton(),
                const SizedBox(height: 15),
                _buildSignInNavigation(context),
              ],
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
          hintText: 'Full Name',
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
          hintText: 'Phone Number',
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
          hintText: 'Password',
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
          buttonText: 'Sign Up',
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
          text: 'Already have an account? ',
          style: Theme.of(context).textTheme.titleMedium,
          children: [
            TextSpan(
              text: 'Sign In',
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

  void _register() {
    if (_formKey.currentState!.validate()) {
      final registerData = {
        'username': _emailController.text.trim(), // Sử dụng email làm username
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phoneNumber': _phoneController.text
            .trim(), // Sử dụng phoneNumber theo database schema
        'fullName': _nameController.text
            .trim(), // Sử dụng fullName theo database schema
        'roleId': 3, // 1 = doc_gia (reader) theo database schema
      };
      print('📝 Register data: ${registerData.toString()}');
      print('📝 Data validation:');
      print('  - Username: ${registerData['username']}');
      print('  - Email: ${registerData['email']}');
      print(
        '  - Password length: ${(registerData['password'] as String).length}',
      );
      print('  - Phone: ${registerData['phoneNumber']}');
      print('  - FullName: ${registerData['fullName']}');
      print('  - RoleId: ${registerData['roleId']}');

      // Dispatch register event tới AuthBloc
      context.read<AuthBloc>().add(
        AuthRegisterRequested(registerData: registerData),
      );
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      // Đăng ký và đăng nhập thành công
      // Use addPostFrameCallback to avoid Navigator lock during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            message: 'Đăng ký thành công!',
          );
          // Tự động đăng nhập sau khi đăng ký thành công

          // Điều hướng đến trang chủ
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home_page', (route) => false);
        }
      });
    } else if (state is AuthRegisterSuccess) {
      // Chỉ đăng ký thành công (nếu không auto-login)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          NotificationService.showSuccess(
            context,
            message: 'Đăng ký thành công! Vui lòng đăng nhập.',
          );

          // Quay lại trang đăng nhập
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInPage()),
          );
        }
      });
    } else if (state is AuthError) {
      // Hiển thị lỗi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          NotificationService.showError(context, message: state.message);
        }
      });
    }
  }
}
