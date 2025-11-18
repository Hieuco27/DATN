import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/presentations/pages/home_page.dart';
import 'package:book_tech/core/widgets/gradient_background.dart';
import 'package:book_tech/features/auth/presentations/widgets/auth_field.dart';
import 'package:book_tech/features/auth/presentations/widgets/auth_gradient_button.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_up.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_bloc.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_event.dart';
import 'package:book_tech/features/auth/presentations/bloc/auth_state.dart';
import 'package:book_tech/core/ui/notification_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) => _handleAuthState(context, state),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildEmailField(),
                      SizedBox(height: 15),
                      _buildPasswordField(),
                      SizedBox(height: 15),
                      _buildSignInButton(),
                      SizedBox(height: 15),
                      _buildSignUpNavigation(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return AuthField(
      hintText: 'Email',
      controller: _emailController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email không được để trống';
        }
        if (!value.contains('@')) {
          return 'Email không hợp lệ';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AuthField(
      hintText: 'Mật khẩu',
      controller: _passwordController,
      obsecureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Mật khẩu không được để trống';
        }
        if (value.length < 6) {
          return 'Mật khẩu phải có ít nhất 6 ký tự';
        }
        return null;
      },
    );
  }

  Widget _buildSignInButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AuthGradientButton(
          buttonText: 'Đăng nhập',
          onPressed: state is AuthLoading
              ? null // Disable button when loading
              : () => _signIn(context),
          isLoading: state is AuthLoading,
        );
      },
    );
  }

  Widget _buildSignUpNavigation(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignUpPage()),
        );
      },
      child: RichText(
        text: TextSpan(
          text: 'Bạn chưa có tài khoản? ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color.fromARGB(221, 45, 45, 45),
          ),
          children: [
            TextSpan(
              text: 'Đăng ký',
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

  void _signIn(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('🔐 Attempting login for email: $email');

      context.read<AuthBloc>().add(
        AuthLoginRequested(email: email, password: password),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

void _handleAuthState(BuildContext context, AuthState state) {
  // ✅ REMOVE loading handling từ listener
  if (state is AuthAuthenticated) {
    // Điều hướng đến trang chủ
    // Use addPostFrameCallback to avoid Navigator lock during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        NotificationService.showSuccess(
          context,
          message: 'Đăng nhập thành công!',
        );
      }
    });
  } else if (state is AuthError) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        NotificationService.showError(context, message: state.message);
      }
    });
  }
}

// removed unused helpers
