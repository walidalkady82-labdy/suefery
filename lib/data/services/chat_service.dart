import 'dart:async';
import 'package:suefery/data/models/chat_message.dart';
import 'package:suefery/data/services/firebase_ai_service.dart'; // Import FirebaseAiService
import 'package:suefery/data/enums/model_type.dart'; // Import the new enum
import 'package:suefery/data/models/ai_chat_response.dart';

import '../repositories/repo_log.dart';
import '../repositories/i_repo_firestore.dart';

class ChatService {
  final IRepoFirestore _firestoreRepo;
  final FirebaseAiService _firebaseAiService; // New dependency
  final _log = RepoLog('ChatService');

  // This logic now lives in the service
  static const String _basePath = 'chats';

  ChatService(this._firestoreRepo, this._firebaseAiService); // Update constructor

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
    } 
    on TimeoutException catch (e) {
      _log.e('Error sending message: $e');
      rethrow;
    }
    catch (e) {
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

  /// Processes a user message by selecting the appropriate AI model
  /// and returning a structured response.
  Future<AiChatResponse> processUserMessage(String chatId, String userMessage, List<ChatMessage> chatHistory) async {
    final AiModelType modelType = _selectModelType(chatId, userMessage);
    _log.i('Selected model type: $modelType for chat ID: $chatId, message: "$userMessage"');

    switch (modelType) {
      case AiModelType.order:
        final aiResponse = await _firebaseAiService.getAiOrderResponse(chatHistory);
        return AiChatResponse(orderResponse: aiResponse);
      case AiModelType.chef:
        final recipeSuggestion = await _firebaseAiService.generateRecipeSuggestion();
        return AiChatResponse(recipeSuggestion: recipeSuggestion);
     
      default:
        // For chef-related chat or general chat, use the generic text generation
        final genericResponse = await _firebaseAiService.generateText(prompt: userMessage, history: chatHistory.map((m) => m.toMap()).toList());
        return AiChatResponse(genericChatResponse: genericResponse);
    }
  }

  /// Selects the appropriate chat model based on the chat ID and message content.
  AiModelType _selectModelType(String chatId, String message) {
    final lowerCaseMessage = message.toLowerCase();

    if (chatId.startsWith('chef-')) {
      return AiModelType.chef;
    }

    // Keywords to trigger the 'chef' model for recipe suggestions
    if (lowerCaseMessage.contains('suggest a recipe')) {
      return AiModelType.chef;
    }

    // Keywords to trigger the 'order' model
    const orderKeywords = ['buy', 'get me', 'order', 'add', 'i want'];
    if (orderKeywords.any((keyword) => lowerCaseMessage.contains(keyword))) {
      return AiModelType.order;
    }

    return AiModelType.general;
  }
}