import 'package:suefery/data/models/app_user.dart';

import '../repositories/i_repo_firestore.dart'; // Assuming you have this model

class UserService {
  final IRepoFirestore _firestoreRepo;
  final String _collectionPath = 'users'; // Specific logic!

  UserService(this._firestoreRepo);

  /// Gets a stream of a single user, converting it to an [AppUser] model.
  Stream<AppUser?> getUserStream(String userId) {
    return _firestoreRepo
        .quaryDocumentStream(_collectionPath, userId)
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      // Business Logic: Handles data conversion
      return AppUser.fromMap(snapshot.data()!);
    });
  }

  /// Fetches a single user by their ID.
  Future<AppUser?> getUser(String userId) async {
    final snapshot =
        await _firestoreRepo.getDocumentSnapShot(_collectionPath, userId);
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return AppUser.fromMap(snapshot.data()!);
  }

  /// Creates a new user in the database from an [AppUser] object.
  Future<void> createUser(AppUser user) {
    // Business Logic: Ensures a new user is created with their ID
    // and handles data conversion.
    return _firestoreRepo.update(
      _collectionPath,
      user.id, // Use update/set to enforce the ID
      user.toMap(),
    );
  }

  /// Updates specific fields for a user.
  Future<void> updateUser(String userId, {String? name, String? email}) {
    final dataToUpdate = <String, dynamic>{};
    if (name != null) {
      dataToUpdate['name'] = name;
    }
    if (email != null) {
      dataToUpdate['email'] = email;
    }
    return _firestoreRepo.update(_collectionPath, userId, dataToUpdate);
  }

  /// Deletes a user.
  Future<void> deleteUser(String userId) {
    return _firestoreRepo.remove(_collectionPath, userId);
  }
}