import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:suefery/data/enum/user_alive_status.dart';
import 'package:suefery/data/enum/user_role.dart';
import 'package:suefery/data/model/model_user.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/core/utils/logger.dart';

import '../../core/extensions/future_extension.dart';
import '../repository/i_repo_firestore.dart';

class ServiceUser with LogMixin{
  final IRepoFirestore _firestoreRepo;
  final ServiceAuth _authService;
  final String _collectionPath = 'users'; 

  ServiceUser(this._authService,this._firestoreRepo);
  
  /// Gets a stream of a single user, converting it to an [ModelUser] model.
  Stream<ModelUser?> getUserStream() {
    final user = _authService.currentAppUser;
    if (user == null) return Stream.value(null);
    return _firestoreRepo
        .getDocumentStream(_collectionPath, user.id)
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      // Business Logic: Handles data conversion
      return ModelUser.fromMap(snapshot.data()!);
    });
  }

  /// Fetches a single user by their ID.
  Future<ModelUser?> getUser({String? userId}) async {
    try {
      userId == null ?  
      logInfo("Fetching user with ID: $userId"):
      logInfo("Fetching current user no userId supplied");
      final user = _authService.currentAppUser;   
      if (user == null) {
        logWarning("function got no users!");
        return null;
      }else{
        logInfo("got current user: ${user.email} with id: ${user.id}");
      }
      final snapshot = await (() => _firestoreRepo.getDocumentSnapShot(_collectionPath,userId ?? user.id)).withTimeoutR(
        timeout: const Duration(seconds: 5),
        retryIf: (e) => e is TimeoutException || (e is FirebaseException && e.code == 'unavailable'),
      );
      if (!snapshot.exists || snapshot.data() == null) {
        logWarning("user has no data!");
        return null;
      }else{
        logInfo("returning user data!");
        return ModelUser.fromMap(snapshot.data()!);
      }    
    } on Exception catch (e) {
      logError("Error fetching user: $e");
      rethrow;
    }
  }

  /// Updates specific fields for a user.
  Future<void> updateUser({
    String? userId,
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

    }) async {

    try {
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
      final user = _authService.currentAppUser;
      if(userId == null && user !=null){
        logInfo("updating user: ${user.email} with id: ${user.id}");
        await _firestoreRepo.updateDocument(_collectionPath, user.id, dataToUpdate).withTimeout();
        logInfo("user updated successfully");
      }else if(userId != null && user ==null ) {
        logInfo("updating user with ID: $userId");
        await _firestoreRepo.updateDocument(_collectionPath, userId , dataToUpdate).withTimeout();
        logInfo("user updated successfully");
      }else{
        logWarning("function got no user data!");
      }  
    } on Exception catch (e) {
      logError("error updating user: ${e.toString()}");
      rethrow;
    }
  }

}