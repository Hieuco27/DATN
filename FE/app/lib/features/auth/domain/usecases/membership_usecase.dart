import '../core/result.dart';
import '../core/failure.dart';
import '../core/usecase.dart';
import '../entities/member_card_entity.dart';
import '../repositories/membership_repository.dart';

// Get Card Types UseCase
class GetCardTypesParams {
  final String accessToken;
  const GetCardTypesParams({required this.accessToken});
}

class GetCardTypesUseCase
    implements UseCase<Result<List<CardTypeEntity>>, GetCardTypesParams> {
  final MembershipRepository repository;
  GetCardTypesUseCase(this.repository);

  @override
  Future<Result<List<CardTypeEntity>>> call(GetCardTypesParams params) async {
    try {
      final cardTypes = await repository.getCardTypes(params.accessToken);
      return Result.ok(cardTypes);
    } catch (e) {
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}

// Create Member Card UseCase
class CreateMemberCardParams {
  final String accessToken;
  final int cardTypeId;
  final Map<String, dynamic> paymentData;
  const CreateMemberCardParams({
    required this.accessToken,
    required this.cardTypeId,
    required this.paymentData,
  });
}

class CreateMemberCardUseCase
    implements UseCase<Result<MemberCardEntity>, CreateMemberCardParams> {
  final MembershipRepository repository;
  CreateMemberCardUseCase(this.repository);

  @override
  Future<Result<MemberCardEntity>> call(CreateMemberCardParams params) async {
    try {
      final memberCard = await repository.createMemberCard(
        params.accessToken,
        params.cardTypeId,
        params.paymentData,
      );
      return Result.ok(memberCard);
    } catch (e) {
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}

// Process Payment UseCase
class ProcessPaymentParams {
  final String accessToken;
  final int cardTypeId;
  final String paymentMethod;
  const ProcessPaymentParams({
    required this.accessToken,
    required this.cardTypeId,
    required this.paymentMethod,
  });
}

class ProcessPaymentUseCase
    implements UseCase<Result<Map<String, dynamic>>, ProcessPaymentParams> {
  final MembershipRepository repository;
  ProcessPaymentUseCase(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(ProcessPaymentParams params) async {
    try {
      final result = await repository.processPayment(
        params.accessToken,
        params.cardTypeId,
        params.paymentMethod,
      );
      return Result.ok(result);
    } catch (e) {
      final failure = e is Failure ? e : ServerFailure(e.toString());
      return Result.fail(failure);
    }
  }
}
