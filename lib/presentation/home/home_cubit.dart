
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:suefery/data/enums/order_status.dart';
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/data/services/gemini_service.dart';
import 'package:suefery/data/services/order_service.dart';
import 'package:suefery/locator.dart';

import '../../data/enums/chat_message_type.dart';
import '../../data/models/order_item.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/logging_service.dart';

class HomeState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool geminiIsLoading;
  final bool geminiIsSuccessful;
  final List<StructuredOrder> orders;
  final bool isTyping;
  final AiParsedOrder? pendingOrder;


  const HomeState({
    this.messages = const [],
    this.isLoading = false,
    this.geminiIsLoading = false,
    this.geminiIsSuccessful = false,
    this.orders = const [],
    this.isTyping = false,
    this.pendingOrder,

  });

  HomeState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? geminiIsLoading,
    bool? geminiIsSuccessful,
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
  
  static const String _basePath = 'chats';
  
// --- Dependencies ---
  final AuthService _authService = sl<AuthService>();
  final ChatService _chatService = sl<ChatService>();
  final OrderService _orderService = sl<OrderService>();
  final GeminiService _geminiService = sl<GeminiService>();

  String get currentUserId => _authService.currentAppUser?.id ?? '';
// The subscription is now for the service's stream
  StreamSubscription<List<ChatMessage>>? _chatSubscription;
  StreamSubscription? _ordersSubscription;

  void loadChat() {
    // Cancel previous listener if any
    _log.i('Loading chat with ID: $currentUserId');
    _chatSubscription?.cancel();
    emit(state.copyWith(isLoading: true));
    _chatSubscription = _chatService.getChatStream(currentUserId).listen(
      (messages) {
        _log.i('Chat stream updated with ${messages.length} messages.');
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

  void updateChat(List<ChatMessage> messages) {
    _log.i('Updating chat with ${messages.length} messages.');
    emit(state.copyWith(messages: messages, isLoading: false));

  }
  /// It calls gemini, gets a response, and if confirmed,
  /// it emits a state with the `pendingOrder` property set.
  Future<void> submitOrderPrompt(String prompt) async {
    // 1. Set loading state and add user's message
    if (prompt.trim().isEmpty) return;
    emit(state.copyWith(geminiIsLoading: true, isTyping: false));

    // 2. Add user message to chat immediately for responsiveness
    await _addUserMessageToChat(prompt);

    // 3. Check if there's a pending order to confirm/cancel
    final isConfirming = state.pendingOrder != null &&
        ['yes', 'confirm', 'ok', 'yep', 'yeah', 'go ahead'].any((p) => prompt.toLowerCase().contains(p));
    final isCancelling = state.pendingOrder != null &&
        ['no', 'cancel', 'stop', 'nope'].any((p) => prompt.toLowerCase().contains(p));

    // if (isConfirming) {
    //   await confirmPendingOrder();
    //   return;
    // } else if (isCancelling) {
    //   cancelPendingOrder();
    //   return;
    // }

    // 4. If not confirming/cancelling, proceed to call Gemini
    try {
      final AiResponse aiResponse = await _geminiService.getAiOrderResponse(state.messages);

      // 5. Add AI's response message to the chat
      final aiMessage = ChatMessage(
        senderId: 'gemini',
        text: aiResponse.aiResponseText,
        timestamp: DateTime.now(),
        senderType: MessageSender.gemini,
      );
      // Don't use the helper. Add the full message object to state and service.
      emit(state.copyWith(messages: List.from(state.messages)..add(aiMessage)));
      await _chatService.sendMessage(currentUserId, aiMessage);

      // 6. Handle Gemini's response
      if (aiResponse.parsedOrder.orderConfirmed && aiResponse.parsedOrder.requestedItems.isNotEmpty) {
        // AI has parsed an order. Create a confirmation message in the chat.
        final confirmationMessage = ChatMessage(
          senderId: 'gemini',
          text: aiResponse.aiResponseText,
          timestamp: DateTime.now(),
          senderType: MessageSender.gemini,
          messageType: ChatMessageType.orderConfirmation, // <-- SET NEW TYPE
          parsedOrder: aiResponse.parsedOrder, // <-- ATTACH ORDER DATA
        );
        emit(state.copyWith(messages: List.from(state.messages)..add(confirmationMessage)));
        await _chatService.sendMessage(currentUserId, confirmationMessage);
        emit(state.copyWith(geminiIsLoading: false, geminiIsSuccessful: true));
      } else {
        // It was just a conversational message, no order detected.
        emit(state.copyWith(geminiIsLoading: false, geminiIsSuccessful: true));
      }
    } catch (e) {
      _log.e('Error calling Gemini service: $e');
      emit(state.copyWith(geminiIsLoading: false, geminiIsSuccessful: false));
    }
  }

  /// Called by the modal's "Confirm" button.
  Future<void> confirmParsedOrder(AiParsedOrder parsedOrder) async {
    
    _log.i('User confirmed order. Calling OrderService...');
    emit(state.copyWith(isLoading: true)); // Show loading
    
    try {
      // 1. Tell the OrderService to create the order.
      // We pass it the parsed order data from the chat message.
      final StructuredOrder newOrder = 
          await _orderService.creatStructuredOrder(
              parsedOrder,
              currentUserId
          );
      
      // 2. Add a final confirmation message to the chat from the system
      final confirmText = 'Your order #${newOrder.orderId.substring(0, 6)} is confirmed! The delivery fee is ${newOrder.deliveryFee} EGP. We are on it.';
      await _addUserMessageToChat(confirmText, sender: MessageSender.system);
      
      // 3. Clear the pending order and update chat
      emit(state.copyWith(
        isLoading: false,
      ));

    } catch (e) {
       _log.e('Failed to create order: $e');
       emit(state.copyWith(isLoading: false));
    }
  }

  /// Updates an existing order's items.
  Future<void> updateOrder(String orderId, List<OrderItem> items) async {
    _log.i('Updating order $orderId with ${items.length} items.');
    emit(state.copyWith(isLoading: true));
    try {
      // Convert OrderItems back to a map.
      final itemsAsMap = items.map((item) => item.toMap()).toList();
      await _orderService.updateOrder(orderId, {'items': itemsAsMap});

      // Add a system message to the chat
      final updateText = 'Order #${orderId.substring(0, 6)} has been updated.';
      await _addUserMessageToChat(updateText, sender: MessageSender.system);

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      _log.e('Failed to update order: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Cancels an order by its ID.
  Future<void> cancelOrderById(String orderId) async {
    _log.i('Cancelling order $orderId.');
    emit(state.copyWith(isLoading: true));

    await _orderService.updateOrderStatus(orderId, OrderStatus.Cancelled);
    // Add a system message to the chat
    final cancelText = 'Order #${orderId.substring(0, 6)} has been cancelled.';
    await _addUserMessageToChat(cancelText, sender: MessageSender.system);

    // The stream in `loadPendingOrders` will automatically remove it from the list.
    emit(state.copyWith(isLoading: false));
  }

  /// ---- NEW METHOD: Called by the modal's "Cancel" button ----
  Future<void> cancelParsedOrder() async {
    _log.i('User cancelled pending order.');
    const cancelText = 'Okay, I\'ve cancelled that. What else can I help you with?';
    await _addUserMessageToChat(cancelText, sender: MessageSender.system);
  }

  void loadPendingOrders() {
    _log.i('Loading pending orders...');
    emit(state.copyWith(isLoading: true));
    _ordersSubscription?.cancel();
    final userId = _authService.currentAppUser?.id;
    if (userId == null) {
      _log.i('No user ID found. Cannot load pending orders..');
      emit(state.copyWith(isLoading: false, orders: [])); // No user
      return;
    }
    _log.i('listening to order stream');
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

  /// Private helper to add a message to the chat service and update state.
  Future<void> _addUserMessageToChat(String text, {MessageSender sender = MessageSender.user}) async {
    final newMessage = ChatMessage(
      senderId: sender == MessageSender.user ? currentUserId : 'gemini',
      text: text.trim(),
      timestamp: DateTime.now(),
      senderType: sender,
    );

    // Optimistically update the UI
    emit(state.copyWith(messages: List.from(state.messages)..add(newMessage)));

    try {
      // Persist the message in the background
      await _chatService.sendMessage(currentUserId, newMessage);
    } catch (e) {
      _log.e('Error sending message: $e');
      // Optionally, handle the error, e.g., show a "failed to send" indicator.
    }
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
            submitOrderPrompt(recognizedText);
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