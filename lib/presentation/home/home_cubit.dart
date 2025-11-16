import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:suefery/core/errors/authentication_exception.dart';
// --- Consolidated Models ---
import 'package:suefery/data/models/order_model.dart';
import 'package:suefery/data/models/chat_message_model.dart';
import 'package:suefery/data/models/ai_parsed_order.dart';
import 'package:suefery/data/models/tool_use_response.dart';
//import 'package:suefery/data/models/billing_details.txt'; // For payment logic

// --- Services ---
import 'package:suefery/data/services/order_service.dart';
import 'package:suefery/data/services/auth_service.dart';
import 'package:suefery/data/services/chat_service.dart';
import 'package:suefery/data/services/logging_service.dart';
import 'package:suefery/data/services/pref_service.dart';
import 'package:suefery/locator.dart';
// import 'package:suefery/data/services/payment_service.dart'; // Uncomment when ready

// --- Enums ---
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/enums/chat_message_type.dart';

import '../../data/enums/auth_step.dart';


/// --- STATE ---
class HomeState {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool geminiIsLoading;
  final bool geminiIsSuccessful;
  final List<OrderModel> orders; // <-- Uses new consolidated OrderModel
  final bool isTyping;
  final int selectedViewIndex;
  final AuthStep authStep;
  final String authEmail;
  final String authPassword;    


  const HomeState({
    this.messages = const [],
    this.isLoading = false,
    this.geminiIsLoading = false,
    this.geminiIsSuccessful = false,
    this.orders = const [],
    this.isTyping = false,
    this.selectedViewIndex = 0,
    this.authStep = AuthStep.none,
    this.authEmail = '',
    this.authPassword = '',

  });

  HomeState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? geminiIsLoading,
    bool? geminiIsSuccessful,
    List<OrderModel>? orders, // <-- Uses new consolidated OrderModel
    bool? isTyping,
    int? selectedViewIndex,
    AuthStep? authStep,
    String? authEmail,
    String? authPassword,
    
  }) {
    return HomeState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      geminiIsLoading: geminiIsLoading ?? this.geminiIsLoading,
      geminiIsSuccessful: geminiIsSuccessful ?? this.geminiIsSuccessful,
      orders: orders ?? this.orders,
      isTyping: isTyping ?? this.isTyping,
      selectedViewIndex: selectedViewIndex ?? this.selectedViewIndex,
      authStep: authStep ?? this.authStep,
      authEmail: authEmail ?? this.authEmail,
      authPassword: authPassword ?? this.authPassword,
    );
  }
}
// --- END OF STATE ---

/// --- CUBIT ---
class HomeCubit extends Cubit<HomeState> {
  final _log = LoggerRepo('HomeCubit');

  // --- Dependencies ---
  final ChatService _chatService = sl<ChatService>();
  final OrderService _orderService = sl<OrderService>();
  final AuthService _authService = sl<AuthService>();
  final PrefService _prefService = sl<PrefService>();
  // final PaymentService _paymentService; // Uncomment when ready

// --- Configuration ---
  static const String _welcomeChatId = 'anon_welcome_v1';
  static const String _welcomeVideoUrl = "https://www.youtube.com/embed/iw4NobfELVU";

  StreamSubscription? _chatSubscription;

  // Helper getters (Assuming AuthService is injected)
// --- FIXED: Use getters to access user data directly ---
  String get currentUserId => _authService.currentAppUser?.id ?? '';
  String get currentUserName => _authService.currentAppUser?.name ?? 'Customer';
  
  // --- FIXED: Derived Chat ID ---
  String get _currentChatId => currentUserId.isNotEmpty ? currentUserId : _welcomeChatId;

  HomeCubit() : super(const HomeState()) {
    // REMOVED: Do not initialize here. The UI will explicitly call loadChat()
    // via the AuthCubit listener when the user is authenticated.
  }

  // =======================================================================
  // --- Main Public Methods (Called by UI) ---
  // =======================================================================
  void loadChat() {
    _initializeChat();
  }

  /// --- MODIFIED: This is now async and handles the whole flow ---
  Future<void> setupAnonymousChat() async {
    emit(state.copyWith(isLoading: true, messages: []));
    try {
      final hasSeenWelcome = _prefService.hasSeenWelcomeChat;
      if (hasSeenWelcome) {
        await _buildReturningAnonymousChat();
      } else {
        await _buildFirstTimeAnonymousChat();
        await _prefService.setHasSeenWelcomeChat(true);
      }
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// If we are in an auth flow, it handles the auth prompt.
  /// Otherwise, it sends the prompt to Gemini for an order.
  Future<void> submitOrderPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    // --- ROUTING LOGIC ---
    if (state.authStep != AuthStep.none) {
      await _handleAuthPrompt(prompt);
      return; // Stop here, it was an auth message
    }
    // --- End of routing logic ---

    // If the user is not logged in and not in an auth flow, they shouldn't be able to chat.
    if (currentUserId.isEmpty) {
      _log.w('Anonymous user tried to chat. Prompting to sign in.');
      await _addUserMessageToChat("Please sign in or register to start chatting.", sender: MessageSender.system);
      // Optionally, re-trigger the auth flow if needed
      emit(state.copyWith(authStep: AuthStep.awaitingChoice));
      return;
    }
    // If authStep is none, proceed as normal...
    emit(state.copyWith(geminiIsLoading: true));
    try {
      final currentHistory = List<ChatMessageModel>.from(state.messages)
        ..add(await _addUserMessageToChat(prompt));
      final aiResponse = await _chatService.processUserMessage(currentHistory);
      final aiMessageToSave = await _processAiResponse(aiResponse);
      await _chatService.sendMessage(_currentChatId, aiMessageToSave);
      emit(state.copyWith(geminiIsSuccessful: true));
    } catch (e) {
      _log.e('Error processing user message: $e');
      await _handleError(e);
    } finally {
      emit(state.copyWith(geminiIsLoading: false));
    }
  }

    Future<void> showPostVideoAuthMessages() async {
    _log.i('Video ended. Starting auth dialogue.');
    final authChoiceMessage = _createAiMessage(
      content: "Ready to get started? To save your history and place orders, please select an option below.",
      senderType: MessageSender.gemini,
      messageType: ChatMessageType.authChoice, // New message type
      choices: ['Sign In', 'Register'], // The choices for the buttons
    );
    
    emit(state.copyWith(
      messages: List.from(state.messages)..add(authChoiceMessage),
      authStep: AuthStep.awaitingChoice, // <-- SET AUTH STEP
    ));
  }

  /// A convenience method to trigger a recipe suggestion.
  Future<void> suggestRecipe() async {
    await submitOrderPrompt('suggest a recipe');
  }

  /// Fetches a generic help message from the AI.
  Future<void> getHelpMessage() async {
    // Let the AI handle the help message via its 'getHelp' tool.
    await submitOrderPrompt('help');
  }

  /// Starts the voice-to-text listener.
  Future<void> sendVoiceOrder() async {
    _log.i("Voice recording started...");
    final speech = SpeechToText();
    bool available = await speech.initialize();

    if (available) {
      speech.listen(
        localeId: 'ar_EG', // Or 'en_US'
        onResult: (result) {
          if (result.finalResult) {
            String recognizedText = result.recognizedWords;
            submitOrderPrompt(recognizedText);
          }
        },
      );
    } else {
      _log.i("The user did not grant microphone permission.");
    }
  }

  /// Called by the [PendingOrderBubble]'s "Confirm" button.
  /// 
  Future<bool?> confirmAndPayForOrder(BuildContext context, AiParsedOrder parsedOrder, ChatMessageModel message) async {
    emit(state.copyWith(isLoading: true));

    // --- 1. Calculate Total ---
    final double subtotal = parsedOrder.requestedItems.fold( 0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
    // TODO: Get fee from RemoteConfigService
    const double deliveryFee = 10.0;
    final double grandTotal = subtotal + deliveryFee;

    // --- 2. Process Payment (Logic is commented out) ---
    _log.i('Attempting payment for order...');
    // final paymentService = sl<PaymentService>(); // Get from locator
    // final billingDetails = BillingDetails(
    //   firstName: currentUserName.split(' ').first,
    //   lastName: currentUserName.split(' ').last,
    //   email: _authService.currentAppUser?.email ?? 'test@test.com',
    //   phone: _authService.currentAppUser?.phone ?? '+20123456789',
    //   city: 'Cairo', state: 'Cairo', // Placeholders
    // );
    // final paymentResponse = await paymentService.processPayment(
    //   context: context,
    //   amount: grandTotal,
    //   billingDetails: billingDetails,
    // );
    
    // --- 3. Handle Payment Result (Mocked as successful) ---
    final bool paymentSuccess = true; // Mock success
    // if (paymentResponse != null && paymentResponse.success == true) {
    if (paymentSuccess) {
      _log.i('Payment successful. Creating order...');
      try {
        _markMessageAsActioned(message, status: 'Paid');

        // Create the order in the backend
        final OrderModel newOrder = await _orderService.createOrder(
          parsedOrder,
          customerId: currentUserId,
          customerName: currentUserName,
          // paymentTransactionId: paymentResponse.transactionID, // Add this
        );

        // Update the message with the final orderId
        _markMessageAsActioned(message, status: 'Confirmed', orderId: newOrder.id);

        final confirmText =
            'Your order #${newOrder.id.substring(0, 6)} is confirmed! We are on it.';
        await _addUserMessageToChat(confirmText, sender: MessageSender.system);

        emit(state.copyWith(isLoading: false));
        return true; // Signal success to the UI
      } catch (e) {
        _log.e('Failed to create order after payment: $e');
        await _addUserMessageToChat(
            'There was an issue confirming your order after payment. Please contact support.',
            sender: MessageSender.system);
        emit(state.copyWith(isLoading: false));
        return false; // Signal failure
      }
    } else {
      _log.i('Payment failed or was cancelled by user.');
      await _addUserMessageToChat('Payment failed. Please try again.',
          sender: MessageSender.system);
      emit(state.copyWith(isLoading: false));
      return false; // Signal failure
    }
  }

  /// Called by the [PendingOrderBubble]'s "Cancel" button.
  Future<void> cancelParsedOrder(ChatMessageModel message) async {
    // This is a user-initiated cancellation from a specific bubble.
    _markMessageAsActioned(message, status: 'Cancelled');
    _log.i('User cancelled pending order.');
    // Let the AI confirm the cancellation.
    await submitOrderPrompt('The user cancelled the proposed order. Please confirm this to them.');
  }

  /// Updates the quantity of an item in a [PendingOrderBubble].
  void updatePendingOrderItemQuantity(
      String messageId, int itemIndex, int change) {
    final messageIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    final message = state.messages[messageIndex];
    if (message.parsedOrder == null) return;

    final currentItems = message.parsedOrder!.requestedItems;
    if (itemIndex >= currentItems.length) return;

    final newQuantity = currentItems[itemIndex].quantity + change;

    if (newQuantity >= 1) { // Don't allow 0 or less
      // Create new list of items
      final updatedItems = List<AiParsedItem>.from(currentItems);
      updatedItems[itemIndex] =
          updatedItems[itemIndex].copyWith(quantity: newQuantity);

      // Create new parsed order and message
      final updatedParsedOrder =
          message.parsedOrder!.copyWith(requestedItems: updatedItems);
      final updatedMessage = message.copyWith(parsedOrder: updatedParsedOrder);

      // Create new state
      final updatedMessages = List<ChatMessageModel>.from(state.messages);
      updatedMessages[messageIndex] = updatedMessage;
      emit(state.copyWith(messages: updatedMessages));
    }
  }

  /// Loads the user's order history for the 'History' tab.
  void loadPendingOrders() {
    if (currentUserId.isEmpty) return;
    _log.i('Loading order history for user: $currentUserId');
    _orderService.getOrdersForUser(currentUserId).listen(
      (orders) {
        _log.i('Order history stream updated with ${orders.length} orders.');
        emit(state.copyWith(isLoading: false, orders: orders));
      },
      onError: (error) {
        _log.e('Error in order history stream: $error');
        emit(state.copyWith(isLoading: false, orders: []));
      },
    );
  }

  // =======================================================================
  // --- Interactive Startup Logic ---
  // =======================================================================
  // THIS IS NO LONGER USED
  /*
  Future<void> initializeWelcomeMessages() async {
    // Check local storage. If they've seen it, stop.
    if (_prefService.hasSeenWelcomeChat) {
      return;
    }
    // ... rest of old code
  }
  */
    // =======================================================================
  // --- NEW: Conversational Auth Logic ---
  // =======================================================================

  /// --- REFACTORED: Routes auth prompts to the correct handler. ---
  Future<void> _handleAuthPrompt(String prompt) async {
    // Add user message to chat, masking passwords.
    await _addUserMessageToChat(_maskIfPassword(prompt), saveToDb: false);

    switch (state.authStep) {
      case AuthStep.awaitingChoice:
        await handleAuthChoice(prompt);
        break;
 
      case AuthStep.awaitingLoginEmail:
        await _handleLoginEmail(prompt);
        break;
      case AuthStep.awaitingLoginPassword:
        await _handleLoginPassword(prompt);
        break;
 
      case AuthStep.awaitingRegisterEmail:
        await _handleRegisterEmail(prompt);
        break;
      case AuthStep.awaitingRegisterPassword:
        await _handleRegisterPassword(prompt);
        break;
      case AuthStep.awaitingRegisterConfirm:
        await _handleRegisterConfirmPassword(prompt);
        break;
      default:
        break;
    }
  }

  /// --- NEW: Handles the "Sign In" or "Register" choice. ---
  Future<void> handleAuthChoice(String prompt) async {
    final choice = prompt.toLowerCase().trim();
    final userChoiceMessage = await _addUserMessageToChat(prompt, saveToDb: false);

    if (choice.contains("sign in") || choice.contains("login")) {
      final geminiPrompt = _createAiMessage(content: "Great! What's your email?");
      // Clear previous messages and show only the prompt
      emit(state.copyWith(messages: [userChoiceMessage, geminiPrompt], authStep: AuthStep.awaitingLoginEmail));
    } else if (choice.contains("register")) {
      final geminiPrompt = _createAiMessage(content: "Okay, let's create an account. What's your email?");
      // Clear previous messages and show only the prompt
      emit(state.copyWith(messages: [userChoiceMessage, geminiPrompt], authStep: AuthStep.awaitingRegisterEmail));
    } else {
      await _addUserMessageToChat("Sorry, I didn't get that. Please type **Sign In** or **Register**.", sender: MessageSender.gemini, saveToDb: false);
    }
  }

  /// --- NEW: Handles the email step for both login and registration. ---
  Future<void> _handleLoginEmail(String email) async {
    if (!_isValidEmail(email)) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
      final geminiMessage = _createAiMessage(content: "That doesn't look like a valid email. Please try again.");
      emit(state.copyWith(messages: [userMessage, geminiMessage]));
      return;
    }
    final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
    final geminiMessage = _createAiMessage(content: "Thanks. Now, what's your password?");
    emit(state.copyWith(authStep: AuthStep.awaitingLoginPassword, authEmail: email.trim(), messages: [userMessage, geminiMessage]));
  }

  /// --- NEW: Handles the password step for login. ---
  Future<void> _handleLoginPassword(String password) async {
    emit(state.copyWith(geminiIsLoading: true));
    try {
      await _authService.signInWithEmailAndPassword(email: state.authEmail, password: password.trim());
      // Success is handled by the AuthCubit listener.
      emit(state.copyWith(geminiIsLoading: false, authStep: AuthStep.none, authEmail: '', authPassword: ''));
    } on firebase.FirebaseAuthException catch (e) {
      _log.e("Conversational Sign in failed: ${e.code}");
      final failure = LoginEmailPassFirebaseFailure.fromCode(e.code);
      final geminiMessage = _createAiMessage(content: "Login failed: ${failure.message}. Let's try again. What's your email?");
      emit(state.copyWith(geminiIsLoading: false, authStep: AuthStep.awaitingLoginEmail, authEmail: '', messages: [geminiMessage]));
    }
  }

  /// --- NEW: Handles the email step for registration. ---
  Future<void> _handleRegisterEmail(String email) async {
    if (!_isValidEmail(email)) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
      final geminiMessage = _createAiMessage(content: "That doesn't look like a valid email. Please enter a valid email address.");
      emit(state.copyWith(messages: [userMessage, geminiMessage]));
      return;
    }
    final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
    final geminiMessage = _createAiMessage(content: "Got it. Please create a password (at least 6 characters).");
    emit(state.copyWith(authStep: AuthStep.awaitingRegisterPassword, authEmail: email.trim(), messages: [userMessage, geminiMessage]));
  }

  /// --- NEW: Handles the password creation step. ---
  Future<void> _handleRegisterPassword(String password) async {
    if (password.trim().length < 6) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(password), saveToDb: false);
      final geminiMessage = _createAiMessage(content: "That password is a bit short. Please try a different one (at least 6 characters).");
      emit(state.copyWith(messages: [userMessage, geminiMessage]));
      return; // Stay on this step
    }
    final userMessage = await _addUserMessageToChat(_maskIfPassword(password), saveToDb: false);
    final geminiMessage = _createAiMessage(content: "Great. Please type your password again to confirm.");
    emit(state.copyWith(authStep: AuthStep.awaitingRegisterConfirm, authPassword: password.trim(), messages: [userMessage, geminiMessage]));
  }

  /// --- NEW: Handles the password confirmation step. ---
  Future<void> _handleRegisterConfirmPassword(String confirmPassword) async {
    if (state.authPassword != confirmPassword.trim()) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(confirmPassword), saveToDb: false);
      final geminiMessage = _createAiMessage(content: "Those passwords don't match. Let's start the registration over. What's your email?");
      emit(state.copyWith(
        authStep: AuthStep.awaitingRegisterEmail, 
        authEmail: '', 
        authPassword: '', 
        messages: [userMessage, geminiMessage]));
      return;
    }

    emit(state.copyWith(geminiIsLoading: true));
    try {
      await _authService.signUpWithEmailAndPassword(email: state.authEmail, password: state.authPassword);
      // Success is handled by the AuthCubit listener.
      emit(state.copyWith(geminiIsLoading: false, authStep: AuthStep.none, authEmail: '', authPassword: ''));
    } on firebase.FirebaseAuthException catch (e) {
      _log.e("Conversational Sign up failed: ${e.code}");
      final failure = RegisterFirebaseFailure.fromCode(e.code);
      final geminiMessage = _createAiMessage(content: "Sorry, sign up failed: ${failure.message}. Let's try again. What's your email?");
      emit(state.copyWith(
        geminiIsLoading: false, 
        authStep: AuthStep.awaitingRegisterEmail, 
        authEmail: '', 
        authPassword: '',
        messages: [geminiMessage]));
    }
  }

  /// --- NEW: Helper to mask password input for display. ---
  String _maskIfPassword(String prompt) {
    final isPasswordStep = state.authStep == AuthStep.awaitingLoginPassword ||
                           state.authStep == AuthStep.awaitingRegisterPassword ||
                           state.authStep == AuthStep.awaitingRegisterConfirm;
    return isPasswordStep ? '••••••••' : prompt;
  }

  /// --- NEW: Simple email validation using regex. ---
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email.trim());
  }

  // =======================================================================
  // --- Private Helper Functions (The Logic) ---
  // =======================================================================

 /// Master method to decide what chat to load based on authentication status.
  Future<void> _initializeChat() async {
    final isUserLoggedIn = currentUserId.isNotEmpty;
    _chatSubscription?.cancel();

    if (isUserLoggedIn) {
      await _prefService.setHasSeenWelcomeChat(true);
      _loadUserChatFromFirestore();
      loadPendingOrders();
    } else {
      await setupAnonymousChat();
    }
  }

  /// Loads the authenticated user's chat history from Firestore.
  void _loadUserChatFromFirestore() {
    _log.i('Loading chat history from Firestore for user: $currentUserId');
    emit(state.copyWith(isLoading: true));
    
    _chatSubscription = _chatService.getChatStream(_currentChatId).listen(
      (messages) {
        emit(state.copyWith(messages: messages, isLoading: false, authStep: AuthStep.none)); // Reset auth step
      },
      onError: (error) {
        _log.e('Error loading user chat: $error');
        emit(state.copyWith(isLoading: false));
      },
    );
  }

  Future<void> _buildFirstTimeAnonymousChat() async {
    _log.i('Building first-time interactive welcome sequence locally.');
    
    final firstMessage = _createAiMessage(
      content: "👋 Welcome to Suefery! Watch this quick video to see how I can help you.",
      senderType: MessageSender.gemini,
    );
    emit(state.copyWith(messages: [firstMessage]));
    
    await Future.delayed(const Duration(milliseconds: 1200)); 

    final videoMessage = _createAiMessage(
      content: "Suefery Presentation",
      senderType: MessageSender.gemini,
      messageType: ChatMessageType.videoPresentation,
      mediaUrl: _welcomeVideoUrl,
    );
    emit(state.copyWith(messages: [...state.messages, videoMessage]));

    await Future.delayed(const Duration(seconds: 4)); 

    // Automatically trigger the auth sequence
    await showPostVideoAuthMessages();
  }

  Future<void> _buildReturningAnonymousChat() async {
    _log.i('Building returning anonymous user prompt.');
    final authChoiceMessage = _createAiMessage(
      content: "Welcome back! To continue, please select an option below.",
      senderType: MessageSender.gemini,
      messageType: ChatMessageType.authChoice, // New message type
      choices: ['Sign In', 'Register'], // The choices for the buttons
    );
    // --- MODIFIED: Set auth step ---
    emit(state.copyWith(
      messages: [authChoiceMessage],
      authStep: AuthStep.awaitingChoice,
    ));
  }

  /// Private helper to add a message to the chat service and update state.
  Future<ChatMessageModel> _addUserMessageToChat(String text, {MessageSender sender = MessageSender.user, bool saveToDb = true}) async {
    final newMessage = ChatMessageModel(
      id: _orderService.generateId(),
      senderId: sender == MessageSender.user ? currentUserId : 'gemini', 
      content: text.trim(),
      timestamp: DateTime.now(),
      senderType: sender,
    );
    emit(state.copyWith(messages: List.from(state.messages)..add(newMessage)));
    if (currentUserId.isNotEmpty && saveToDb) {
      try {
        await _chatService.sendMessage(_currentChatId, newMessage);
      } catch (e) {
        _log.e('Error sending message: $e');
      }
    }
    return newMessage;
  }
  
/// Processes the AI's response and returns the ChatMessage to be saved.
  Future<ChatMessageModel> _processAiResponse(ToolUseResponse aiResponse) async {
     if (aiResponse.isToolCall) {
      return _handleToolCall(aiResponse);
    } else {
      return _handleTextResponse(aiResponse);
    }
  }
  
  ChatMessageModel _handleToolCall(ToolUseResponse response) {
    final args = response.arguments ?? {};
    switch (response.toolName) {
      case 'createOrder':
        return _buildOrderMessage(args);
      case 'suggestRecipe':
        return _buildRecipeMessage(args);
      case 'buildOrderFromRecipe':
        return _buildOrderFromRecipeMessage(args);
      case 'cancelOrder':
      case 'getHelp':
        return _buildInfoMessage(args);
      default:
        _log.e('Unknown tool: ${response.toolName}');
        return _buildUnknownToolMessage(response.toolName);
    }
  }
  
  ChatMessageModel _handleTextResponse(ToolUseResponse response) {
    return _createAiMessage(
      content: response.textResponse ?? "Sorry, I'm not sure what to say.",
    );
  }
  
  ChatMessageModel _buildOrderMessage(Map<String, dynamic> args) {
    final parsedOrder = AiParsedOrder.fromMap(args);
    return _createAiMessage(
      content: args['aiResponseText'] as String?,
      messageType: ChatMessageType.orderConfirmation,
      parsedOrder: parsedOrder,
    );
  }
  
  ChatMessageModel _buildRecipeMessage(Map<String, dynamic> args) {
    return _createAiMessage(
      content: 'Here is a recipe idea for you:',
      messageType: ChatMessageType.recipe,
      recipeName: args['recipeName'] as String?,
      recipeIngredients: (args['ingredients'] as List?)?.cast<String>(),
    );
  }

  ChatMessageModel _buildOrderFromRecipeMessage(Map<String, dynamic> args) {
    // Find the last recipe in the chat history
    final lastRecipe = state.messages.lastWhere(
      (m) => m.messageType == ChatMessageType.recipe,
      orElse: () => ChatMessageModel.empty(),
    );

    if (lastRecipe.id.isEmpty || lastRecipe.recipeIngredients == null) {
      return _createAiMessage(content: "Sorry, I couldn't find a recipe to order from.");
    }

    // Convert ingredients to order items (assuming a quantity of 1 and placeholder price)
    final items = lastRecipe.recipeIngredients!
        .map((ingredient) => AiParsedItem(
              itemName: ingredient,
              quantity: 1,
              unitPrice: 10.0, // Placeholder price
            ))
        .toList();

    final parsedOrder = AiParsedOrder(
      requestedItems: items,
      aiResponseText: args['aiResponseText'] as String? ?? 'Here are the ingredients from your last recipe.',
    );

    return _createAiMessage(
      content: args['aiResponseText'] as String?,
      messageType: ChatMessageType.orderConfirmation,
      parsedOrder: parsedOrder,
    );
  }

  ChatMessageModel _buildInfoMessage(Map<String, dynamic> args) {
    return _createAiMessage(
      content: (args['aiResponseText'] as String?) ?? (args['helpText'] as String?) ?? "Okay, done.",
    );
  }
  
  ChatMessageModel _buildUnknownToolMessage(String? toolName) {
    return _createAiMessage(
      content: "I understood a tool '$toolName', but I don't know how to use it.",
    );
  }
  
  Future<void> _handleError(Object e) async {
    emit(state.copyWith(geminiIsSuccessful: false));
    await _addUserMessageToChat(
      "Sorry, I had an error. Please try again.",
      sender: MessageSender.system,
    );
  }
  
  ChatMessageModel _createAiMessage({
    String? content,
    ChatMessageType messageType = ChatMessageType.text,
    MessageSender senderType = MessageSender.gemini,
    AiParsedOrder? parsedOrder,
    String? recipeName,
    List<String>? recipeIngredients,
    String? mediaUrl,
    List<String>? choices,
  }) {
    return ChatMessageModel(
      id: _orderService.generateId(),
      senderId: senderType == MessageSender.user ? currentUserId : 'gemini',
      senderType: senderType,
      timestamp: DateTime.now(),
      content: content,
      messageType: messageType,
      parsedOrder: parsedOrder,
      recipeName: recipeName,
      recipeIngredients: recipeIngredients,
      mediaUrl: mediaUrl,
      isActioned: false,
      choices: choices,
      actionStatus: null,
    );
  }
  
  void _markMessageAsActioned(ChatMessageModel message, {required String status, String? orderId}) {
    final index = state.messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      final updatedMessages = List<ChatMessageModel>.from(state.messages);
      final updatedMessage = updatedMessages[index].copyWith(
        isActioned: true, 
        actionStatus: status,
      );
      updatedMessages[index] = updatedMessage;
      emit(state.copyWith(messages: updatedMessages)); 
      _chatService.updateMessage(_currentChatId, updatedMessage);
    }
  }
  // --- Lifecycle and UI State ---

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }

  void onTyping(String text) {
    emit(state.copyWith(isTyping: text.isNotEmpty));
  }

  void changeView(int index) {
    emit(state.copyWith(selectedViewIndex: index));
  }
}