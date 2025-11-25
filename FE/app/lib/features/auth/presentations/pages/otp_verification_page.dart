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
  int _countdown = 59;

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
      print('🔄 [RESEND OTP] Đang gửi lại OTP...');
      
      final repository = AuthenticationRepositoryImpl(
        remoteDataSource: AuthenticationRemoteDataSourceImpl(),
        localStorageDataSource: LocalStorageDataSourceImpl(),
      );

      // Hiển thị thông báo đang gửi
      NotificationService.showInfo(
        context,
        message: 'Đang gửi lại mã OTP...',
        duration: const Duration(milliseconds: 1500),
      );

      final response = await repository.registerInit(widget.email);
      
      print('✅ [RESEND OTP] Gửi lại thành công: $response');

      if (mounted) {
        setState(() {
          _countdown = 59;
          _isResending = false;
        });

        _startCountdown();

        NotificationService.showSuccess(
          context,
          message: 'Đã gửi lại mã OTP đến email của bạn!',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ [RESEND OTP] Lỗi: ${e.toString()}');
      
      if (mounted) {
        setState(() {
          _isResending = false;
        });
        NotificationService.showError(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          duration: const Duration(seconds: 4),
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
                  horizontal: 20,
                  vertical: 24,
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
                    // Icon với animation subtle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPalette.gradient2.withOpacity(0.1),
                            AppPalette.gradient1.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 48,
                        color: AppPalette.gradient2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    const Text(
                      'Xác thực Email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.gradient1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description with email - Fix overflow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const Text(
                            'Nhập mã OTP gửi đến',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.gradient2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                 const SizedBox(height: 24),
                    
                    // OTP Input Fields - Responsive width
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate spacing based on available width
                          final availableWidth = constraints.maxWidth;
                          final spacing = availableWidth > 400 ? 6.0 : 3.0;
                          final totalSpacing = spacing * 5; // 5 gaps between 6 boxes
                          final boxWidth = (availableWidth - totalSpacing - 12) / 6;
                          final clampedWidth = boxWidth.clamp(30.0, 40.0);
                        
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              6,
                              (index) => Padding(
                                padding: EdgeInsets.only(
                                  right: index < 5 ? spacing / 2 : 0,
                                  left: index > 0 ? spacing / 2 : 0,
                                ),
                                child: SizedBox(
                                  width: clampedWidth,
                                  height: clampedWidth + 6,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.gradient1,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFF),
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE0E6F3),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppPalette.gradient2,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Colors.redAccent,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) => _onOtpChanged(index, value),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.gradient2,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _isLoading ? 0 : 2,
                          shadowColor: AppPalette.gradient2.withOpacity(0.3),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Xác thực OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Resend section - Fix overflow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          const Text(
                            'Không nhận được mã?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _countdown > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Gửi lại sau ${_countdown}s',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black26,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: _isResending ? null : _resendOtp,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    backgroundColor:
                                        AppPalette.gradient2.withOpacity(0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: _isResending
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppPalette.gradient2,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.refresh_rounded,
                                          size: 16,
                                          color: AppPalette.gradient2,
                                        ),
                                  label: const Text(
                                    'Gửi lại OTP',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppPalette.gradient2,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Back to login
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignInPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: Colors.black45,
                      ),
                      label: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 13,
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
