import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/data/repositories/i_repo_firestore.dart';
import 'package:suefery/data/services/auth_service.dart';
import 'package:suefery/data/services/logging_service.dart';
import 'package:suefery/locator.dart';

import '../../../data/enums/form_status.dart';

class ProfileState extends Equatable {
  final FromStatus status;
  final String name;
  final String email;
  final String phone;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    required this.status,
    required this.name,
    required this.email,
    required this.phone,
    this.errorMessage,
    this.successMessage,
  });

  factory ProfileState.initial() {
    return const ProfileState(
      status: FromStatus.initial,
      name: '',
      email: '',
      phone: '',
      errorMessage: null,
      successMessage: null,
    );
  }

  ProfileState copyWith({
    FromStatus? status,
    String? name,
    String? email,
    String? phone,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      errorMessage: errorMessage, // Don't carry over old errors
      successMessage: successMessage, // Don't carry over old messages
    );
  }

  @override
  List<Object?> get props => [status, name, email, phone, errorMessage, successMessage];
}

class ProfileCubit extends Cubit<ProfileState> {
  final AuthService _authService = sl<AuthService>();
  final IRepoFirestore _firestoreRepo = sl<IRepoFirestore>();
  final _log = LoggerRepo('ProfileCubit');

  ProfileCubit() : super(ProfileState.initial()) {
    loadUserProfile();
  }

  /// Loads the current user's profile from the AuthService.
  void loadUserProfile() {
    final user = _authService.currentAppUser;
    if (user != null) {
      _log.i('Loading profile for user: ${user.id}');
      emit(state.copyWith(
        status: FromStatus.loaded,
        name: user.name,
        email: user.email,
        phone: user.phone,
      ));
    } else {
      _log.w('No user found to load profile.');
      emit(state.copyWith(status: FromStatus.error, errorMessage: 'User not found.'));
    }
  }

  /// Updates the user's name.
  void nameChanged(String name) {
    emit(state.copyWith(name: name));
  }

  /// Updates the user's phone number.
  void phoneChanged(String phone) {
    emit(state.copyWith(phone: phone));
  }

  /// Saves the updated profile information to Firestore.
  Future<void> saveProfile() async {
    if (state.status == FromStatus.saving) return;

    emit(state.copyWith(status: FromStatus.saving));

    final userId = _authService.currentAppUser?.id;
    if (userId == null) {
      _log.e('Cannot save profile, user ID is null.');
      emit(state.copyWith(status: FromStatus.error, errorMessage: 'Could not save profile. User not found.'));
      return;
    }

    try {
      _log.i('Saving profile for user: $userId');
      final updatedData = {
        'name': state.name,
        'phone': state.phone,
      };

      // Use the firestore repository to update the user document
      await _firestoreRepo.update('users', userId, updatedData);

      // Also update the user object in the auth service so the whole app sees the change
      await _authService.reloadUser();

      emit(state.copyWith(status: FromStatus.loaded, successMessage: 'Profile saved successfully!'));
      
      // Reset success message after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed) {
          emit(state.copyWith(successMessage: ''));
        }
      });

    } catch (e) {
      _log.e('Error saving profile: $e');
      emit(state.copyWith(status: FromStatus.error, errorMessage: 'Failed to save profile.'));
    }
  }
}