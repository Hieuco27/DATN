import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/core/failure.dart';
import '../../domain/entities/reader_entity.dart';
import '../../domain/entities/profile_usecase.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String accessToken;
  const ProfileLoadRequested(this.accessToken);
  @override
  List<Object?> get props => [accessToken];
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
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  ProfileBloc({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileClearError>(_onProfileClearError);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      print('🔄 ProfileBloc: Loading profile...');

      final result = await _getProfileUseCase(event.accessToken);
      if (result.isSuccess && result.value != null) {
        print('✅ ProfileBloc: Profile loaded successfully');
        print('🔍 Profile data: ${result.value}');
        print('🔍 Full name: ${result.value!.fullName}');
        emit(ProfileLoaded(result.value!));
      } else {
        final err = result.error;
        final message = err is Failure ? err.message : err.toString();
        print('❌ ProfileBloc: Profile load failed - $message');
        emit(ProfileError(message));
      }
    } catch (e) {
      print('❌ ProfileBloc: Unexpected error loading profile - $e');
      emit(
        ProfileError(
          'Lỗi không xác định khi tải thông tin profile: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(ProfileLoading());
      print('🔄 ProfileBloc: Updating profile with data: ${event.profileData}');

      DateTime? _parseDate(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
        return null;
      }

      final readerEntity = ReaderEntity(
        readerId: event.profileData['readerId'],
        accountId: event.profileData['accountId'],
        fullName: event.profileData['fullName'],
        phoneNumber: event.profileData['phoneNumber'],
        address: event.profileData['address'],
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
        print('✅ ProfileBloc: Profile updated successfully');
        emit(ProfileUpdated(result.value!));
      } else {
        final err = result.error;
        final message = err is Failure ? err.message : err.toString();
        print('❌ ProfileBloc: Profile update failed - $message');
        emit(ProfileError(message, previousState: state));
      }
    } catch (e) {
      print('❌ ProfileBloc: Unexpected error updating profile - $e');
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
