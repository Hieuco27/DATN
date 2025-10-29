import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/core/failure.dart';
import '../../domain/entities/reader_entity.dart';
import '../../domain/entities/profile_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

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

      // Lấy token từ AuthBloc
      final authState = _authBloc.state;
      if (authState is AuthAuthenticated &&
          authState.account.accessToken != null) {
        // Sử dụng ProfileUseCase với token
        final result = await _getProfileUseCase(authState.account.accessToken!);
        if (result.isSuccess && result.value != null) {
          print('✅ ProfileBloc: Profile loaded successfully');
          emit(ProfileLoaded(result.value!));
        } else {
          final err = result.error;
          final message = err is Failure ? err.message : err.toString();
          emit(ProfileError(message));
        }
      } else {
        emit(ProfileError('Chưa đăng nhập'));
      }
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

      DateTime? _parseDate(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
        return null;
      }

      // Kiểm tra nếu có đầy đủ dữ liệu từ event
      if (event.profileData['readerId'] == null ||
          event.profileData['accountId'] == null) {
        throw Exception('Thiếu thông tin readerId hoặc accountId');
      }

      // Tạo ReaderEntity từ dữ liệu event (không cần lấy từ state)
      final readerEntity = ReaderEntity(
        readerId: event.profileData['readerId'],
        accountId: event.profileData['accountId'],
        fullName: event.profileData['fullName'],
        phoneNumber: event.profileData['phoneNumber'],
        address: event.profileData['address'],
        gender: event.profileData['gender'],
        dateOfBirth: _parseDate(event.profileData['dateOfBirth']),
        cccd: event.profileData['cccd'],
        totolBorrow: event.profileData['totolBorrow'],
        note: event.profileData['note'],
        createdAt: _parseDate(event.profileData['created_at']),
        updatedAt: _parseDate(event.profileData['updated_at']),
      );

      final result = await _updateProfileUseCase(
        event.accessToken,
        readerEntity,
      );
      if (result.isSuccess && result.value != null) {
        emit(ProfileUpdated(result.value!));
      } else {
        final err = result.error;
        final message = err is Failure ? err.message : err.toString();
        emit(ProfileError(message, previousState: state));
      }
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
