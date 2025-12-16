import 'dart:async';
// Import the new consolidated ChatMessageModel model
import 'package:suefery/core/extensions/future_extension.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/service/service_firebase_ai.dart';
// Import the standard response model
import 'package:suefery/data/model/model_tool_use_response.dart'; 
import '../model/model_chat_message.dart';
import '../repository/i_repo_firestore.dart';

class ServiceChat with LogMixin{
  final IRepoFirestore _firestoreRepo;
  final ServiceFirebaseAi _firebaseAiService;

  static const String _basePath = 'chats';

  ServiceChat(this._firestoreRepo, this._firebaseAiService);

  String _getCollectionPath(String chatId) {
    return '$_basePath/$chatId/messages';
  }

  /// Gets a stream of [ModelChatMessage] for a given chat ID.
  Stream<List<ModelChatMessage>> getChatStream(String chatId) {
    final path = _getCollectionPath(chatId);
    return _firestoreRepo.getCollectionStream(
      path,
      orderBy: [OrderBy('timestamp', descending: false)],
    )
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ModelChatMessage.fromMap(doc.data());
      }).toList();
    }).handleError((error) {
      logError('Error in chat stream: $error');
      return <ModelChatMessage>[];
    });
  }

  /// Generates a new unique ID for a document in the messages subcollection.
  Future<String> generateMessageId(String chatId) async {
    final path = _getCollectionPath(chatId);
    return await _firestoreRepo.generateId(path).withTimeout();
  }

  /// Saves a new message to a specific chat using a pre-defined ID.
  Future<void> saveMessageWithId(String chatId, ModelChatMessage message) async {
    if (message.id.isEmpty) {
      logError('Error: Attempted to save message with no ID using saveMessageWithId.');
      return;
    }
    final path = _getCollectionPath(chatId);
    try {
      await _firestoreRepo.setDocument(path, message.id, message.toMap());
    } catch (e) {
      logError('Error saving message with ID: $e');
      rethrow;
    }
  }

  /// Sends a new message to a specific chat.
  Future<void> saveMessage(String chatId, ModelChatMessage message) async {
    // Content check is now in the cubit
    final path = _getCollectionPath(chatId);
    try {
      await _firestoreRepo.addDocument(path, message.toMap());
    } catch (e) {
      logError('Error sending message: $e');
      rethrow;
    }
  }

  /// Updates an existing message in a specific chat.
  Future<void> updateMessage(String chatId, ModelChatMessage message) async {
    if (message.id.isEmpty) {
      logError('Error: Attempted to update message with no ID.');
      return;
    }
    final path = _getCollectionPath(chatId);
    await _firestoreRepo.updateDocument(path, message.id, message.toMap());
  }

  /// Processes chat history and returns a structured AI response.
  Future<ModelToolUseResponse> processUserMessage(List<ModelChatMessage> chatHistory) async {
    return await _firebaseAiService.getStructuredResponse(chatHistory);
  }

  
}


