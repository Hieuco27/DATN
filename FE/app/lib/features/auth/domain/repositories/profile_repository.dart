import '../entities/reader_entity.dart';

abstract class ProfileRepository {
  Future<ReaderEntity> getProfile(String accessToken);
  Future<ReaderEntity> updateProfile(String accessToken, ReaderEntity reader);
}