import 'dart:async';
import 'package:book_tech/core/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:book_tech/core/ui/notification_service.dart';
import 'package:book_tech/core/theme/app_palette.dart';
import 'package:book_tech/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/authentication_remote_data_source.dart';
import 'package:book_tech/features/auth/data/datasources/local_storage_data_source.dart';
import 'package:book_tech/features/auth/presentations/pages/sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class MembershipSelectionPage extends StatefulWidget {
  final int readerId;
  final int accountId;
  final String email;
  final bool isFromRegistration;
  final VoidCallback? onMembershipUpdated;

  const MembershipSelectionPage({
    Key? key,
    required this.readerId,
    required this.accountId,
    required this.email,
    this.isFromRegistration = true,
    this.onMembershipUpdated,
  }) : super(key: key);

  @override
  State<MembershipSelectionPage> createState() =>
      _MembershipSelectionPageState();
}

class _MembershipSelectionPageState extends State<MembershipSelectionPage> {
  int? _selectedCardTypeId = 2; // Mặc định chọn thẻ thư viện
  bool _isLoading = false;
  bool _showPaymentQR = false;
  bool _isPaymentSuccess = false;
  Map<String, dynamic>? _paymentData;
  dynamic _currentOrderCode;
  Timer? _paymentCheckTimer;
  bool _socketListenerSetup = false;

  @override
  void initState() {
    super.initState();
    try {
      SocketService().initSocket(userId: widget.readerId);
    } catch (e) {
      // Socket initialization error is not critical, continue without it
    }
  }

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    SocketService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Đăng ký thẻ thư viện',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPalette.gradient1, AppPalette.gradient2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isPaymentSuccess
          ? _buildPaymentSuccessView()
          : _showPaymentQR
              ? _buildPaymentQRView()
              : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.gradient2.withOpacity(0.05),
                      Colors.white,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardTypeOption(
                          2,
                          'PREMIUM',
                          'Thẻ thư viện',
                          '150000',
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppPalette.gradient1, AppPalette.gradient2],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.gradient2.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading || _selectedCardTypeId == null
                                ? null
                                : _completeRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Hoàn tất đăng ký',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              if (widget.isFromRegistration) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const SignInPage(),
                                  ),
                                );
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            label: Text(
                              'Bỏ qua, đăng ký sau',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildCardTypeOption(
    int cardTypeId,
    String type,
    String name,
    String price,
  ) {
    final isSelected = _selectedCardTypeId == cardTypeId;
    final isFree = cardTypeId == 1;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardTypeId = cardTypeId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    isFree
                        ? Colors.green.shade50
                        : AppPalette.gradient1.withOpacity(0.1),
                    isFree
                        ? Colors.green.shade100
                        : AppPalette.gradient2.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isFree ? Colors.green : AppPalette.gradient2)
                : Colors.grey.shade200,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? (isFree ? Colors.green : AppPalette.gradient2).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFree
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [AppPalette.gradient1, AppPalette.gradient2],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isFree ? Colors.green : AppPalette.gradient2)
                              .withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFree ? Icons.card_giftcard : Icons.workspace_premium,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (isFree ? Colors.green.shade700 : AppPalette.gradient1)
                                    : Colors.black87,
                              ),
                            ),
                            if (!isFree) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HOT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        
                      ],
                    ),
                  ),
                  // Checkbox
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (isFree ? Colors.green : AppPalette.gradient2)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      color: isSelected
                          ? (isFree ? Colors.green : AppPalette.gradient2)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      Icons.check,
                      color: isSelected ? Colors.white : Colors.transparent,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Features
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildFeature(
                      
                      isFree ? Icons.menu_book : Icons.auto_stories,
                      isFree ? 'Mượn sách cơ bản' : 'Mượn sách không giới hạn',
                      isFree,
                    ),
                    const SizedBox(height: 6),
                    _buildFeature(
                      isFree ? Icons.access_time : Icons.schedule,
                      isFree ? 'Thời gian: 7 ngày' : 'Thời gian: 35 ngày',
                      isFree,
                    ),
                    if (!isFree) ...[
                      const SizedBox(height: 6),
                      _buildFeature(
                        Icons.star,
                        'Ưu tiên sách mới',
                        false,
                      ),
                      const SizedBox(height: 6),
                      _buildFeature(
                        Icons.support_agent,
                        'Hỗ trợ 24/7',
                        false,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Giá:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          isFree ? 'MIỄN PHÍ' : '150k/năm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isFree ? Colors.green.shade700 : AppPalette.gradient2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeature(IconData icon, String text, bool isFree) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: isFree ? Colors.green.shade600 : AppPalette.gradient2,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Thanh toán thành công!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn đã có thẻ thư viện',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentQRView() {
    final checkoutUrl = _paymentData?['payos']?['checkoutUrl'] as String? ?? '';
    final qrCode = _paymentData?['payos']?['qrCode'] as String? ?? '';
    final amount = _paymentData?['amount'] as int? ?? 150000;
    final orderCode = _paymentData?['orderCode'] as int?;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Thanh toán thẻ thư viện',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Số tiền: ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppPalette.gradient2,
              ),
            ),
            if (orderCode != null) ...[
              const SizedBox(height: 4),
              Text(
                'Mã đơn hàng: $orderCode',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            // Hiển thị QR Code
            if (qrCode.isNotEmpty) ...[
              const Text(
                'Quét mã QR để thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrCode,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              // Nút copy mã QR
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrCode));
                  NotificationService.showSuccess(
                    context,
                    message: 'Đã sao chép mã QR vào clipboard',
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Sao chép mã QR'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Nút mở link thanh toán
            if (checkoutUrl.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(checkoutUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      NotificationService.showError(
                        context,
                        message: 'Không thể mở link thanh toán',
                      );
                    }
                  },
                  icon: const Icon(Icons.payment, size: 24),
                  label: const Text(
                    'Mở link thanh toán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.gradient2,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hoặc mở app ngân hàng và quét mã QR ở trên',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: _checkPaymentStatus,
              child: const Text(
                'Đã thanh toán nhưng chưa thấy phản hồi?',
                style: TextStyle(
                  color: AppPalette.gradient2,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (widget.isFromRegistration) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Hoàn tất sau',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeRegistration() async {
    if (_selectedCardTypeId == null) {
      NotificationService.showError(
        context,
        message: 'Vui lòng chọn loại thẻ thành viên',
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

      final completeData = {
        'readerId': widget.readerId,
        'cardTypeId': _selectedCardTypeId,
        'action': _selectedCardTypeId == 1 ? 'SKIP' : 'PAY',
      };

      final response = await repository.registerComplete(completeData);

      if (response['ok'] == true) {
        // Trường hợp 1: SKIP/FREE card - có free: true và memberCard
        if (response['free'] == true) {
          if (response['memberCard'] != null &&
              response['memberCard'] is Map<String, dynamic>) {
            // Đăng ký thành công với thẻ miễn phí
            if (mounted) {
              NotificationService.showSuccess(
                context,
                message: 'Đăng ký thành viên miễn phí thành công!',
              );
              if (widget.isFromRegistration) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const SignInPage()),
                    );
                  }
                });
              } else {
                widget.onMembershipUpdated?.call();
                Navigator.of(context).pop(true);
              }
            }
          } else {
            // free: true nhưng không có memberCard hoặc memberCard không hợp lệ
            throw Exception(
              'Đăng ký thành công nhưng không tạo được thẻ thành viên. Vui lòng liên hệ hỗ trợ.',
            );
          }
        }
        // Trường hợp 2: PAY/PREMIUM card - có paymentId và payos
        else if (response['paymentId'] != null) {
          if (response['payos'] != null &&
              response['payos'] is Map<String, dynamic>) {
            final payos = response['payos'] as Map<String, dynamic>;
            if (payos['checkoutUrl'] != null || payos['qrCode'] != null) {
              // Cần thanh toán - hiển thị payment link
              setState(() {
                _paymentData = response;
                _showPaymentQR = true;
                _isLoading = false;
              });

              final orderCode = response['orderCode'];
              if (orderCode != null) {
                _currentOrderCode = orderCode;
                _setupSocketListener();
                _startPaymentPolling();
              }
            } else {
              throw Exception(
                'Không thể tạo link thanh toán. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
              );
            }
          } else {
            // Có paymentId nhưng không có payos hoặc payos không hợp lệ
            throw Exception(
              'Không thể tạo link thanh toán. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
            );
          }
        } else {
          // Response có ok: true nhưng không match với cả 2 trường hợp trên
          throw Exception(
            'Phản hồi từ server không hợp lệ. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
          );
        }
      } else {
        // Response không thành công (ok: false hoặc không có ok)
        final errorMessage =
            response['message'] ??
            response['error'] ??
            'Hoàn tất đăng ký thất bại';
        throw Exception(errorMessage);
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

  void _setupSocketListener() {
    if (_currentOrderCode == null || _socketListenerSetup) {
      return;
    }

    try {
      SocketService().off('payment_success');
      
      SocketService().on('payment_success', (data) async {
        try {
          final transactionCode = data?['transactionCode']?.toString();
          if (data != null && transactionCode != null &&
              transactionCode == _currentOrderCode.toString()) {
            if (mounted) {
              setState(() {
                _isPaymentSuccess = true;
              });

              NotificationService.showSuccess(
                context,
                message: 'Thanh toán thành công! Vui lòng đăng nhập để tiếp tục.',
              );

              await Future.delayed(const Duration(seconds: 2));

              if (mounted) {
                if (widget.isFromRegistration) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                    (route) => false,
                  );
                } else {
                  widget.onMembershipUpdated?.call();
                  Navigator.of(context).pop(true);
                }
              }
            }
          }
        } catch (e) {
          // Handle socket event processing error silently
        }
      });
      
      _socketListenerSetup = true;
    } catch (e) {
      // Handle socket listener setup error silently
    }
  }

  void _startPaymentPolling() {
    _paymentCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _isPaymentSuccess || _currentOrderCode == null) {
        timer.cancel();
        return;
      }

      try {
        final localStorageDataSource = LocalStorageDataSourceImpl();
        final accessToken = await localStorageDataSource.getAccessToken();
        
        if (accessToken == null || accessToken.isEmpty) {
          return;
        }
        
        final remoteDataSource = AuthenticationRemoteDataSourceImpl();
        final result = await remoteDataSource.checkPaymentStatus(accessToken);
        
        if (result['status'] == 'PAID' || result['paid'] == true) {
          timer.cancel();
          await _handlePaymentSuccess(result);
        }
      } catch (e) {
        // Continue polling on error
      }
    });
  }

  Future<void> _handlePaymentSuccess(Map<String, dynamic> data) async {
    if (!mounted || _isPaymentSuccess) return;

    try {
      setState(() {
        _isPaymentSuccess = true;
      });

      NotificationService.showSuccess(
        context,
        message: 'Thanh toán thành công! Vui lòng đăng nhập để tiếp tục.',
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        if (widget.isFromRegistration) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignInPage()),
            (route) => false,
          );
        } else {
          widget.onMembershipUpdated?.call();
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          message: 'Có lỗi xảy ra khi xử lý thanh toán.',
        );
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_currentOrderCode == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SocketService().disconnect();
      await Future.delayed(const Duration(seconds: 1));
      SocketService().initSocket(userId: widget.readerId);
      
      await Future.delayed(const Duration(seconds: 2));
      _setupSocketListener();

      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted && !_isPaymentSuccess) {
        NotificationService.showInfo(
          context,
          message: 'Đang kiểm tra kết nối... Vui lòng đợi thêm chút nữa.',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          message: 'Không thể kết nối. Vui lòng thử lại.',
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
}
