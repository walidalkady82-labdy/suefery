import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// Defines the three primary user roles in the SUEFERY application.
enum Role {
  customer, // S1: Conversational Ordering
  rider,    // S3: Hyper-Local Efficiency
  partner   // Partner App
}

// ===================================
// 1. ROLE EVENTS
// Events represent actions that occur in the application.
// ===================================

abstract class RoleEvent {}

/// Event fired when the user successfully authenticates.
class AuthStatusChanged extends RoleEvent {
  final bool isLoggedIn;
  final Role initialRole;

  AuthStatusChanged({required this.isLoggedIn, required this.initialRole});
}

/// Event fired when a user (in the multi-role app) switches view/role.
class RoleSwitched extends RoleEvent {
  final Role newRole;
  RoleSwitched(this.newRole);
}

// ===================================
// 2. ROLE STATES
// States represent the data the UI needs to render.
// ===================================

abstract class RoleState {}

/// Initial state, before authentication check.
class RoleInitialState extends RoleState {}

/// State indicating the app is ready, providing the current role and auth status.
class RoleReadyState extends RoleState {
  final bool isLoggedIn;
  final Role currentRole;

  RoleReadyState({required this.isLoggedIn, required this.currentRole});
}

// ===================================
// 3. ROLE BLOC
// The central brain that maps Events to States.
// ===================================

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  // Initialize with the starting state (not ready yet)
  RoleBloc() : super(RoleInitialState()) {
    // Register the handlers for the defined events
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<RoleSwitched>(_onRoleSwitched);
    
    // Immediately simulate the initial authentication check
    add(AuthStatusChanged(isLoggedIn: true, initialRole: Role.customer));
  }

  /// Handles the initial auth status check.
  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<RoleState> emit) {
    debugPrint('RoleBloc: AuthStatusChanged -> User Logged In: ${event.isLoggedIn}');
    emit(RoleReadyState(
      isLoggedIn: event.isLoggedIn,
      currentRole: event.initialRole,
    ));
  }

  /// Handles the user switching their role (e.g., from Customer UI to Rider UI).
  void _onRoleSwitched(RoleSwitched event, Emitter<RoleState> emit) {
    if (state is RoleReadyState) {
      final currentState = state as RoleReadyState;
      debugPrint('RoleBloc: RoleSwitched -> New Role: ${event.newRole}');
      // Emit a new state with the updated role, preserving the login status
      emit(RoleReadyState(
        isLoggedIn: currentState.isLoggedIn,
        currentRole: event.newRole,
      ));
    }
  }
}
