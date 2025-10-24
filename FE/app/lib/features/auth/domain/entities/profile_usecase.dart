import '../entities/reader_entity.dart';
import '../core/result.dart';
import '../repositories/profile_repository.dart';


class GetProfileUseCase {
  final ProfileRepository repo;
  GetProfileUseCase(this.repo);

  Future<Result<ReaderEntity>> call(String accessToken) async {
    try {
      final data = await repo.getProfile(accessToken);
      return Result.ok(data);
    } catch (e) {
      return Result.fail(e);
    }
  }
}

class UpdateProfileUseCase {
  final ProfileRepository repo;
  UpdateProfileUseCase(this.repo);

  Future<Result<ReaderEntity>> call(
    String accessToken,
    ReaderEntity reader,
  ) async {
    try {
      final data = await repo.updateProfile(accessToken, reader);
      return Result.ok(data);
    } catch (e) {
      return Result.fail(e);
    }
  }
}
