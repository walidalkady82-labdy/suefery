import 'package:suefery/data/enum/user_alive_status.dart';
import 'package:suefery/data/enum/user_role.dart';
import 'package:suefery/data/model/model_user.dart';

import '../repository/i_repo_firestore.dart'; // Assuming you have this model

class ServiceUser {
  final IRepoFirestore _firestoreRepo;
  final String _collectionPath = 'users'; // Specific logic!

  ServiceUser(this._firestoreRepo);

  /// Gets a stream of a single user, converting it to an [ModelUser] model.
  Stream<ModelUser?> getUserStream(String userId) {
    return _firestoreRepo
        .getDocumentStream(_collectionPath, userId)
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      // Business Logic: Handles data conversion
      return ModelUser.fromMap(snapshot.data()!);
    });
  }

  /// Fetches a single user by their ID.
  Future<ModelUser?> getUser(String userId) async {
    final snapshot =
        await _firestoreRepo.getDocumentSnapShot(_collectionPath, userId);
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return ModelUser.fromMap(snapshot.data()!);
  }

  /// Creates a new user in the database from an [ModelUser] object.
  Future<void> createUser(ModelUser user) {
    // Business Logic: Ensures a new user is created with their ID
    // and handles data conversion.
    return _firestoreRepo.updateDocument(
      _collectionPath,
      user.id, // Use update/set to enforce the ID
      user.toMap(),
    );
  }

  /// Updates specific fields for a user.
  Future<void> updateUser(String userId, {
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    bool? isVerified,
    DateTime? creationTimestamp,
    UserRole? role,
    String? photoUrl,
    UserAliveStatus? userAliveStatus,
    double? lat,
    double? lng,
    String? geohash,
    String? fcmToken,
    String? bio,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    String? state,
    String? specificPersonaGoal,

    }) {
    final dataToUpdate = <String, dynamic>{};
    if (firstName != null) {
      dataToUpdate['firstName'] = firstName;
    }
    if (lastName != null) {
      dataToUpdate['lastName'] = lastName;
    }
    if (email != null) {
      dataToUpdate['email'] = email;
    }
    if (phone != null) {
      dataToUpdate['phone'] = phone;
    }
    if (isVerified != null) {
      dataToUpdate['isVerified'] = isVerified;
    }
    if (creationTimestamp != null) {
      dataToUpdate['creationTimestamp'] = creationTimestamp;
    }
    if (role != null) {
      dataToUpdate['role'] = role.name;
    }
    if (photoUrl != null) {
      dataToUpdate['photoUrl'] = photoUrl;
    }
    if (userAliveStatus != null) {
      dataToUpdate['userAliveStatus'] = userAliveStatus.name;
    }
    if (lat != null) {
      dataToUpdate['lat'] = lat;
    }
    if (lng != null) {
      dataToUpdate['lng'] = lng;
    }
    if (geohash != null) {
      dataToUpdate['geohash'] = geohash;
    }
    if (fcmToken != null) {
      dataToUpdate['fcmToken'] = fcmToken;
    }
    if (bio != null) {
      dataToUpdate['bio'] = bio;
    }
    
    return _firestoreRepo.updateDocument(_collectionPath, userId, dataToUpdate);
  }

  /// Deletes a user.
  Future<void> deleteUser(String userId) {
    return _firestoreRepo.remove(_collectionPath, userId);
  }
}