import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
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

import '../../data/enums/app_string_keys.dart';
import '../../data/enums/auth_step.dart';
import '../../data/enums/order_status.dart';


/// --- STATE ---
class HomeState extends Equatable {
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
  final AppStringKey? errorKey;
  final List<String>? errorArgs;

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
    this.errorKey,
    this.errorArgs,
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
    AppStringKey? errorKey,
    List<String>? errorArgs,
    
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
      errorKey: errorKey ?? this.errorKey,
      errorArgs: errorArgs ?? this.errorArgs,
    );
  }
  @override
  List<Object?> get props => [messages, isLoading, geminiIsLoading, geminiIsSuccessful, orders, isTyping, selectedViewIndex, authStep, authEmail, errorArgs];
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
      // This part is tricky without context. Assuming a default or a way to get strings.
      // For now, we can't localize this without passing context.
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
      final aiMessagesToSave = _processAiResponse(aiResponse);
      for (final message in aiMessagesToSave) {
        if (message.messageType == ChatMessageType.orderConfirmation) {
          await submitDraftOrder(message);
        }
        await _chatService.sendMessage(_currentChatId, message);
      }

      emit(state.copyWith(geminiIsSuccessful: true));
    } catch (e) {
      _log.e('Error processing user message: $e');
      await _handleError(e);
    } finally {
      emit(state.copyWith(geminiIsLoading: false));
    }
  }

  /// A convenience method to trigger a recipe suggestion.
  Future<void> suggestRecipe() async {
    //TODO: Replace localized strings
    await submitOrderPrompt("Suggest a recipe");
  }

  /// Fetches a generic help message from the AI.
  Future<void> getHelpMessage() async {
    // Let the AI handle the help message via its 'getHelp' tool.
    await submitOrderPrompt("Help");
  }

  /// Starts the voice-to-text listener.
  Future<void> sendVoiceOrder(BuildContext context) async {
    _log.i("Voice recording started...");
    final speech = SpeechToText();
    bool available = await speech.initialize();

    if (available) {
      speech.listen(
        localeId: _prefService.language == 'en' ? 'en_US' : 'ar_EG',
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

  /// Submits the AI-parsed items as a "Draft" order to the backend.
  Future<void> submitDraftOrder(ChatMessageModel message) async {
    if (message.parsedOrder == null) return;

    _log.i('Submitting draft order to backend.');
    // Mark the bubble as "waiting for a quote"
    _markMessageAsActioned(message, status: 'AwaitingQuote');

    try {
      // This would create a new document in a 'draftOrders' collection
      // with a status of 'Draft'. The backend would then take over.
      // For now, we simulate the partner response.
      await _orderService.createDraftOrder( // <-- Corrected method call
        message.parsedOrder!,
        customerId: currentUserId,
        customerName: currentUserName,
      );
      //await _addUserMessageToChat("Great! We're checking with nearby partners for price and availability. This may take a moment.", sender: MessageSender.system);

    } catch (e) {
      _log.e('Failed to submit draft order: $e');
      _markMessageAsActioned(message, status: 'Draft'); // Revert status
      // This would ideally use a localized string passed from the UI.
    }
  }

  /// --- Called by the "Confirm" button in the bubble ---
  /// This confirms the user's intent to proceed with the draft order,
  /// without initiating payment.
  Future<void> confirmDraftOrder(ChatMessageModel message) async {
    if (message.parsedOrder == null || message.id.isEmpty) return;

    _log.i('User confirmed draft order. Updating status to pending_quote.');

    try {
      // The message ID is used as the draft order ID.
      await _orderService.updateOrderStatus(message.id, OrderStatus.awaitingQuote);

      // Update the bubble to show the new status.
      _markMessageAsActioned(message, status: 'Confirmed. Awaiting partner quote.');

    } catch (e) {
      _log.e('Failed to confirm draft order: $e');
      // This would ideally use a localized string passed from the UI.
    }
  }
  
  /// Called by the [PendingOrderBubble]'s "Confirm" button.
  /// 
  Future<bool?> confirmAndPayForOrder(BuildContext context, AiParsedOrder parsedOrder, ChatMessageModel message) async {
    emit(state.copyWith(isLoading: true));

    // --- 1. Calculate Total ---
    // final double subtotal = parsedOrder.requestedItems.fold( 0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
    // // TODO: Get fee from RemoteConfigService
    // const double deliveryFee = 10.0;
    // final double grandTotal = subtotal + deliveryFee;

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
        _markMessageAsActioned(message, status: 'Paid', orderId: newOrder.id);

        final confirmText = 'Your order #${newOrder.id.substring(0, 6)} is confirmed! We are on it.';
        await _addUserMessageToChat(confirmText, sender: MessageSender.system);

        emit(state.copyWith(isLoading: false));
        return true; // Signal success to the UI
      } catch (e) {
        _log.e('Failed to create order after payment: $e');
        // This would ideally use a localized string passed from the UI.
        emit(state.copyWith(isLoading: false));
        return false; // Signal failure
      }
    } else {
      _log.i('Payment failed or was cancelled by user.');
      // This would ideally use a localized string passed from the UI.
      emit(state.copyWith(isLoading: false));
      return false; // Signal failure
    }
  }

  /// Called by the [PendingOrderBubble]'s "Cancel" button.
  Future<void> cancelParsedOrder(ChatMessageModel message) async {

    // 1. Mark the message as actioned locally and get the updated message model.
    // I'm modifying _markMessageAsActioned to return the updated model.
    final updatedMessage = await _markMessageAsActioned(message, status: 'Cancelled');
    if (updatedMessage == null) return; // Safety check

    _log.i('User cancelled pending order.');

    // 2. Add a new message to simulate the user typing "cancel order".
    final currentHistory = List<ChatMessageModel>.from(state.messages)
        ..add(await _addUserMessageToChat(AppStringKey.cancelOrder, sender: MessageSender.user));

    // 3. (This was the bug) Now, we don't need to send the message again because
    // _markMessageAsActioned already updated it in Firestore.
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

  /// --- Handles the "Sign In" or "Register" choice. ---
  Future<void> handleAuthChoice(String prompt,AppLocalizations strings) async {
    final choice = prompt.toLowerCase().trim();
    final userChoiceMessage = await _addUserMessageToChat(prompt, saveToDb: false);

    if (choice.contains("sign in") || choice.contains("login")) {
      final geminiPrompt = _createAiMessage(content: strings.promptEmail);
      // Clear previous messages and show only the prompt
      emit(state.copyWith(messages: [userChoiceMessage, geminiPrompt], authStep: AuthStep.awaitingLoginEmail));
    } else if (choice.contains("register")) {
      final geminiPrompt = _createAiMessage(content: strings.registerTitle);
      // Clear previous messages and show only the prompt
      emit(state.copyWith(messages: [userChoiceMessage, geminiPrompt], authStep: AuthStep.awaitingRegisterEmail));
    } else {
      await _addUserMessageToChat(strings.invalidChoice, sender: MessageSender.gemini, saveToDb: false);
    }
  }

  /// --- Handles the email step for both login and registration. ---
  Future<void> _handleLoginEmail(String email,AppLocalizations strings) async {
    if (!_isValidEmail(email)) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
      final geminiMessage = _createAiMessage(content: strings.errorFieldInvalid('email'));
      emit(state.copyWith(messages: [userMessage, geminiMessage]));
      return;
    }
    final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
    final geminiMessage = _createAiMessage(content: strings.promptPassword);
    emit(state.copyWith(authStep: AuthStep.awaitingLoginPassword, authEmail: email.trim(), messages: [userMessage, geminiMessage]));
  }

  /// --- Handles the password step for login. ---
  Future<void> _handleLoginPassword(String password, AppLocalizations strings) async {
    emit(state.copyWith(geminiIsLoading: true));
    try {
      await _authService.signInWithEmailAndPassword(email: state.authEmail, password: password.trim());
      // Success is handled by the AuthCubit listener.
      emit(state.copyWith(geminiIsLoading: false, authStep: AuthStep.none, authEmail: '', authPassword: ''));
    } on firebase.FirebaseAuthException catch (e) {
      _log.e("Conversational Sign in failed: ${e.code}");
      final failure = LoginEmailPassFirebaseFailure.fromCode(e.code);
      final geminiMessage = _createAiMessage(content: strings.loginFailed(failure.message));
      emit(state.copyWith(geminiIsLoading: false, authStep: AuthStep.awaitingLoginEmail, authEmail: '', authPassword: '', messages: [geminiMessage]));
    }
  }

  /// --- Handles the email step for registration. ---
  Future<void> _handleRegisterEmail(String email, AppLocalizations strings) async {
    if (!_isValidEmail(email)) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
      final geminiMessage = _createAiMessage(content: strings.authInvalidEmail);
      emit(state.copyWith(messages: [userMessage, geminiMessage]));
      return;
    }
    final userMessage = await _addUserMessageToChat(_maskIfPassword(email), saveToDb: false);
    final geminiMessage = _createAiMessage(content: strings.authRegisterPromptPassword);
    emit(state.copyWith(authStep: AuthStep.awaitingRegisterPassword, authEmail: email.trim(), messages: [userMessage, geminiMessage]));
  }

  /// --- Handles the password creation step. ---
  Future<void> _handleRegisterPassword(String password, AppLocalizations strings) async {
    if (password.trim().length < 6) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(password), saveToDb: false);
      final geminiMessage = _createAiMessage(content: strings.errorPasswordLength(6));
      emit(state.copyWith(messages: [userMessage, geminiMessage]));
      return; // Stay on this step
    }
    final userMessage = await _addUserMessageToChat(_maskIfPassword(password), saveToDb: false);
    final geminiMessage = _createAiMessage(content: strings.promptConfirmPassword);
    emit(state.copyWith(authStep: AuthStep.awaitingRegisterConfirm, authPassword: password.trim(), messages: [userMessage, geminiMessage]));
  }

  /// --- Handles the password confirmation step. ---
  Future<void> _handleRegisterConfirmPassword(String confirmPassword, AppLocalizations strings) async {
    if (state.authPassword != confirmPassword.trim()) {
      final userMessage = await _addUserMessageToChat(_maskIfPassword(confirmPassword), saveToDb: false);
      final geminiMessage = _createAiMessage(content: strings.errorPasswordMismatch);
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
      final geminiMessage = _createAiMessage(content: "Sign up failed: ${failure.message}. Let's try again. What's your email?"); // Needs localization
      emit(state.copyWith(
        geminiIsLoading: false, 
        authStep: AuthStep.awaitingRegisterEmail, 
        authEmail: '', 
        authPassword: '', 
        messages: [geminiMessage]));
    }
  }

  /// --- Helper to mask password input for display. ---
  String _maskIfPassword(String prompt) {
    final isPasswordStep = state.authStep == AuthStep.awaitingLoginPassword ||
                           state.authStep == AuthStep.awaitingRegisterPassword ||
                           state.authStep == AuthStep.awaitingRegisterConfirm;
    return isPasswordStep ? '••••••••' : prompt;
  }

  /// --- Simple email validation using regex. ---
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email.trim());
  }

  /// Displays an authentication-related error message in the chat.
  void showAuthErrorAsBubble(String errorMessage) {
    _log.i('Displaying auth error as bubble: $errorMessage');
    final errorBubble = _createAiMessage(
      content: errorMessage, 
      senderType: MessageSender.system,
      messageType: ChatMessageType.error,
    );
    // We add the error to the existing messages without clearing them.
    emit(state.copyWith(messages: List.from(state.messages)..add(errorBubble)));
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
    // Simplified welcome flow for anonymous users.
    // The app tour is now shown after the first successful login.
    final authChoiceMessage = _createAiMessage(
      content: "Welcome! To get startet, please sign in or cneate an account.",
      messageType: ChatMessageType.authChoice,
      choices: ['Sign In', 'Register'],
      senderType: MessageSender.gemini,
    );
    emit(state.copyWith(
        messages: [authChoiceMessage], authStep: AuthStep.awaitingChoice));
  }

  Future<void> _buildReturningAnonymousChat() async {
    _log.i('Building returning anonymous user prompt.');
    final authChoiceMessage = _createAiMessage(
      content: "Welcome back! To continue, please select an option below.",
      senderType: MessageSender.gemini,
      messageType: ChatMessageType.authChoice, // New message type
      choices: ['Sign In', 'Register'], // The choices for the buttons
    );
    // --- MODIFIED: Set auth step -);
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
  List<ChatMessageModel> _processAiResponse(ToolUseResponse aiResponse) {
     if (aiResponse.isToolCall) {
      return _handleToolCall(aiResponse);
    } else {
      return [_handleTextResponse(aiResponse)];
    }
  }
  
  List<ChatMessageModel> _handleToolCall(ToolUseResponse response) {
    final args = response.arguments ?? {};
    switch (response.toolName) {
      case 'createOrder':
        return _buildOrderMessages(args);
      case 'confirmOrder':
        return _buildOrderMessages(args);
      case 'suggestRecipe':
        return [_buildRecipeMessage(args)];
      case 'buildOrderFromRecipe':
        return [_buildOrderFromRecipeMessage(args)];
      case 'cancelOrder':
      case 'getHelp':
        return [_buildInfoMessage(args)];
      default:
        _log.e('Unknown tool: ${response.toolName}');
        return [_buildUnknownToolMessage(response.toolName)];
    }
  }
  
  ChatMessageModel _handleTextResponse(ToolUseResponse response) {
    return _createAiMessage(
      content: response.textResponse ?? "Sorry, I'm not sure what to say.",
    );
  }
  
  List<ChatMessageModel> _buildOrderMessages(Map<String, dynamic> args) {
    final itemsList = ((args['parsed_order']?['requested_items'] ?? args['items']) as List)
        .map((item) => AiParsedItem.fromMap(item as Map<String, dynamic>))
        .toList();

    final aiText = (args['ai_response_text'] as String?)?.isNotEmpty == true
        ? args['ai_response_text'] as String
        : 'Please review your order.';

    // Manually construct the AiParsedOrder object.
    final parsedOrder = AiParsedOrder(
      requestedItems: itemsList,
      aiResponseText: aiText,
    );
    final orderMessage = _createAiMessage(
      content: aiText, // Ensure content is not null
      messageType: ChatMessageType.orderConfirmation,
      parsedOrder: parsedOrder,
    );
    return [orderMessage];
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
              brand: '',
              quantity: 1, // Price is no longer known at this stage
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
  
  Future<ChatMessageModel?> _markMessageAsActioned(ChatMessageModel message, {required String status, String? orderId}) async {
    final index = state.messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      final updatedMessages = List<ChatMessageModel>.from(state.messages);
      final updatedMessage = updatedMessages[index].copyWith(
        isActioned: true, 
        actionStatus: status,
      );
      updatedMessages[index] = updatedMessage;
      emit(state.copyWith(messages: updatedMessages)); 
      await _chatService.updateMessage(_currentChatId, updatedMessage);
      return updatedMessage;
    }
    return null;
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