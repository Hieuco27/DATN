import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/reader_entity.dart';
import '../../domain/entities/profile_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
  @override
  List<Object?> get props => [];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String accessToken;
  final Map<String, dynamic> profileData;
  const ProfileUpdateRequested(this.accessToken, this.profileData);
  @override
  List<Object?> get props => [accessToken, profileData];
}

class ProfileClearError extends ProfileEvent {}

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ReaderEntity profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdated extends ProfileState {
  final ReaderEntity profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;
  final ProfileState? previousState;

  const ProfileError(this.message, {this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthenticationRepository _authRepository;
  // Unused now (kept for constructor compatibility); consider removing wiring later
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final AuthBloc _authBloc;

  ProfileBloc({
    required AuthenticationRepository authRepository,
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required AuthBloc authBloc,
  }) : _authRepository = authRepository,
       _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _authBloc = authBloc,
       super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileClearError>(_onProfileClearError);
  }

  // Trong ProfileBloc, thay đổi:
  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      print('🔄 ProfileBloc: Loading profile...');

      // Gọi qua AuthenticationRepository để có auto refresh token
      final profile = await _authRepository.getProfile();
      print('✅ ProfileBloc: Profile loaded successfully');
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('Lỗi lấy profile: ${e.toString()}'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());

      // (no-op)

      // Kiểm tra nếu có đầy đủ dữ liệu từ event
      if (event.profileData['readerId'] == null ||
          event.profileData['accountId'] == null) {
        throw Exception('Thiếu thông tin readerId hoặc accountId');
      }

      // Chuẩn hoá dữ liệu đầu vào nếu cần (không cần tạo entity ở đây)

      // Dùng AuthenticationRepository để được tự refresh khi 401
      final updated = await _authRepository.updateProfile(event.profileData);
      emit(ProfileUpdated(updated));
    } catch (e) {
      emit(
        ProfileError(
          'Lỗi không xác định khi cập nhật profile: ${e.toString()}',
          previousState: state,
        ),
      );
    }
  }

  void _onProfileClearError(
    ProfileClearError event,
    Emitter<ProfileState> emit,
  ) {
    if (state is ProfileError) {
      final previousState = (state as ProfileError).previousState;
      if (previousState != null) {
        emit(previousState);
      } else {
        emit(ProfileInitial());
      }
    }
  }
}
