import '../../domain/entities/reader_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  ProfileRepositoryImpl(this._remote);

  @override
  Future<ReaderEntity> getProfile(String accessToken) {
    return _remote.getProfile(accessToken);
  }

  @override
  Future<ReaderEntity> updateProfile(String accessToken, ReaderEntity reader) {
    return _remote.updateProfile(accessToken, reader);
  }
}
