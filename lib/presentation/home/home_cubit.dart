
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/data/services/gemini_service.dart';
import 'package:suefery/data/services/order_service.dart';
import 'package:suefery/locator.dart';

import '../../data/enums/chat_message_type.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/logging_service.dart';

class HomeState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool geminiIsLoading;
  final bool geminiIsSuccessful;
  final int? currentOrderId;
  final List<StructuredOrder> orders;
  final bool isTyping;
  final AiParsedOrder? pendingOrder;


  const HomeState({
    this.messages = const [],
    this.isLoading = false,
    this.geminiIsLoading = false,
    this.geminiIsSuccessful = false,
    this.currentOrderId,
    this.orders = const [],
    this.isTyping = false,
    this.pendingOrder,

  });

  HomeState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? geminiIsLoading,
    bool? geminiIsSuccessful,
    int? currentOrderId,
    List<StructuredOrder>? orders,
    bool? isTyping,
    AiParsedOrder? pendingOrder,
    bool clearPendingOrder = false,
  }) {
    return HomeState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      geminiIsLoading: geminiIsLoading ?? this.geminiIsLoading,
      geminiIsSuccessful: geminiIsSuccessful ?? this.geminiIsSuccessful,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      orders: orders ?? this.orders,
      isTyping: isTyping ?? this.isTyping,
      pendingOrder: clearPendingOrder ? null : pendingOrder ?? this.pendingOrder,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  final _log = LoggerRepo('HomeCubit');
  
  HomeCubit() : super(HomeState());
  // Path Structure: /artifacts/{appId}/public/data/chats/{orderId}/messages/{messageId}
  
  static const String _basePath = 'artifacts/default-app-id/public/data/chats';
  
// --- Dependencies ---
  final AuthService _authService = sl<AuthService>();
  final ChatService _chatService = sl<ChatService>();
  final OrderService _orderService = sl<OrderService>();
  final GeminiService _geminiService = sl<GeminiService>();

  String get currentUserId => _authService.currentAppUser?.id ?? '';
// The subscription is now for the service's stream
  StreamSubscription<List<ChatMessage>>? _chatSubscription;
  StreamSubscription? _ordersSubscription;

  void loadChat(int orderId) {
    // Cancel previous listener if any
    _chatSubscription?.cancel();

    emit(state.copyWith(isLoading: true, currentOrderId: orderId));

    final chatId = orderId.toString();

    // --- REFACTORED ---
    // The Cubit subscribes to the *service*, not to Firestore.
    _chatSubscription = _chatService.getChatStream(chatId).listen(
      (messages) {
        // The service already did all the mapping and reversing!
        updateChat(messages);
      },
      onError: (error) {
        _log.e('Error loading chat: $error');
        emit(state.copyWith(isLoading: false));
        // You could add an error state here
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Get the current chat ID from the state
    final chatId = state.currentOrderId?.toString();
    if (chatId == null) {
      _log.e('Cannot send message, no chat is loaded.');
      return;
    }

    final newMessage = ChatMessage(
      senderId: currentUserId,
      text: text.trim(),
      timestamp: DateTime.now(),
      senderType: MessageSender.user,
    );

    try {
      // --- REFACTORED ---
      // Delegate sending the message to the service
      await _chatService.sendMessage(chatId, newMessage);
    } catch (e) {
      _log.e('Error sending message: $e');
    }
  }

  void updateChat(List<ChatMessage> messages) {
    emit(state.copyWith(messages: messages, isLoading: false));
  }
  /// It calls gemini, gets a response, and if confirmed,
  /// it emits a state with the `pendingOrder` property set.
  Future<void> submitOrderPrompt(String prompt) async {
    // 1. Set loading state and add user's message
    emit(state.copyWith(geminiIsLoading: true));
    
    final userMessage = ChatMessage(
      senderId: currentUserId,
      text: prompt.trim(),
      timestamp: DateTime.now(),
      senderType: MessageSender.user,
    );
    
    // 2. Create the full chat history to send to Gemini
    final chatHistory = List<ChatMessage>.from(state.messages)..add(userMessage);

    try {
      // 3. Call the REAL Gemini service
      final AiResponse aiResponse = 
          await _geminiService.getAiOrderResponse(chatHistory);

      // 4. Create the AI's response message
      final aiMessage = ChatMessage(
        senderId: 'gemini',
        text: aiResponse.aiResponseText,
        timestamp: DateTime.now(),
        senderType: MessageSender.gemini,
      );

      // 5. Add AI's message to the new history
      final fullNewHistory = List<ChatMessage>.from(chatHistory)..add(aiMessage);
      
      if (aiResponse.parsedOrder.orderConfirmed) {
        // 1. Don't create the order. Just save it in the state.
        // The UI will react to this 'pendingOrder'
        emit(state.copyWith(
          geminiIsLoading: false,
          geminiIsSuccessful: true,
          messages: fullNewHistory,
          pendingOrder: aiResponse.parsedOrder, // <-- SET PENDING ORDER
        ));
      } else {
        // No order, just a normal chat message
        emit(state.copyWith(
          geminiIsLoading: false,
          geminiIsSuccessful: true,
          messages: fullNewHistory,
        ));
      }

    } catch (e) {
      _log.e('Error calling Gemini service: $e');
      emit(state.copyWith(geminiIsLoading: false, geminiIsSuccessful: false));
    }
  }
  /// Called by the modal's "Confirm" button.
  Future<void> confirmPendingOrder() async {
    if (state.pendingOrder == null) return;
    
    _log.i('User confirmed order. Calling OrderService...');
    emit(state.copyWith(isLoading: true)); // Show loading
    
    try {
      // 1. Tell the OrderService to create the order.
      // We pass it the AI data and the user ID.
      final StructuredOrder newOrder = 
          await _orderService.creatStructuredOrder(
              state.pendingOrder!, 
              currentUserId
          );
      
      // 2. Add a final confirmation message to the chat
      final confirmMessage = ChatMessage(
        senderId: 'gemini',
        text: 'Your order #${newOrder.orderId.substring(0, 6)} is confirmed! The delivery fee is ${newOrder.deliveryFee} EGP. We are on it.',
        timestamp: DateTime.now(),
        senderType: MessageSender.gemini,
      );
      
      // 3. Clear the pending order and update chat
      emit(state.copyWith(
        isLoading: false,
        messages: List.from(state.messages)..add(confirmMessage),
        clearPendingOrder: true, // Clears the pending order
        currentOrderId: int.tryParse(newOrder.orderId) ?? state.currentOrderId,
      ));

    } catch (e) {
       _log.e('Failed to create order: $e');
       emit(state.copyWith(isLoading: false));
    }
  }
  /// ---- NEW METHOD: Called by the modal's "Cancel" button ----
  void cancelPendingOrder() {
    _log.i('User cancelled pending order.');
    final cancelMessage = ChatMessage(
        senderId: 'gemini',
        text: 'Okay, I\'ve cancelled that. What else can I help you with?',
        timestamp: DateTime.now(),
        senderType: MessageSender.gemini,
      );
      
    emit(state.copyWith(
      messages: List.from(state.messages)..add(cancelMessage),
      clearPendingOrder: true, // <-- Clears the pending order
    ));
  }
 
  void loadPendingOrders() {
    emit(state.copyWith(isLoading: true));
    _ordersSubscription?.cancel();

    final userId = _authService.currentAppUser?.id;
    if (userId == null) {
      emit(state.copyWith(isLoading: false, orders: [])); // No user
      return;
    }

    _ordersSubscription = _orderService
        .getPendingOrdersStream(userId)
        .listen((orders) {
      _log.i('Pending orders stream updated with ${orders.length} orders.');
      emit(state.copyWith(isLoading: false, orders: orders));
    }, onError: (error) {
      _log.e('Error in pending orders stream: $error');
      emit(state.copyWith(isLoading: false, orders: []));
    });
  }

  Future<void> suggestRecipe() async {
    emit(state.copyWith(geminiIsLoading: true));
    
    // 1. Call the service (no change here)
    final result = await _geminiService.generateRecipeSuggestion();
    
    // 2. Get the *first* suggestion from the list
    // (Your Gemini prompt returns a 'suggestions' list)
    final suggestion = (result['suggestions'] as List).firstOrNull;
    
    if (suggestion != null) {
      // 3. Create a new ChatMessage with the recipe data
      final recipeMessage = ChatMessage(
        senderId: 'gemini',
        text: 'Here is a lunch idea for you:', // Fallback/title text
        timestamp: DateTime.now(),
        senderType: MessageSender.gemini,
        messageType: ChatMessageType.recipe, // SET THE TYPE
        recipeName: suggestion['name'],
        recipeIngredients: (suggestion['ingredients'] as List<dynamic>)
            .map((e) => "${e['name']} (${e['quantity']})") // Format ingredients
            .toList(),
      );

      // 4. Add the new message to the chat list
      emit(state.copyWith(
        geminiIsLoading: false,
        geminiIsSuccessful: true,
        messages: List.from(state.messages)..add(recipeMessage),
      ));
    } else {
      // Handle error if no suggestion was returned
      emit(state.copyWith(geminiIsLoading: false, geminiIsSuccessful: false));
    }
  }

  // void sendMessage() {
  //   // 1. Get the text from the controller and trim whitespace
  //   final text = _controller.text.trim();

  //   // 2. Check if the text is not empty
  //   if (text.isNotEmpty) {
  //     // 3. Get the instance of your HomeCubit
  //     final cubit = context.read<HomeCubit>();
      
  //     // 4. Call 'submitOrderPrompt', which sends the text to Gemini
  //     cubit.submitOrderPrompt(text);
      
  //     // 5. Clear the text field so the user can type again
  //     _controller.clear();
  //   }
  // }

  Future<void> sendVoiceOrder() async {
    // 1. Show a visual cue (e.g., a "listening..." modal)
    _log.i("Voice recording started...");
    // TODO: Initialize the speech_to_text package
    final speech = SpeechToText();
    bool available = await speech.initialize();

    // 2. Start listening
    if (available) {
      // TODO: Start listening. You need to handle the locale
      // for Arabic (e.g., 'ar_EG')
      speech.listen(
        localeId: 'ar_EG', 
        onResult: (result) {
          if (result.finalResult) {
            // 3. Get the final text
            String recognizedText = result.recognizedWords;
            
            // 4. Send the text to the _sendMessage method
            //_controller.text = recognizedText;
            sendMessage(recognizedText);
          }
        },
      );
    } else {
      _log.i("The user did not grant microphone permission.");
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }

  /// ---- NEW METHOD: Called by the text field's onChanged ----
  void onTyping(String text) {
    emit(state.copyWith(isTyping: text.isNotEmpty));
  }

}