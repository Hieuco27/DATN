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
  int? _selectedCardTypeId; // 1 = FREE, 2 = PREMIUM
  bool _isLoading = false;
  bool _showPaymentQR = false;
  Map<String, dynamic>? _paymentData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Thanh toán thẻ thư viện',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _showPaymentQR
          ? _buildPaymentQRView()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chọn loại thẻ thành viên',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildCardTypeOption(
                              1,
                              'FREE',
                              'Miễn phí',
                              'Sử dụng dịch vụ cơ bản miễn phí',
                              '0',
                            ),
                            const SizedBox(height: 12),
                            _buildCardTypeOption(
                              2,
                              'PREMIUM',
                              'Premium',
                              'Hưởng nhiều ưu đãi và quyền lợi đặc biệt',
                              '150000',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || _selectedCardTypeId == null
                            ? null
                            : _completeRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.gradient2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Hoàn tất đăng ký',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
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
                      child: const Text(
                        'Bỏ qua, đăng ký sau',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardTypeOption(
    int cardTypeId,
    String type,
    String name,
    String description,
    String price,
  ) {
    final isSelected = _selectedCardTypeId == cardTypeId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCardTypeId = cardTypeId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppPalette.gradient2.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppPalette.gradient2 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: cardTypeId,
              groupValue: _selectedCardTypeId,
              onChanged: (value) {
                setState(() {
                  _selectedCardTypeId = value;
                });
              },
              activeColor: AppPalette.gradient2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppPalette.gradient2
                              : Colors.black87,
                        ),
                      ),
                      if (cardTypeId == 2) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.gradient2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '150k/năm',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              'Thanh toán thành viên Premium',
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

      // Debug: In ra response để kiểm tra

      // Kiểm tra response có hợp lệ không
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
              print('💳 Payment required, showing payment link');
              print('💳 PaymentId: ${response['paymentId']}');
              print('💳 OrderCode: ${response['orderCode']}');
              print('💳 Amount: ${response['amount']}');
              print('💳 PayOS checkoutUrl: ${payos['checkoutUrl']}');
              setState(() {
                _paymentData = response;
                _showPaymentQR = true;
                _isLoading = false;
              });
            } else {
              print('⚠️ payos exists but checkoutUrl and qrCode are null');
              throw Exception(
                'Không thể tạo link thanh toán. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
              );
            }
          } else {
            // Có paymentId nhưng không có payos hoặc payos không hợp lệ
            print('⚠️ paymentId exists but payos is null or invalid');
            print('   paymentId: ${response['paymentId']}');
            print('   payos: ${response['payos']}');
            throw Exception(
              'Không thể tạo link thanh toán. Vui lòng thử lại hoặc liên hệ hỗ trợ.',
            );
          }
        } else {
          // Response có ok: true nhưng không match với cả 2 trường hợp trên
          print('❌ Invalid response structure:');
          print('   - ok: ${response['ok']}');
          print('   - free: ${response['free']}');
          print('   - memberCard: ${response['memberCard']}');
          print('   - paymentId: ${response['paymentId']}');
          print('   - payos: ${response['payos']}');
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
        print('❌ Registration failed: $errorMessage');
        print('❌ Full response: $response');
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
}
