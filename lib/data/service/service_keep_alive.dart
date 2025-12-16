import 'dart:async';

import 'package:suefery/core/extensions/future_extension.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/user_alive_status.dart';
import 'package:suefery/data/repository/i_repo_firestore.dart';

class ServiceKeepAlive with LogMixin {
  final IRepoFirestore _firestoreRepo;
  Timer? _keepAliveTimer;
  final String _collectionPath = 'users';

  ServiceKeepAlive(this._firestoreRepo);

  Stream<UserAliveStatus> getUserAliveStatusStream(String userId) {
    return _firestoreRepo
        .getDocumentStream(_collectionPath, userId) 
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        // Returns the status from Firestore, defaulting to offline if missing
        return UserAliveStatusExtension.fromString(data['userAliveStatus'] ?? 'inactive');
      }
      return UserAliveStatus.inactive;
    });
  }

  void startKeepAlive(String userId) {
    _keepAliveTimer?.cancel(); // Cancel any existing timer
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _updateKeepAlive(userId);
    });
    // Send one ping immediately on login
    _updateKeepAlive(userId);
  }

  void stopKeepAlive() {
    _keepAliveTimer?.cancel();
  }

  Future<void> _updateKeepAlive(String userId) async {
    try {
      await _firestoreRepo.updateDocument(
        _collectionPath,
        userId,
        {
          'userAliveStatus': UserAliveStatus.active.name,
          'lastSeen': DateTime.now().toIso8601String(),
        },
      ).withTimeout(duration: const Duration(seconds: 5));
      logInfo('Keep-Alive Ping: User $userId is online.');
    } catch (e) {
      logError('Failed to update keep-alive: $e');
    }
  }
}
