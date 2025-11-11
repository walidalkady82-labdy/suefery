
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:suefery/data/enums/model_type.dart';
import 'package:suefery/data/enums/order_status.dart';
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/ai_chat_response.dart';
import 'package:suefery/data/models/billing_details.dart';
import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/data/services/firebase_ai_service.dart';
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
  final int selectedViewIndex;
  final AiModelType aiModelType;


  const HomeState({
    this.messages = const [],
    this.isLoading = false,
    this.geminiIsLoading = false,
    this.geminiIsSuccessful = false,
    this.orders = const [],
    this.isTyping = false,
    this.selectedViewIndex = 0,
    this.aiModelType = AiModelType.general, // Provide a default value
  });

  HomeState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? geminiIsLoading,
    bool? geminiIsSuccessful,
    List<StructuredOrder>? orders,
    bool? isTyping,
    int? selectedViewIndex,
    AiModelType? aiModelType,
  }) {
    return HomeState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      geminiIsLoading: geminiIsLoading ?? this.geminiIsLoading,
      geminiIsSuccessful: geminiIsSuccessful ?? this.geminiIsSuccessful,
      orders: orders ?? this.orders, // This is now for the 'History' tab
      isTyping: isTyping ?? this.isTyping,
      selectedViewIndex: selectedViewIndex ?? this.selectedViewIndex,
      aiModelType: aiModelType ?? this.aiModelType,
    );
  }
  @override
  List<Object?> get props => [
        messages,
        isLoading,
        geminiIsLoading,
        geminiIsSuccessful,
        orders, // This is now for the 'History' tab
        isTyping,
        selectedViewIndex,
        aiModelType,
      ];
}

class HomeCubit extends Cubit<HomeState> {
  final _log = LoggerRepo('HomeCubit');
  
  HomeCubit() : super(const HomeState()); // Use a const constructor
  // Path Structure: /artifacts/{appId}/public/data/chats/{orderId}/messages/{messageId}
  
  static const String _basePath = 'chats';
  
// --- Dependencies ---
  final AuthService _authService = sl<AuthService>();
  final ChatService _chatService = sl<ChatService>();
  final OrderService _orderService = sl<OrderService>();
  //final PaymentService _paymentService = sl<PaymentService>();

  String get currentUserId => _authService.currentAppUser?.id ?? '';
// The subscription is now for the service's stream
  StreamSubscription? _chatSubscription;

  void loadChat() {
    // Cancel previous listener if any
    _log.i('Loading chat with ID: $currentUserId');
    _chatSubscription?.cancel();
    emit(state.copyWith(isLoading: true));
    _chatSubscription = _chatService.getChatStream( currentUserId).listen(
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
    emit(state.copyWith(geminiIsLoading: true));

    // 2. Add user message to chat immediately for responsiveness
    await _addUserMessageToChat(prompt);

    // 3. Process the message through the ChatService to get a structured AI response.
    try {
      final aiChatResponse =
          await _chatService.processUserMessage(currentUserId, prompt, state.messages);

      // 4. Handle the specific type of response from the service.
      if (aiChatResponse.isOrderResponse) {
        final aiResponse = aiChatResponse.orderResponse!;
        if (aiResponse.parsedOrder.orderConfirmed && aiResponse.parsedOrder.requestedItems.isNotEmpty) {
          final confirmationMessage = ChatMessage(
            id: _orderService.generateId(),
            senderId: 'gemini',
            text: aiResponse.aiResponseText,
            timestamp: DateTime.now(),
            senderType: MessageSender.gemini,
            messageType: ChatMessageType.orderConfirmation,
            parsedOrder: aiResponse.parsedOrder,
          );
          await _chatService.sendMessage(currentUserId, confirmationMessage);
        } else {
          final aiMessage = ChatMessage(
            id: _orderService.generateId(),
            senderId: 'gemini',
            text: aiResponse.aiResponseText,
            timestamp: DateTime.now(),
            senderType: MessageSender.gemini,
          );
          await _chatService.sendMessage(currentUserId, aiMessage);
        }
      } else if (aiChatResponse.isRecipeSuggestion) {
        final recipe = aiChatResponse.recipeSuggestion!;
        // The backend returns a map, let's create a nice message.
        final recipeMessage = ChatMessage(
          id: _orderService.generateId(),
          senderId: 'gemini',
          text: 'Here is a recipe idea for you:', // Title text
          timestamp: DateTime.now(),
          senderType: MessageSender.gemini,
          messageType: ChatMessageType.recipe, // Set the type
          // Extract data from the map
          recipeName: recipe['name'] as String?,
          recipeIngredients: (recipe['ingredients'] as List<dynamic>?)
              ?.map((e) => "${e['name']} (${e['quantity']})")
              .toList(),
        );
        await _chatService.sendMessage(currentUserId, recipeMessage);
      } else if (aiChatResponse.isGenericChat) {
        final aiMessage = ChatMessage(
          id: _orderService.generateId(),
          senderId: 'gemini',
          text: aiChatResponse.genericChatResponse!,
          timestamp: DateTime.now(),
          senderType: MessageSender.gemini,
        );
        await _chatService.sendMessage(currentUserId, aiMessage);
      }

      emit(state.copyWith(geminiIsSuccessful: true));
    } catch (e) {
      _log.e('Error processing user message: $e');
      emit(state.copyWith(geminiIsSuccessful: false));
    } finally {
      // This block will always run, ensuring the indicator is turned off.
      emit(state.copyWith(geminiIsLoading: false));
    }
  }

  /// A convenience method to trigger a recipe suggestion.
  Future<void> suggestRecipe() async {
    await submitOrderPrompt('suggest a recipe');
  }

  /// Fetches a generic help message from the AI and adds it to the chat.
  Future<void> getHelpMessage() async {
    emit(state.copyWith(geminiIsLoading: true));
    try {
      // We don't add the user's "Help" prompt to the chat history.
      // We just use it to get a generic response from the service.
      final aiChatResponse = await _chatService.processUserMessage(currentUserId, 'Help', state.messages);

      if (aiChatResponse.isGenericChat) {
        // Add only the AI's response to the chat.
        await _addUserMessageToChat(aiChatResponse.genericChatResponse!, sender: MessageSender.gemini);
      }
      emit(state.copyWith(geminiIsSuccessful: true));
    } catch (e) {
      _log.e('Error getting help message: $e');
      emit(state.copyWith(geminiIsSuccessful: false));
      // Optionally, add a local error message to the chat
      await _addUserMessageToChat("Sorry, I couldn't fetch help information right now.", sender: MessageSender.system);
    } finally {
      emit(state.copyWith(geminiIsLoading: false));
    }
  }
  /// Called by the modal's "Confirm" button.
  Future<bool?> confirmAndPayForOrder(BuildContext context, AiParsedOrder parsedOrder, ChatMessage message) async {
    emit(state.copyWith(isLoading: true));

    // --- 1. Calculate Total ---
    final double subtotal = parsedOrder.requestedItems.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
    const double deliveryFee = 10.0; // Placeholder
    final double grandTotal = subtotal + deliveryFee;

    // --- NEW: Create BillingDetails object ---
    // You should fetch this from the user's profile in a real app
    final billingDetails = BillingDetails(
      firstName: _authService.currentAppUser?.name.split(' ').first ?? 'Valued',
      lastName: _authService.currentAppUser?.name.split(' ').last ?? 'Customer',
      email: _authService.currentAppUser?.email ?? 'test@test.com',
      phone: _authService.currentAppUser?.phone ?? '+20123456789',
      city: 'Cairo', // Placeholder
      state: 'Cairo', // Placeholder
    );

    // --- 2. Process Payment ---
    _log.i('Attempting payment for order...');
    // final paymentResponse = await _paymentService.processPayment(
    //   context: context,
    //   amount: grandTotal,
    //   billingDetails: billingDetails,
    // );

    // --- 3. Handle Payment Result ---
    // if (paymentResponse != null && paymentResponse.success == true) {
    //   _log.i('Payment successful. Creating order...');
    //   try {
    //     // Mark message as actioned immediately after payment
    //     _markMessageAsActioned(message, status: 'Paid', clearPendingItems: true);

    //     // Create the order in the backend, now including the transaction ID
    //     final StructuredOrder newOrder = await _orderService.creatStructuredOrder(
    //         parsedOrder,
    //         customerId: currentUserId,
    //         customerName: _authService.currentAppUser?.name ?? 'Customer',
    //         // Pass the transaction ID to be saved with the order
    //         paymentTransactionId: paymentResponse.transactionID,
    //     );

    //     // Update the message with the final orderId
    //     _markMessageAsActioned(message, status: 'Confirmed', orderId: newOrder.orderId);

    //     // Add a final confirmation message to the chat
    //     final confirmText = 'Your order #${newOrder.orderId.substring(0, 6)} is confirmed! We are on it.';
    //     await _addUserMessageToChat(confirmText, sender: MessageSender.system);

    //     emit(state.copyWith(isLoading: false));
    //     return true; // Signal success to the UI
    //   } catch (e) {
    //     _log.e('Failed to create order after payment: $e');
    //     await _addUserMessageToChat('There was an issue confirming your order after payment. Please contact support.', sender: MessageSender.system);
    //     emit(state.copyWith(isLoading: false));
    //     return false; // Signal failure
    //   }
    // } else {
    //   _log.i('Payment failed or was cancelled by user.');
    //   await _addUserMessageToChat('Payment failed. Please try again.', sender: MessageSender.system);
    //   emit(state.copyWith(isLoading: false));
    //   return false; // Signal failure
    // }
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
  Future<void> cancelParsedOrder(ChatMessage message) async {
    // Disable the buttons on the message that was actioned
    _markMessageAsActioned(message, status: 'Cancelled', clearPendingItems: true);

    _log.i('User cancelled pending order.');
    const cancelText = 'Okay, I\'ve cancelled that. What else can I help you with?';
    await _addUserMessageToChat(cancelText, sender: MessageSender.system);
  } 

  /// Updates the quantity of an item in a pending order confirmation bubble.
  void updatePendingOrderItemQuantity(String messageId, int itemIndex, int change) {    
    // First, find the message
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final message = state.messages[messageIndex];
    if (message.parsedOrder == null) return;

    final currentItems = message.parsedOrder!.requestedItems;
    if (itemIndex >= currentItems.length) return;

    final newQuantity = currentItems[itemIndex].quantity + change;

    // Ensure the new quantity is valid (greater than zero)
    if (newQuantity >= 1) {
      // Copy the existing list of items
      final updatedItems = List<AiParsedItem>.from(currentItems);
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(quantity: newQuantity);
      

      final updatedParsedOrder = message.parsedOrder!.copyWith(requestedItems: updatedItems);
      final updatedMessage = message.copyWith(parsedOrder: updatedParsedOrder);

      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[messageIndex] = updatedMessage;

      emit(state.copyWith(messages: updatedMessages));
    }
  }

  /// Finds a message in the state, marks it as actioned, and updates the UI.
  void _markMessageAsActioned(ChatMessage message, {required String status, String? orderId, bool clearPendingItems = false}) {
    final index = state.messages.indexWhere((m) => m.id == message.id);

    if (index != -1) {
      final updatedMessages = List<ChatMessage>.from(state.messages);
      updatedMessages[index] = message.copyWith(isActioned: true, actionStatus: status, orderId: orderId);

      emit(state.copyWith(messages: updatedMessages)); 

      // Persist this change in the background
      _chatService.updateMessage(currentUserId, updatedMessages[index]);
    }
  }

  void loadPendingOrders() { // Now this will load for the 'History' tab
    _log.i('Loading order history...');
    final userId = _authService.currentAppUser?.id;
    if (userId == null) {
      _log.i('No user ID found. Cannot load pending orders..');
      emit(state.copyWith(isLoading: false, orders: [])); // No user
      return;
    }
    _log.i('listening to order stream');
    _chatSubscription = _orderService
        .getOrdersForUser(userId) // Using getOrdersForUser now
        .listen((orders) {
      _log.i('Order history stream updated with ${orders.length} orders.');
      emit(state.copyWith(isLoading: false, orders: orders));
    }, onError: (error) {
      _log.e('Error in order history stream: $error');
      emit(state.copyWith(isLoading: false, orders: []));
    });
  }

  /// Private helper to add a message to the chat service and update state.
  Future<void> _addUserMessageToChat(String text, {MessageSender sender = MessageSender.user}) async {
    final newMessage = ChatMessage(
      id: _orderService.generateId(),
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

  /// ---- NEW METHOD: Called from the menu to change the view ----
  void changeView(int index) {
    emit(state.copyWith(selectedViewIndex: index));
  }

}