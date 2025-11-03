
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/enums/order_status.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/order_item.dart';
import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/data/services/order_service.dart';
import 'package:suefery/locator.dart';

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
  final  String recipeName;
  final List<String> ingredients;
  final AiParsedOrder? pendingOrder;

  const HomeState({
    this.messages = const [],
    this.isLoading = false,
    this.geminiIsLoading = false,
    this.geminiIsSuccessful = false,
    this.currentOrderId,
    this.recipeName = '',
    this.ingredients = const [],
    this.pendingOrder,
  });

  HomeState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? geminiIsLoading,
    bool? geminiIsSuccessful,
    int? currentOrderId,
    String? recipeName,
    List<String>? ingredients,
    AiParsedOrder? pendingOrder,
    bool clearPendingOrder = false,
  }) {
    return HomeState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      geminiIsLoading: geminiIsLoading ?? this.geminiIsLoading,
      geminiIsSuccessful: geminiIsSuccessful ?? this.geminiIsSuccessful,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      recipeName: recipeName ?? this.recipeName,
      ingredients: ingredients ?? this.ingredients,
      pendingOrder: clearPendingOrder ? null : pendingOrder ?? this.pendingOrder,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  final log = LoggerRepo('HomeCubit');
  
  HomeCubit() : super(HomeState());
  // Path Structure: /artifacts/{appId}/public/data/chats/{orderId}/messages/{messageId}
  
  static const String _basePath = 'artifacts/default-app-id/public/data/chats';
  
// --- Dependencies ---
  final AuthService _authService = sl<AuthService>();
  final ChatService _chatService = sl<ChatService>();
  final OrderService _orderService = sl<OrderService>();

  String get currentUserId => _authService.currentAppUser?.id ?? '';
// The subscription is now for the service's stream
  StreamSubscription<List<ChatMessage>>? _chatSubscription;

  Future<void> submitOrder(String prompt) async {
    emit(state.copyWith(
      isLoading: true,
    ));
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    // S1 Logic: Mock successful conversion
    final Map<String, dynamic> mockOrder = {
      'partner': 'University Mini-Mart',
      'items': [
        {'name': 'Water', 'qty': 2, 'price': 10},
        {'name': 'Chips', 'qty': 1, 'price': 15},
      ],
      'total': 35.0,
      'notes': prompt,
    };
  }

  @visibleForTesting
  Future<void> submitOrderMock(String prompt) async {
    emit(state.copyWith(
      isLoading: true,
    ));
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    // S1 Logic: Mock successful conversion
    final Map<String, dynamic> mockOrder = {
      'partner': 'University Mini-Mart',
      'items': [
        {'name': 'Water', 'qty': 2, 'price': 10},
        {'name': 'Chips', 'qty': 1, 'price': 15},
      ],
      'total': 35.0,
      'notes': prompt,
    };
    emit(state.copyWith(
      isLoading: true,
    ));
  }

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
        log.e('Error loading chat: $error');
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
      log.e('Cannot send message, no chat is loaded.');
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
      log.e('Error sending message: $e');
    }
  }

  void updateChat(List<ChatMessage> messages) {
    emit(state.copyWith(messages: messages, isLoading: false));
  }
  
  // Future<void> submitOrderPrompt(String prompt, String userId) async {
  //   emit(state.copyWith(geminiIsLoading: true));
  //   final messages = await _chatService.generateOrderFromPromptMock(prompt, userId);
  //   emit(state.copyWith(geminiIsSuccessful: true,
  //     geminiIsLoading: false,
  //     messages: messages,
  //     ));
  // }
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
          await _chatService.getAiOrderResponse(chatHistory);

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
      log.e('Error calling Gemini service: $e');
      emit(state.copyWith(geminiIsLoading: false, geminiIsSuccessful: false));
    }
  }
  Future<void> confirmPendingOrder() async {
    if (state.pendingOrder == null) return;
    
    log.i('User confirmed order. Creating in Firestore...');
    emit(state.copyWith(isLoading: true)); // Show loading
    
    try {
      // 1. Use the helper to create the order
      final newOrderId = await _createOrderFromAi(state.pendingOrder!);
      
      // 2. Add a final confirmation message to the chat
      final confirmMessage = ChatMessage(
        senderId: 'gemini',
        text: 'Your order #${newOrderId.substring(0, 6)} is confirmed! We are on it.',
        timestamp: DateTime.now(),
        senderType: MessageSender.gemini,
      );
      
      // 3. Clear the pending order and update chat
      emit(state.copyWith(
        isLoading: false,
        messages: List.from(state.messages)..add(confirmMessage),
        clearPendingOrder: true, // <-- Clears the pending order
        currentOrderId: int.tryParse(newOrderId) ?? state.currentOrderId,
      ));

    } catch (e) {
       log.e('Failed to create order: $e');
       emit(state.copyWith(isLoading: false));
    }
  }

  /// ---- NEW METHOD: Called by the modal's "Cancel" button ----
  void cancelPendingOrder() {
    log.i('User cancelled pending order.');
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
  /// Private helper to convert an AiParsedOrder into a StructuredOrder
  /// and save it to Firestore.
  Future<String> _createOrderFromAi(AiParsedOrder parsedOrder) async {
    // 1. Generate a new, unique ID for the order
    final newOrderId = await _orderService.generateOrderId();
    
    double estimatedTotal = 0.0;

    // 2. Convert AI items to real OrderItems
    // NOTE: The AI doesn't know item IDs or prices.
    // We set them to '0' as placeholders for a human to review.
    final List<Map<String, dynamic>> orderItemsAsJson = parsedOrder.requestedItems.map((aiItem) {
      // You would have real price logic here later
      const itemPrice = 0.0; // Placeholder price
      estimatedTotal += (itemPrice * aiItem.quantity);
      
      // Convert the OrderItem-like structure to a Map (JSON)
      return {
        'itemId': '', // Placeholder
        'name': aiItem.itemName,
        'quantity': aiItem.quantity,
        'unitPrice': itemPrice,
        'notes': aiItem.notes,
      };
    }).toList();

    // 3. Build the full StructuredOrder
    final newOrder = StructuredOrder(
      orderId: newOrderId,
      customerId: currentUserId,
      partnerId: '',
      riderId: null,
      estimatedTotal: estimatedTotal,
      deliveryFee: 0.0, // Placeholder
      deliveryAddress: 'To be confirmed', // Placeholder
      status: OrderStatus.New, // Initial status
      items: orderItemsAsJson, // Use the JSON list
      createdAt: DateTime.now(),  
      progress: 0,
    );

    // 4. Use the OrderService to create the document
    try {
      await _orderService.createOrder(newOrder);
      log.i('Successfully created order: $newOrderId');
      return newOrderId;
    } catch (e) {
      log.e('Failed to save new order: $e');
      rethrow; // Re-throw to be caught by the main method
    }
  }

  Future<void> suggestRecipe() async {
    emit(state.copyWith(geminiIsLoading: true));
    final result = await _chatService.generateRecipeSuggestion();
    emit(
      state.copyWith(
        geminiIsSuccessful: true,
        geminiIsLoading: false,
        recipeName: result['name'],
        ingredients: result['ingredients']  as List<String>,
      ));
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }

}