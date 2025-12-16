import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/app_string_keys.dart';
import 'package:suefery/data/enum/auth_step.dart';
import 'package:suefery/data/enum/chat_message_type.dart';
import 'package:suefery/data/enum/message_sender.dart';
import 'package:suefery/data/model/model_ai_parsed_order.dart';
import 'package:suefery/data/model/model_chat_message.dart';
import 'package:suefery/data/model/model_order.dart';
import 'package:suefery/data/model/model_tool_use_response.dart';
import 'package:suefery/data/service/service_auth.dart';
import 'package:suefery/data/service/service_chat.dart' show ServiceChat;
import 'package:suefery/data/service/service_order.dart';
import 'package:suefery/locator.dart';

// --- STATE ---
class StateChat extends Equatable {
  final List<ModelChatMessage> messages;
  final bool isLoading;
  final bool geminiIsLoading;
  final bool isTyping;
  final AuthStep authStep;
  final String authEmail;
  final String authPassword;
  final AppStringKey? errorKey;
  final List<String>? errorArgs;

  const StateChat({
    this.messages = const [],
    this.isLoading = false,
    this.geminiIsLoading = false,
    this.isTyping = false,
    this.authStep = AuthStep.none,
    this.authEmail = '',
    this.authPassword = '',
    this.errorKey,
    this.errorArgs,
  });

  StateChat copyWith({
    List<ModelChatMessage>? messages,
    bool? isLoading,
    bool? geminiIsLoading,
    bool? isTyping,
    AuthStep? authStep,
    String? authEmail,
    String? authPassword,
    AppStringKey? errorKey,
    List<String>? errorArgs,
  }) {
    return StateChat(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      geminiIsLoading: geminiIsLoading ?? this.geminiIsLoading,
      isTyping: isTyping ?? this.isTyping,
      authStep: authStep ?? this.authStep,
      authEmail: authEmail ?? this.authEmail,
      authPassword: authPassword ?? this.authPassword,
      errorKey: errorKey ?? this.errorKey,
      errorArgs: errorArgs ?? this.errorArgs,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, geminiIsLoading, isTyping, authStep, authEmail, authPassword,errorKey, errorArgs,];
}

// --- CUBIT ---
class CubitChat extends Cubit<StateChat> with LogMixin {
  // --- Services ---
  final ServiceChat _chatService = sl<ServiceChat>();
  final ServiceAuth _authService = sl<ServiceAuth>();
  final ServiceOrder _orderService = sl<ServiceOrder>();

  StreamSubscription? _chatSubscription;

  String get currentUserId => _authService.currentAppUser?.id ?? '';
  String get currentUserName => _authService.currentAppUser?.name ?? 'Guest';

  CubitChat() : super(const StateChat());
  // --- Lifecycle ---
  void loadChat() {
    initializeChat();
  }

  /// initialize chat stream
  void initializeChat() {
    _chatSubscription?.cancel();
    if (currentUserId.isNotEmpty) {
      logInfo("_initializeChat: getting chat (id $currentUserId)  history for user $currentUserId");
      _chatSubscription = _chatService.getChatStream(currentUserId).listen((msgs) {
        logInfo("_initializeChat: got chat history with ${msgs.length} messages");
        emit(state.copyWith(messages: msgs, isLoading: false));
      });
    }
  }

  // --- AI Processing & Tool Handling ---

  /// handle screen message
  Future<void> handleUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    final useMock = dotenv.getBool('gemini_use_mocks', fallback: false);

    // 1. Chat Flow
    emit(state.copyWith(geminiIsLoading: true));
    try {
      // Create and save the user's message
      final userMessage = await _addUserMessageToChat(text);

      // Prepare history for the AI model, including the new user message
      final history = List<ModelChatMessage>.from(state.messages)..add(userMessage);

      List<ModelChatMessage> newAiMessages;
      // ignore: dead_code
      if (useMock) {
        logInfo("handleUserMessage: getting AI response (from mock)");
        newAiMessages = [MockAIResponses.mockOrderConfirmationMessage.copyWith(messageType: ChatMessageType.draftOrder)];
      // ignore: dead_code
      } else {
        logInfo("handleUserMessage: getting AI response");
        final aiResponse = await _chatService.processUserMessage(history);
        newAiMessages = _processAiResponse(aiResponse);
      }

      logInfo("handleUserMessage: processing AI response");
      for (final msg in newAiMessages) {
        if (msg.messageType == ChatMessageType.orderConfirmation && msg.parsedOrder != null) {
          if (msg.orderId != null && msg.orderId!.isNotEmpty) {
            // This is a modification of an existing order.
            logInfo("handleUserMessage: got response order and updating order bubble for order ${msg.orderId}");

            final originalMessage = state.messages.firstWhere(
              (m) => m.id == msg.orderId,
              orElse: () => ModelChatMessage.empty(),
            );

            if (originalMessage.id.isEmpty) {
              logError("Original message for order ${msg.orderId} not found!");
              return;
            }

            final updatedMessage = originalMessage.copyWith(
              parsedOrder: msg.parsedOrder,
              content: msg.content,
            );
            
            final List<ModelOrderItem> orderItems = msg.parsedOrder!.requestedItems.map((aiItem) {
              return ModelOrderItem(
                id: '',
                description: aiItem.itemName,
                brand: aiItem.brand ?? 'unknown',
                unit: aiItem.unit ?? "EA",
                quantity: aiItem.quantity,
                unitPrice: 0.0,
              );
            }).toList();

            await _orderService.updateOrder(
              msg.orderId!,
              {'items': orderItems.map((e) => e.toMap()).toList()},
            );
            
            // Also update the message in the chat
            await _chatService.updateMessage(currentUserId, updatedMessage);

          } else {
            // This is a new order.
            logInfo("handleUserMessage: got response order and creating order bubble");
            // 1. Generate a unique ID for both the message and the order.
            final docId = await _chatService.generateMessageId(currentUserId);
            final messageWithId = msg.copyWith(id: docId, orderId: docId);
            
            // 2. Create the draft order in the database
            await _orderService.createDraftOrder(
              messageWithId,
              customerId: currentUserId,
              customerName: currentUserName,
            );

            // 3. Save the message using the SAME ID.
            await _chatService.saveMessageWithId(currentUserId, messageWithId);
          }
        } else {
          // Keep original flow for other message types
          logInfo("handleUserMessage: saving message to database");
          await _chatService.saveMessage(currentUserId, msg);
        }
      }
    } catch (e) {
      logError("AI Error: $e");
      _addSystemMessage(key: AppStringKey.animationError, args: [e.toString()]);
    } finally {
      emit(state.copyWith(geminiIsLoading: false));
    }
  }

  /// handle AI response (text or tool call)
  List<ModelChatMessage> _processAiResponse(ModelToolUseResponse aiResponse) {
     if (aiResponse.isToolCall) {
      return _handleToolCall(aiResponse);
    } else {
      return [_handleTextResponse(aiResponse)];
    }
  }
  
  /// handle tool call
  List<ModelChatMessage> _handleToolCall(ModelToolUseResponse response) {
    final args = response.arguments ?? {};
    switch (response.toolName) {
      case 'createOrder':
      case 'confirmOrder':
        return _buildOrderMessages(args);
      case 'suggestRecipe':
        return [_buildRecipeMessage(args)];
      case 'addItem':
        return _buildAddItemMessage(args);
      case 'removeItem':
        return _buildRemoveItemMessage(args);
      case 'buildOrderFromRecipe':
        return [_buildOrderFromRecipeMessage(args)];
      case 'cancelOrder':
        return _buildCancelOrderMessage(args);
      case 'getHelp':
        // Assuming getHelp just returns a text response.
        return [_buildInfoMessage(args)];
      default:
        logError('Unknown tool: ${response.toolName}');
        return [_createAiMessage(content: "I don't know how to use '${response.toolName}'.")];
    }
  }

  /// handle text response
  ModelChatMessage _handleTextResponse(ModelToolUseResponse response) {
    return _createAiMessage(
      content: response.textResponse ?? "Sorry, I'm not sure what to say.",
    );
  }

  // --- Specific Builders ---

  /// build order messages
  List<ModelChatMessage> _buildOrderMessages(Map<String, dynamic> args) {
        final itemsList = ((args['parsed_order']?['requested_items'] ?? args['items']) as List)
            .map((item) => ModelAiParsedItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList();

    final aiText = (args['aiResponseText'] as String?)?.isNotEmpty == true
        ? args['aiResponseText'] as String
        : 'Please review your order.';

    final parsedOrder = ModelAiParsedOrder(
      requestedItems: itemsList,
      aiResponseText: aiText,
    );
    
    final orderMessage = _createAiMessage(
      content: aiText,
      messageType: ChatMessageType.orderConfirmation,
      parsedOrder: parsedOrder,
      orderId: args['order_id'] as String?,
    );
    return [orderMessage];
  }

  /// build recipe message
  ModelChatMessage _buildRecipeMessage(Map<String, dynamic> args) {
    return _createAiMessage(
      content: 'Here is a recipe idea for you:',
      messageType: ChatMessageType.recipe,
      recipeName: args['recipeName'] as String?,
      recipeIngredients: (args['ingredients'] as List?)?.cast<String>(),
    );
  }

  /// build order from recipe message
  ModelChatMessage _buildOrderFromRecipeMessage(Map<String, dynamic> args) {
    final lastRecipe = state.messages.lastWhere(
      (m) => m.messageType == ChatMessageType.recipe,
      orElse: () => ModelChatMessage.empty(),
    );

    if (lastRecipe.id.isEmpty || lastRecipe.recipeIngredients == null) {
      return _createAiMessage(content: "Sorry, I couldn't find a recipe to order from.");
    }

    final items = lastRecipe.recipeIngredients!
        .map((ingredient) => ModelAiParsedItem(
              itemName: ingredient,
              brand: '',
              quantity: 1, 
            ))
        .toList();

    final parsedOrder = ModelAiParsedOrder(
      requestedItems: items,
      aiResponseText: args['aiResponseText'] as String? ?? 'Here are the ingredients.',
    );

    return _createAiMessage(
      content: args['aiResponseText'] as String?,
      messageType: ChatMessageType.orderConfirmation,
      parsedOrder: parsedOrder,
    );
  }

  /// build add item message
  List<ModelChatMessage> _buildAddItemMessage(Map<String, dynamic> args) {
    final itemsList = (args['items_to_add'] as List)
        .map((item) => ModelAiParsedItem.fromMap(item as Map<String, dynamic>))
        .toList();

    final parsedOrder = ModelAiParsedOrder(
      requestedItems: itemsList,
      aiResponseText: args['ai_response_text'] as String? ?? 'Adding items.',
    );

    return [
      _createAiMessage(
        content: parsedOrder.aiResponseText,
        messageType: ChatMessageType.addOrderItem,
        parsedOrder: parsedOrder,
      )
    ];
  }

  /// build remove item message
  List<ModelChatMessage> _buildRemoveItemMessage(Map<String, dynamic> args) {
    final itemName = args['item_name'] as String;
    return [
      _createAiMessage(
        content: 'Removing $itemName.',
        messageType: ChatMessageType.removeOrderItem,
        // We can use the content field to pass the item name to the order cubit.
      )
    ];
  }

  /// build cancel order message
  List<ModelChatMessage> _buildCancelOrderMessage(Map<String, dynamic> args) {
    return [_createAiMessage(content: args['ai_response_text'] as String? ?? 'Cancelling order.', messageType: ChatMessageType.cancelOrder)];
  }
  /// build info message
  ModelChatMessage _buildInfoMessage(Map<String, dynamic> args) {
    return _createAiMessage(
      content: (args['aiResponseText'] as String?) ?? (args['helpText'] as String?) ?? "Okay, done.",
    );
  }

  /// --- Message manupilation ---
  
  Future<ModelChatMessage> _addUserMessageToChat(String text, {bool saveToDb = true}) async {
    final msg = ModelChatMessage(
      id: '',
      senderId: currentUserId,
      content: text,
      senderType: MessageSender.user,
      timestamp: DateTime.now()
    );
    if (saveToDb && currentUserId.isNotEmpty) {
      await _chatService.saveMessage(currentUserId, msg);
    }
    return msg;
  }
  
  void _addSystemMessage({required AppStringKey key, List<String>? args}) {
    final msg = _createAiMessage(key: key, args: args, senderType: MessageSender.system);
    emit(state.copyWith(messages: List.from(state.messages)..add(msg)));
  }

  ModelChatMessage _createAiMessage({
    String? content,
    AppStringKey? key,
    List<String>? args,
    
    ChatMessageType messageType = ChatMessageType.text,
    MessageSender senderType = MessageSender.gemini,
    
    ModelAiParsedOrder? parsedOrder,
    String? orderId,
    String? recipeName,
    List<String>? recipeIngredients,
    String? mediaUrl,
    List<String>? choices,
  }) {
    return ModelChatMessage(
      id: '',
      senderId: 'gemini',
      senderType: senderType,
      timestamp: DateTime.now(),
      content: content ?? (key != null ? key.name : ''),
      messageType: messageType,
      orderId: orderId,
      parsedOrder: parsedOrder,
      recipeName: recipeName,
      recipeIngredients: recipeIngredients,
      mediaUrl: mediaUrl,
      choices: choices,
      
      isActioned: false,
      actionStatus: null,
    );
  }
  
  void showAuthErrorAsBubble(String errorMessage) {
    logInfo('Displaying auth error as bubble: $errorMessage');
    final errorBubble = _createAiMessage(
      content: errorMessage, 
      senderType: MessageSender.system,
      messageType: ChatMessageType.error,
    );
    // We add the error to the existing messages without clearing them.
    emit(state.copyWith(messages: List.from(state.messages)..add(errorBubble)));
  }

  void onTyping(String text) => emit(state.copyWith(isTyping: text.isNotEmpty));

  void sendVoiceOrder() { 
    
  }
}

/// A collection of mock AI responses for development and testing.
class MockAIResponses {
  /// A mock [ChatMessage] from the AI containing a structured order.
  ///
  /// This simulates the AI understanding a user's request and presenting
  /// a draft order for their review. The `StructuredOrder` is encoded
  /// in the `data` field of the chat message.
  static ModelChatMessage get mockOrderConfirmationMessage {
    // 1. Define the items for the mock order.
    // Note: You might need to adjust this based on your actual OrderItem constructor.
    final mockOrderItems = [
      ModelAiParsedItem(
        itemName: 'Classic Beef Burger',
        quantity: 2,
        brand: 'Burger Palace',
        unitPrice: 15.50, 
        unit: 'EA',
        // Assuming other fields like notes are optional
      ),
      ModelAiParsedItem(
        itemName: 'Cheesy Fries',
        brand: 'Burger Palace',
        quantity: 1,
        unitPrice: 7.00,
      ),
      ModelAiParsedItem(
        itemName: 'Chocolate Milkshake',
        brand: 'Burger Palace',
        quantity: 1,
        unitPrice: 8.25,
      ),
    ];

    // 2. Create the structured order that will be embedded in the message.
    final mockStructuredOrder = ModelAiParsedOrder(
      aiResponseText : " here is your order",
      requestedItems: mockOrderItems,
    );

    // 3. Create the chat message from the AI.
    return ModelChatMessage(
        id: 'ai_msg_001',
        senderType: MessageSender.system, // Or a dedicated MessageSender.ai
        senderId: 's1-ai-assistant',
        content: "I've prepared a draft of your order from Burger Palace. Please take a moment to review it.",
        timestamp: DateTime.now(),
        messageType  : ChatMessageType.orderConfirmation,
        parsedOrder: mockStructuredOrder); // The order is passed as data.
  }
}