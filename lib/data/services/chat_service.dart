import 'dart:async';
import 'package:suefery/data/models/chat_message.dart';

import '../../domain/repositories/log_repo.dart';
import '../repositories/i_firestore_repository.dart';

class ChatService {
  final IFirestoreRepo _firestoreRepo;
  final _log = LogRepo('ChatService');

  // This logic now lives in the service
  static const String _basePath = 'chats';

  ChatService(this._firestoreRepo);

  /// Builds the Firestore path for a given chat.
  String _getCollectionPath(String chatId) {
    return '$_basePath/$chatId/messages';
  }

  /// Gets a stream of [ChatMessage] for a given chat ID.
  Stream<List<ChatMessage>> getChatStream(String chatId) {
    final path = _getCollectionPath(chatId);

    return _firestoreRepo
        .quaryCollectionStream(
      path,
      orderBy: 'timestamp',
      isDescending: true, // Get latest messages first
    )
        .map((snapshot) {
      // This is the business logic from your Cubit
      final messages = snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data());
      }).toList();
      // Reverse to display chronologically (oldest at bottom)
      return messages.reversed.toList();
    }).handleError((error) {
      _log.e('Error in chat stream: $error');
      // Return an empty list on error to keep the stream alive
      return <ChatMessage>[];
    });
  }

  /// Sends a new message to a specific chat.
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    if (message.text.trim().isEmpty) return;

    final path = _getCollectionPath(chatId);

    try {
      // The repo 'add' method automatically creates an ID
      // and adds it to the map for us.
      await _firestoreRepo.add(path, message.toMap());
    } catch (e) {
      _log.e('Error sending message: $e');
      rethrow;
    }
  }

  /// Updates an existing message in a specific chat.
  Future<void> updateMessage(String chatId, ChatMessage message) async {
    if (message.id.isEmpty) {
      _log.e('Error: Attempted to update a message with an empty ID.');
      return;
    }

    final path = _getCollectionPath(chatId);
    // Use the repo's update method, targeting the specific message document
    await _firestoreRepo.update(path, message.id, message.toMap());
  }
}