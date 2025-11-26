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

import 'package:flutter_svg/flutter_svg.dart';

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
      body: AppGradientBackground(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) => _handleAuthState(context, state),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isSmallScreen = screenWidth < 360;
                  final isMediumScreen = screenWidth < 380;
                  
                  // Responsive values
                  final horizontalPadding = isSmallScreen ? 20.0 : 15.0;
                  final titleFontSize = isSmallScreen ? 48.0 : (isMediumScreen ? 54.0 : 60.0);
                  final spacing1 = isSmallScreen ? 20.0 : 30.0;
                  final spacing2 = isSmallScreen ? 12.0 : 15.0;
                  
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: spacing1),
                                _buildEmailField(),
                                SizedBox(height: spacing2),
                                _buildPasswordField(),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      // TODO: Implement forgot password logic
                                      NotificationService.showInfo(
                                        context, 
                                        message: 'Tính năng đang phát triển'
                                      );
                                    },
                                    child: Text(
                                      'Quên mật khẩu?',
                                      style: TextStyle(
                                        color: AppPalette.gradient2,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: spacing2),
                                _buildSignInButton(),
                                SizedBox(height: 25),
                                _buildSocialLogin(),
                                SizedBox(height: 25),
                                _buildSignUpNavigation(context),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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

  Widget _buildSocialLogin() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Hoặc đăng nhập bằng',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              icon: _googleIcon,
              onTap: () => _handleSocialLogin('Google'),
            ),
            const SizedBox(width: 25),
            _socialButton(
              icon: _facebookIcon,
              onTap: () => _handleSocialLogin('Facebook'),
            ),
            const SizedBox(width: 25),
            _socialButton(
              icon: _appleIcon,
              onTap: () => _handleSocialLogin('Apple'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SvgPicture.string(
          icon,
          width: 26,
          height: 26,
        ),
      ),
    );
  }

  void _handleSocialLogin(String provider) {
    NotificationService.showInfo(
      context,
      message: 'Đăng nhập bằng $provider đang phát triển',
    );
  }

  static const String _googleIcon = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/><path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/><path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/><path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/></svg>''';
  
  static const String _facebookIcon = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#1976D2" d="M24,4C12.954,4,4,12.954,4,24s8.954,20,20,20s20-8.954,20-20S35.046,4,24,4z"/><path fill="#FAFAFA" d="M26.707,29.301h5.176l0.813-5.258h-5.989v-2.874c0-1.67,0.558-2.503,2.206-2.503h2.825V13.87c-0.871-0.135-2.308-0.26-4.125-0.26c-4.324,0-7.151,2.659-7.151,7.406v3.033h-4.809v5.258h4.809c0,6.748,3.99,12.812,9.967,15.853C28.86,43.956,26.707,36.959,26.707,29.301z"/></svg>''';
  
  static const String _appleIcon = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 384 512"><path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/></svg>''';

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
