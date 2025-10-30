import 'package:flutter/material.dart';
import '../../domain/entities/reader_entity.dart';

class ProfileDetailPage extends StatelessWidget {
  final ReaderEntity profile;
  const ProfileDetailPage({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Thông tin chi tiết',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Card thông tin cơ bản
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade100,
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName ?? '---',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _contactInfo(
                              Icons.email_outlined,
                              profile.email ?? '---',
                            ),
                            const SizedBox(height: 4),
                            _contactInfo(
                              Icons.phone_outlined,
                              profile.phoneNumber ?? '---',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Thông tin chi tiết
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                color: Colors.white,
                child: Column(
                  children: [
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

            // Thông tin bổ sung (nếu có)
            if (profile.createdAt != null || profile.updatedAt != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Thông tin hệ thống',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (profile.createdAt != null)
                        _systemInfo('Ngày tạo', profile.createdAt),
                      if (profile.createdAt != null &&
                          profile.updatedAt != null)
                        _divider(),
                      if (profile.updatedAt != null)
                        _systemInfo('Ngày cập nhật', profile.updatedAt),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
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
}
