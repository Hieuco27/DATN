import 'package:flutter/material.dart';
import '../../domain/entities/reader_entity.dart';

class ProfileDetailPage extends StatelessWidget {
  final ReaderEntity profile;
  const ProfileDetailPage({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName ?? '---',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (profile.email != null && profile.email!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: Colors.blue.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile.email!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
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
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 3,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Builder(
                    builder: (context) {
                      final memberCard = profile.memberCard!;
                      final cardType = memberCard.cardType;
                      final bool isUpgradeableCard =
                          cardType != null && cardType.maxBorrowLimit > 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.card_membership,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thẻ thành viên thư viện',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cardType?.typeName ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: memberCard.status == 'ACTIVE'
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      memberCard.status == 'ACTIVE'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 14,
                                      color: memberCard.status == 'ACTIVE'
                                          ? Colors.green.shade700
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      memberCard.status == 'ACTIVE'
                                          ? 'Đang hoạt động'
                                          : 'Không hoạt động',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: memberCard.status == 'ACTIVE'
                                            ? Colors.green.shade700
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _memberInfo(
                            Icons.credit_card,
                            'Số thẻ',
                            memberCard.cardNumber,
                          ),
                          const SizedBox(height: 8),
                          _memberInfo(
                            Icons.account_balance_wallet,
                            'Số dư',
                            '${memberCard.balance} VNĐ',
                          ),
                          if (isUpgradeableCard &&
                              memberCard.expiryDate != null) ...[
                            const SizedBox(height: 8),
                            _memberInfo(
                              Icons.calendar_today,
                              'Hết hạn',
                              '${memberCard.expiryDate!.day}/${memberCard.expiryDate!.month}/${memberCard.expiryDate!.year}',
                            ),
                          ],
                          if (cardType != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quyền lợi thẻ:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (cardType.canBorrowHome)
                                    _benefitItem('Mượn sách về nhà'),
                                  if (cardType.canReadOnsite)
                                    _benefitItem('Đọc sách tại chỗ'),
                                  if (cardType.canReadEbook)
                                    _benefitItem('Đọc sách điện tử (Ebook)'),
                                  if (cardType.canSearchCatalog)
                                    _benefitItem('Tra cứu, tìm kiếm danh mục'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Giới hạn: ${cardType.maxBorrowLimit} quyển / ${cardType.borrowDuration} ngày',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

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
                      profile.dateOfBirth,
                      Colors.orange.shade400,
                    ),
                    _divider(),
                    _infoTile(
                      Icons.transgender,
                      'Giới tính',
                      profile.gender,
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
                      profile.totolBorrow,
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
            if (profile.createdAt != null || profile.updatedAt != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        'Thông tin hệ thống',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (profile.createdAt != null)
                      _systemInfo('Ngày tạo', profile.createdAt),
                    if (profile.createdAt != null && profile.updatedAt != null)
                      _divider(),
                    if (profile.updatedAt != null)
                      _systemInfo('Ngày cập nhật', profile.updatedAt),
                  ],
                ),
              ),
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
                  style: const TextStyle(
                    fontSize: 16,
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
          Text(
            '${value ?? ""}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
            style: const TextStyle(
              fontSize: 14,
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
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
