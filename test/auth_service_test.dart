import 'dart:async';

import 'partner_service_test.dart';


class MockAuthService {
  // Simulates the authenticated user (null if signed out)
  AppUser? _currentUser;

  // StreamController to emit authentication state changes (like Firebase AuthStateChanges)
  final StreamController<AppUser?> _userStreamController = StreamController.broadcast();

  Stream<AppUser?> get authStateChanges => _userStreamController.stream;

  // Helper to mock role assignment based on email domain/prefix
  UserRole _determineRoleFromEmail(String email) {
    if (email.contains('customer')) {
      return UserRole.customer;
    } else if (email.contains('rider')) {
      return UserRole.rider;
    } else if (email.contains('partner')) {
      return UserRole.partner;
    } 
    // Default to Customer for new sign-ups, as this is the primary user group (W1 Mitigation)
    return UserRole.customer; 
  }

  // Sign in simulation
  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {

    // Mock API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple password check (should fail if not 'password123')
    if (password != 'password123') {
      throw Exception('Invalid credentials or password.');
    }

    // Determine the role based on existing user email (simulates custom claims lookup)
    UserRole userRole = _determineRoleFromEmail(email);

    _currentUser = AppUser(uid: 'mock-uid-${userRole.name}', email: email, role: userRole);
    _userStreamController.add(_currentUser);
    return _currentUser;
  }
  
  // Sign up simulation (for Email/Password registration)
  Future<AppUser?> signUpWithEmailAndPassword(
      String email, String password) async {

    // Mock API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Determine the role for the new user (default to customer if domain is generic)
    UserRole userRole = _determineRoleFromEmail(email);

    // In a real app, Rider/Partner sign-up would create a PENDING status in Firestore
    if (userRole == UserRole.rider || userRole == UserRole.partner) {
       // Log that this user needs manual vetting and their initial status is PENDING
       print('New ${userRole.name} signed up. Status set to PENDING_REVIEW.');
    }

    _currentUser = AppUser(uid: 'new-uid-${userRole.name}', email: email, role: userRole);
    _userStreamController.add(_currentUser);
    return _currentUser;
  }
  
  // Google Sign-in simulation (Focus on Customer Role - W1 Mitigation)
  Future<AppUser?> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));

    // Google sign-ins are almost always Customers, due to the friction of getting 
    // a Partner/Rider status, so we default this to the Customer role.
    UserRole userRole = UserRole.customer; 
    String email = 'google-user@suefery.com';

    _currentUser = AppUser(uid: 'google-uid-12345', email: email, role: userRole);
    _userStreamController.add(_currentUser);
    return _currentUser;
  }


  // Sign out simulation
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _userStreamController.add(null);
  }
}  