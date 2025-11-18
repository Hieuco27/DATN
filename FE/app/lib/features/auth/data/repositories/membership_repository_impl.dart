import '../../domain/repositories/membership_repository.dart';
import '../../domain/entities/member_card_entity.dart';
import '../datasources/membership_remote_data_source.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  final MembershipRemoteDataSource remoteDataSource;

  MembershipRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CardTypeEntity>> getCardTypes(String accessToken) async {
    try {
      final cardTypes = await remoteDataSource.getCardTypes(accessToken);
      // CardTypeModel extends CardTypeEntity, nên có thể return trực tiếp
      return cardTypes;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MemberCardEntity> createMemberCard(
    String accessToken,
    int cardTypeId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final memberCard = await remoteDataSource.createMemberCard(
        accessToken,
        cardTypeId,
        paymentData,
      );
      return memberCard;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> processPayment(
    String accessToken,
    int cardTypeId,
    String paymentMethod,
  ) async {
    try {
      return await remoteDataSource.processPayment(
        accessToken,
        cardTypeId,
        paymentMethod,
      );
    } catch (e) {
      rethrow;
    }
  }
}
