import 'dart:async';
// Import the new consolidated ChatMessageModel model
import 'package:suefery/data/services/firebase_ai_service.dart';
// Import the standard response model
import 'package:suefery/data/models/tool_use_response.dart'; 
import '../models/chat_message_model.dart';
import '../repositories/repo_log.dart';
import '../repositories/i_repo_firestore.dart';

class ChatService {
  final IRepoFirestore _firestoreRepo;
  final FirebaseAiService _firebaseAiService;
  final _log = RepoLog('ChatService');

  static const String _basePath = 'chats';

  ChatService(this._firestoreRepo, this._firebaseAiService);

  String _getCollectionPath(String chatId) {
    return '$_basePath/$chatId/messages';
  }

  /// Gets a stream of [ChatMessageModel] for a given chat ID.
  Stream<List<ChatMessageModel>> getChatStream(String chatId) {
    final path = _getCollectionPath(chatId);
    return _firestoreRepo
        .quaryCollectionStream(
      path,
      orderBy: 'timestamp',
      isDescending: false, 
    )
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromMap(doc.data());
      }).toList();
    }).handleError((error) {
      _log.e('Error in chat stream: $error');
      return <ChatMessageModel>[];
    });
  }

  /// Sends a new message to a specific chat.
  Future<void> sendMessage(String chatId, ChatMessageModel message) async {
    // Content check is now in the cubit
    final path = _getCollectionPath(chatId);
    try {
      await _firestoreRepo.add(path, message.toMap());
    } catch (e) {
      _log.e('Error sending message: $e');
      rethrow;
    }
  }

  /// Updates an existing message in a specific chat.
  Future<void> updateMessage(String chatId, ChatMessageModel message) async {
    if (message.id.isEmpty) {
      _log.e('Error: Attempted to update message with no ID.');
      return;
    }
    final path = _getCollectionPath(chatId);
    await _firestoreRepo.update(path, message.id, message.toMap());
  }

  /// --- REFACTORED: processUserMessage ---
  /// Processes chat history and returns a structured AI response.
  Future<ToolUseResponse> processUserMessage(List<ChatMessageModel> chatHistory) async {
    _log.i('Processing user message...');
    return await _firebaseAiService.getStructuredResponse(chatHistory);
  }
}