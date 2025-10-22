import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/models/user_role.dart';

// --- Events ---
sealed class AuthEvent {
  const AuthEvent();
}

class ChangeRole extends AuthEvent {
  final UserRole newRole;
  const ChangeRole(this.newRole);
}

// --- State ---
class AuthState {
  final UserRole role;
  final String userId;

  const AuthState({
    required this.role,
    required this.userId,
  });

  AuthState copyWith({
    UserRole? role,
  }) {
    return AuthState(
      role: role ?? this.role,
      userId: userId,
    );
  }
}

// --- BLoC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required String userId}) 
    : super(AuthState(role: UserRole.customer, userId: userId)) {
    on<ChangeRole>(_onChangeRole);
  }

  void _onChangeRole(ChangeRole event, Emitter<AuthState> emit) {
    emit(state.copyWith(role: event.newRole));
  }
}
