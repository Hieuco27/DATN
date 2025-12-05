import '../../domain/entities/member_card_entity.dart';

abstract class MembershipRepository {
  // Lấy danh sách các loại thẻ thành viên
  Future<List<CardTypeEntity>> getCardTypes(String accessToken);

  // Tạo thẻ thành viên mới (sau khi thanh toán)
  Future<MemberCardEntity> createMemberCard(
    String accessToken,
    int cardTypeId,
    Map<String, dynamic> paymentData,
  );

  // Xử lý thanh toán
  Future<Map<String, dynamic>> processPayment(
    String accessToken,
    int cardTypeId,
    String paymentMethod,
  );
  
  // Nạp tiền vào thẻ thành viên
  Future<Map<String, dynamic>> createMemberCardTopup(
    String accessToken,
    int memberCardId,
    int readerId,
  );
  
  // Lấy thông tin thẻ thành viên
  Future<Map<String, dynamic>> getMemberCard(
    String accessToken,
    int memberCardId,
  );
}
