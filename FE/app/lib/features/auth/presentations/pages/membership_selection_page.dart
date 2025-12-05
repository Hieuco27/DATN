import 'dart:async';
import 'dart:io';
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
import 'package:image_picker/image_picker.dart';

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
  File? _selectedImage;
  String? _uploadedAvatarUrl;
  final ImagePicker _imagePicker = ImagePicker();

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
                        _buildAvatarUploadSection(),
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
                      isFree ? 'Mượn sách cơ bản' : 'Mượn sách online',
                      isFree,
                    ),
                    const SizedBox(height: 6),
                    _buildFeature(
                      isFree ? Icons.access_time : Icons.schedule,
                      isFree ? 'Thời gian: 7 ngày' : 'Thời gian mượn: 30 ngày',
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
                          isFree ? 'MIỄN PHÍ' : '100k/năm',
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

  Widget _buildAvatarUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _selectedImage != null 
            ? AppPalette.gradient2 
            : Colors.grey.shade200,
          width: _selectedImage != null ? 3 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedImage != null
                ? AppPalette.gradient2.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: _selectedImage != null ? 20 : 8,
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppPalette.gradient1, AppPalette.gradient2],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.gradient2.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác minh khuôn mặt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _selectedImage != null 
                            ? AppPalette.gradient1 
                            : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _selectedImage != null 
                          ? 'Ảnh đã chọn' 
                          : 'Chọn ảnh chân dung của bạn',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedImage != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPalette.gradient2,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Image preview or picker button
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ảnh của bạn',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sẵn sàng để xác minh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showImageSourceOptions,
                      icon: const Icon(Icons.edit, color: AppPalette.gradient2),
                      tooltip: 'Đổi ảnh',
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Chụp ảnh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppPalette.gradient2,
                        side: BorderSide(color: AppPalette.gradient2),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library, size: 20),
                      label: const Text('Thư viện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.gradient2,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt, size: 28, color: Colors.black),
                title: const Text(
                  'Chụp ảnh',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, size: 28, color: Colors.black),
                title: const Text(
                  'Tải ảnh lên',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _uploadedAvatarUrl = null; // Reset uploaded URL when selecting new image
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          message: 'Không thể chọn ảnh: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _uploadedAvatarUrl = null; // Reset uploaded URL when selecting new image
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(
          context,
          message: 'Không thể chụp ảnh: ${e.toString()}',
        );
      }
    }
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

    Widget buildInfoRow(String label, String value, {bool isHighlight = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  color: isHighlight ? AppPalette.gradient2 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // Header Info Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPalette.gradient1.withValues(alpha: 0.1),
                            AppPalette.gradient2.withValues(alpha: 0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color: AppPalette.gradient2,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Xác nhận thông tin đăng ký',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppPalette.gradient2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          buildInfoRow('Tài khoản:', widget.email),
                          buildInfoRow('Mã độc giả:', '#${widget.readerId}'),
                          const Divider(height: 24),
                          buildInfoRow('Loại thẻ:', 'Thẻ thư viện'),
                          buildInfoRow(
                            'Số tiền thanh toán:',
                            '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ',
                            isHighlight: true,
                          ),
                          if (orderCode != null)
                            buildInfoRow('Mã đơn hàng: ', '$orderCode'),  
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // QR Code Section
              if (qrCode.isNotEmpty) ...[
                const Text(
                  'Quét mã để thanh toán',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
                // const SizedBox(height: 8),
                // const Text(
                //   'Sử dụng App ngân hàng bất kỳ để quét mã',
                //   style: TextStyle(fontSize: 13, color: Colors.grey),
                // ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrCode,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE0B2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nội dung chuyển khoản:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SelectableText(
                                    '$orderCode',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: orderCode.toString()));
                                NotificationService.showSuccess(
                                  context,
                                  message: 'Đã sao chép nội dung chuyển khoản',
                                );
                              },
                              icon: const Icon(Icons.copy, color: Colors.deepOrange),
                              tooltip: 'Sao chép',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: qrCode));
                        NotificationService.showSuccess(
                          context,
                          message: 'Đã sao chép mã QR',
                        );
                      },
                      icon: const Icon(Icons.qr_code, size: 20),
                      label: const Text('Copy Mã QR'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ),
                  if (checkoutUrl.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
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
                        icon: const Icon(Icons.account_balance_wallet, size: 20),
                        label: const Text('Mở App NH'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.gradient2,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 30),

              // Footer Actions
              TextButton(
                onPressed: _checkPaymentStatus,
                child: const Text.rich(
                  TextSpan(
                    text: 'Đã thanh toán? ',
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Kiểm tra trạng thái',
                        style: TextStyle(
                          color: AppPalette.gradient2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                child: Text(
                  'Thực hiện sau',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
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

    // Check if avatar is selected
    if (_selectedImage == null) {
      NotificationService.showError(
        context,
        message: 'Vui lòng chọn ảnh chân dung để xác minh',
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

      // Step 1: Upload avatar first
      if (_uploadedAvatarUrl == null) {
        final uploadResult = await repository.uploadAvatar(_selectedImage!.path);
        
        if (uploadResult['ok'] == true && uploadResult['avatarUrl'] != null) {
          _uploadedAvatarUrl = uploadResult['avatarUrl'] as String;
        } else {
          throw Exception('Không thể tải lên ảnh xác minh');
        }
      }

      // Step 2: Complete registration with avatarUrl
      final completeData = {
        'readerId': widget.readerId,
        'cardTypeId': _selectedCardTypeId,
        'action': _selectedCardTypeId == 1 ? 'SKIP' : 'PAY',
        'avatarUrl': _uploadedAvatarUrl,
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

  Future<void> _handlePaymentSuccess([Map<String, dynamic>? data]) async {
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
