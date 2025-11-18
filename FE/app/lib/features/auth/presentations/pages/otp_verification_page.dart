import 'package:flutter/material.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/core/ui/notification_service.dart';
import 'package:book_tech/core/widgets/gradient_background.dart';
import 'package:book_tech/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/authentication_remote_data_source.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/features/auth/presentations/pages/membership_selection_page.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_in.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final Map<String, dynamic> registerData;

  const OtpVerificationPage({
    Key? key,
    required this.email,
    required this.registerData,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
        });
        return _countdown > 0;
      }
      return false;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      NotificationService.showError(
        context,
        message: 'Vui lòng nhập đầy đủ 6 số OTP',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = AuthenticationRepositoryImpl(
        remoteDataSource: AuthenticationRemoteDataSourceImpl(),
        localStorageDataSource: LocalStorageDataSourceImpl(),
      );

      final verifyData = {...widget.registerData, 'otp': otp};

      final response = await repository.registerVerify(verifyData);

      if (response['ok'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final account = data['account'] as Map<String, dynamic>?;
        final reader = data['reader'] as Map<String, dynamic>?;

        if (account != null && reader != null) {
          // Lưu thông tin tạm thời để dùng cho bước complete
          // Chuyển đến trang chọn thẻ thành viên
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MembershipSelectionPage(
                  readerId: reader['readerId'] as int,
                  accountId: account['accountId'] as int,
                  email: widget.email,
                ),
              ),
            );
          }
        } else {
          throw Exception('Dữ liệu phản hồi không hợp lệ');
        }
      } else {
        throw Exception(response['message'] ?? 'Xác thực OTP thất bại');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0) {
      NotificationService.showInfo(
        context,
        message: 'Vui lòng đợi $_countdown giây trước khi gửi lại',
      );
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final repository = AuthenticationRepositoryImpl(
        remoteDataSource: AuthenticationRemoteDataSourceImpl(),
        localStorageDataSource: LocalStorageDataSourceImpl(),
      );

      await repository.registerInit(widget.email);

      setState(() {
        _countdown = 60;
        _isResending = false;
      });

      _startCountdown();

      if (mounted) {
        NotificationService.showSuccess(
          context,
          message: 'Đã gửi lại mã OTP đến email của bạn',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
        NotificationService.showError(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto verify when all 6 digits are filled
    if (index == 5 && value.isNotEmpty) {
      final allFilled = _otpControllers.every((c) => c.text.isNotEmpty);
      if (allFilled) {
        _verifyOtp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 32,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPalette.gradient2.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 40,
                        color: AppPalette.gradient2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Xác thực Email',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppPalette.gradient1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chúng tôi đã gửi mã OTP 6 số đến\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: 48,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            textInputAction: index < 5
                                ? TextInputAction.next
                                : TextInputAction.done,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFF),
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: const Color(0xFFE0E6F3),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppPalette.gradient2,
                                  width: 1.6,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onOtpChanged(index, value),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.gradient1,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Xác thực',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Không nhận được mã? ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: _isResending || _countdown > 0
                              ? null
                              : _resendOtp,
                          child: Text(
                            _countdown > 0
                                ? 'Gửi lại sau ($_countdown)'
                                : 'Gửi lại',
                            style: TextStyle(
                              color: _isResending || _countdown > 0
                                  ? Colors.black26
                                  : AppPalette.gradient2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignInPage()),
                        );
                      },
                      child: Text(
                        'Quay lại đăng nhập',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
