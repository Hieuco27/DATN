import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reader_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'package:book_tech/features/auth/data/repositories/membership_repository_impl.dart';
import 'package:book_tech/features/auth/data/datasources/membership_remote_data_source.dart';
import 'package:book_tech/core/ui/notification_service.dart';
import 'payment_qr_page.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({Key? key}) : super(key: key);

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  @override
  void initState() {
    super.initState();
    // Load profile mới khi mở trang
    context.read<ProfileBloc>().add(const ProfileLoadRequested());
  }

  String _formatGender(String? gender) {
    if (gender == null || gender.isEmpty) return 'Chưa cập nhật';
    String lowerGender = gender.toLowerCase();
    if (lowerGender == 'nam') return 'Nam';
    if (lowerGender == 'nữ' || lowerGender == 'nu') return 'Nữ';
    if (lowerGender == 'khác' || lowerGender == 'khac') return 'Khác';
    return gender;
  }

  String _formatDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return 'Chưa cập nhật';
    return '${dateOfBirth.day.toString().padLeft(2, '0')}/${dateOfBirth.month.toString().padLeft(2, '0')}/${dateOfBirth.year}';
  }

  Widget _buildAvatarImage(ReaderEntity profile) {
    // Chỉ dùng avatarUrl từ backend
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profile.avatarUrl!,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.person, size: 42, color: Colors.white),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      );
    }
    // Default icon
    return const Center(
      child: Icon(Icons.person, size: 42, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text(
                'Thông tin tài khoản',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.white,
              elevation: 1,
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text(
                'Thông tin tài khoản',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.white,
              elevation: 1,
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            body: Center(
              child: Text(state.message),
            ),
          );
        }

        final profile = state is ProfileLoaded
            ? state.profile
            : (state is ProfileUpdated ? state.profile : null);

        if (profile == null) {
          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text(
                'Thông tin tài khoản',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.white,
              elevation: 1,
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            body: const Center(
              child: Text('Không có dữ liệu'),
            ),
          );
        }

        return _buildDetailContent(profile);
      },
    );
  }

  Widget _buildDetailContent(ReaderEntity profile) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Thông tin tài khoản',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phần header / avatar
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                            ? null
                            : LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) ? Colors.grey[200] : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildAvatarImage(profile),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName ?? '---',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (profile.email != null && profile.email!.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 14,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      profile.email!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _contactInfo(
                          Icons.phone_outlined,
                          profile.phoneNumber ?? '---',
                          
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card thông tin thành viên (nếu có)
            if (profile.memberCard != null)
              _buildMemberCardWidget(profile),

            const SizedBox(height: 16),

            // Thông tin chi tiết
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Thông tin cá nhân',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _divider(),
                    _infoTile(
                      Icons.cake_outlined,
                      'Ngày sinh',
                      _formatDateOfBirth(profile.dateOfBirth),
                      Colors.orange.shade400,
                    ),
                    _divider(),
                    _infoTile(
                      Icons.transgender,
                      'Giới tính',
                      _formatGender(profile.gender),
                      Colors.pink.shade400,
                    ),
                    _divider(),
                    _infoTile(
                      Icons.credit_card_outlined,
                      'CCCD',
                      profile.cccd,
                      Colors.green.shade500,
                    ),
                    _divider(),
                    _infoTile(
                      Icons.home_outlined,
                      'Địa chỉ',
                      profile.address,
                      Colors.blue.shade500,
                    ),
                    _divider(),
                    _infoTile(
                      Icons.book_outlined,
                      'Tổng số lượt mượn',
                      profile.totalBorrow,
                      Colors.purple.shade500,
                    ),
                    _divider(),
                    _infoTile(
                      Icons.note_outlined,
                      'Ghi chú',
                      profile.note,
                      Colors.brown.shade400,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Thông tin bổ sung (nếu có)
            // if (profile.createdAt != null || profile.updatedAt != null)
            //   Card(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(20),
            //     ),
            //     elevation: 2,
            //     color: Colors.white,
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Padding(
            //           padding: EdgeInsets.symmetric(
            //             horizontal: 16,
            //             vertical: 10,
            //           ),
            //           child: Text(
            //             'Thông tin hệ thống',
            //             style: TextStyle(
            //               fontSize: 16,
            //               fontWeight: FontWeight.w700,
            //               color: Colors.black87,
            //             ),
            //           ),
            //         ),
            //         if (profile.createdAt != null)
            //           _systemInfo('Ngày tạo', profile.createdAt),
            //         if (profile.createdAt != null && profile.updatedAt != null)
            //           _divider(),
            //         if (profile.updatedAt != null)
            //           _systemInfo('Ngày cập nhật', profile.updatedAt),
            //       ],
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _contactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    dynamic value,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${value ?? "Chưa cập nhật"}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemInfo(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Flexible(
            child: Text(
              '${value ?? ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  Widget _memberInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _benefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 15, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCardWidget(ReaderEntity profile) {
    final memberCard = profile.memberCard!;
    final cardType = memberCard.cardType;
    final balance = double.tryParse(memberCard.balance) ?? 0;

    return Column(
      children: [
        // Card thẻ thành viên với gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với icon
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Thẻ thư viện',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Thông tin thẻ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Số thẻ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Số thẻ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          memberCard.cardNumber,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),

                    // Số dư hiện tại
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Số dư hiện tại',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${balance.toStringAsFixed(0)} đ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Hạn sử dụng
                if (memberCard.expiryDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hạn sử dụng',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${memberCard.expiryDate!.day}/${memberCard.expiryDate!.month}/${memberCard.expiryDate!.year}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Nút nạp tiền
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleTopUp(profile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Nạp tiền vào thẻ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Ghi chú
                Row(
                  children: [
                    Text(
                      '💡',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nạp tiền để đủ số dư mặc định của loại thẻ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Thông tin quyền lợi (nếu có)
        // if (cardType != null) ...[
        //   const SizedBox(height: 12),
        //   Container(
        //     padding: const EdgeInsets.all(16),
        //     decoration: BoxDecoration(
        //       color: Colors.white,
        //       borderRadius: BorderRadius.circular(16),
        //       border: Border.all(color: Colors.grey.shade200),
        //     ),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text(
        //           'Quyền lợi thẻ',
        //           style: TextStyle(
        //             fontSize: 15,
        //             fontWeight: FontWeight.w700,
        //             color: Colors.black87,
        //           ),
        //         ),
        //         const SizedBox(height: 12),
        //         if (cardType.canBorrowHome)
        //           _benefitItem('Mượn sách về nhà'),
        //         if (cardType.canReadEbook)
        //           _benefitItem('Đọc sách điện tử (Ebook)'),
        //         if (cardType.canSearchCatalog)
        //           _benefitItem('Tra cứu thư mục'),
        //         const SizedBox(height: 8),
        //         Container(
        //           padding: const EdgeInsets.all(10),
        //           decoration: BoxDecoration(
        //             color: Colors.blue.shade50,
        //             borderRadius: BorderRadius.circular(8),
        //           ),
        //           child: Text(
        //             'Giới hạn: ${cardType.maxBorrowLimit} quyển / ${cardType.borrowDuration} ngày',
        //             style: TextStyle(
        //               fontSize: 12,
        //               color: Colors.blue.shade900,
        //               fontWeight: FontWeight.w600,
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Future<void> _handleTopUp(ReaderEntity profile) async {
    final memberCard = profile.memberCard;
    if (memberCard == null) {
      NotificationService.showError(
        context,
        message: 'Không tìm thấy thông tin thẻ thành viên',
      );
      return;
    }

    final balance = double.tryParse(memberCard.balance) ?? 0;
    
    // Check if balance is already sufficient
    if (balance >= 10000) {
      NotificationService.showInfo(
        context,
        message: 'Thẻ đã đủ số dư mặc định (10,000 VND)',
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('Vui lòng đăng nhập');
      }

      final membershipRepo = MembershipRepositoryImpl(
        remoteDataSource: MembershipRemoteDataSourceImpl(),
      );

      final result = await membershipRepo.createMemberCardTopup(
        authState.account.accessToken!,
        memberCard.memberCardId,
        profile.readerId,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      print('🔍 Topup API Response: $result');

      // Check if success
      final isSuccess = result['success'] == true;
      if (!isSuccess) {
        throw Exception(result['message'] ?? 'Không thể tạo thanh toán');
      }

      final data = result['data'];
      if (data == null) {
        throw Exception('Dữ liệu trả về không hợp lệ');
      }
      
      // Check if has checkout URL (need payment)
      if (data.containsKey('checkoutUrl') && data['checkoutUrl'] != null) {
        // Navigate to QR payment page
        final paymentSuccess = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<ProfileBloc>(this.context),
              child: PaymentQrPage(
                paymentId: data['paymentId'] as int,
                orderCode: data['orderCode'] as int,
                amount: (data['amount'] as num).toInt(),
                checkoutUrl: data['checkoutUrl'] as String,
                qrCode: data['qrCode'] as String,
                readerId: profile.readerId,
              ),
            ),
          ),
        );

        // If payment was successful, reload profile
        if (paymentSuccess == true && mounted) {
          // Show loading while reloading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
          
          // Reload profile
          context.read<ProfileBloc>().add(ProfileLoadRequested());
          
          // Wait a bit for the data to update
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close loading dialog
          }
        }
      } else {
        // Already sufficient balance
        if (mounted) {
          NotificationService.showInfo(
            context,
            message: result['message'] ?? 'Thẻ đã đủ số dư',
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still showing
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        NotificationService.showError(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }
}
