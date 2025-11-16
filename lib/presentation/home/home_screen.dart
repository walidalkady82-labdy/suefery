// ignore_for_file: dead_code

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/core/widgets/chat/models/chat_item.dart';
import 'package:suefery/presentation/home/auth_cubit.dart';
import 'package:suefery/presentation/settings/settings_screen.dart';

// Import your BLoCs and States
import '../../data/enums/auth_status.dart';
import '../../data/enums/chat_message_type.dart';
import '../../data/enums/message_sender.dart';
import '../../data/services/logging_service.dart';
import 'home_cubit.dart'; 
import '../../data/enums/auth_step.dart'; // <-- IMPORT AUTH STEP

// Import your "dumb" UI Kit
import 'package:suefery/core/widgets/chat/chat_view.dart';
import 'package:suefery/core/widgets/chat/models/chat_view_io.dart';
import 'package:suefery/core/widgets/chat/models/chat_input_bar_io.dart';

// service locator
import '../../locator.dart';
import 'verification_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _showActionMenu(BuildContext context) {
    final strings = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        final cubit = context.read<HomeCubit>();
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.request_page),
                title:   Text(strings.orderTextButton),
                onTap: () {
                  Navigator.pop(bc);
                  cubit.changeView(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.pending),
                title:   Text(strings.pendingOrdersTextButton),
                onTap: () {
                  Navigator.pop(bc);
                  cubit.changeView(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title:   Text(strings.historyTitle),
                onTap: () {
                  Navigator.pop(bc);
                  cubit.changeView(2);
                },
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(context.l10n.settingsTitle), // Assuming you'll add this to your localizations
                onTap: () {
                  Navigator.pop(bc); // Close the bottom sheet
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title:  Text(strings.logoutTextButton),
                onTap: () => context.read<AuthCubit>().logOut(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// --- THE CALLBACK MAPPER ---
  /// This is simpler now. It just maps messages.
  List<ChatItem> _mapHomeStateToChatItems(AppLocalizations strings,HomeState state, HomeCubit cubit) {
    
    final items = state.messages.map((msg) {
      // We now switch on the strongly-typed enum
      switch (msg.messageType) {
          
        case ChatMessageType.videoPresentation:
          if (msg.mediaUrl == null) return null;
          return VideoPresentationItem( 
            id: msg.id,
            title: msg.content ?? strings.welcomeLottieTitle,
            videoUrl: msg.mediaUrl!,
          );

        case ChatMessageType.orderConfirmation:
          if (msg.parsedOrder == null) return null;
          return PendingOrderChatItem(
            messageId: msg.id,
            parsedOrder: msg.parsedOrder!,
            isActioned: msg.isActioned,
            actionStatus: msg.actionStatus,
            // Pass the cubit methods as callbacks
            onConfirm: (context) => cubit.confirmAndPayForOrder(context, msg.parsedOrder!, msg),
            onCancel: () => cubit.cancelParsedOrder(msg),
            onUpdateQuantity: (itemIndex, change) => cubit.updatePendingOrderItemQuantity(msg.id, itemIndex, change),
          );

        case ChatMessageType.recipe:
          // We read the typed recipe fields
          return RecipeSuggestionItem(
            id: msg.id,
            title: msg.recipeName ?? strings.recipeTitleFallback,
            description: msg.recipeIngredients?.join('\n') ?? strings.recipeNoIngredients,
            imageUrl: 'https://via.placeholder.com/150', // Add imageUrl to your model
          );
        
        case ChatMessageType.authChoice:
          return AuthChoiceItem(
            id: msg.id,
            text: msg.content ?? '',
            choices: msg.choices ?? [],
            onChoiceSelected: (choice) => cubit.handleAuthChoice(choice),
            sender: msg.senderType, 
          );

        //TODO: PromotionItem (if you implement this tool)
        case ChatMessageType.promotion:
          return null; // Placeholder

        // Default text case
        case ChatMessageType.text:
        default:
          return TextChatItem(
            id: msg.id,
            text: msg.content ?? '',
            sender: msg.senderType,
          );
      }
    }).whereType<ChatItem>().toList(); // Filter out any nulls
    
    // Add the loading indicator if Gemini is working
    if (state.geminiIsLoading) {
      items.add(const LoadingChatItem());
    }

    return items;
  }

  /// --- Helper to set the hint text in the input bar ---
  String _getHintText(AuthStep step, AppLocalizations strings) {
    // You will need to add these strings to your .arb file
    // e.g., "authHintChoice": "Type 'Sign In' or 'Register'",
    switch (step) {
      case AuthStep.awaitingChoice:
        return strings.authHintChoice; 
      case AuthStep.awaitingLoginEmail:
      case AuthStep.awaitingRegisterEmail:
        return strings.authHintEmail; 
      case AuthStep.awaitingLoginPassword:
      case AuthStep.awaitingRegisterPassword:
        return strings.authHintPassword; 
      case AuthStep.awaitingRegisterConfirm:
        return strings.authHintConfirmPassword;
      case AuthStep.none:
      default:
        return strings.chatHint; // "Type a message..."
    }
  }


@override
  Widget build(BuildContext buildContext) { // Renamed context
    final _log = LoggerRepo('HomeScreen');
    final strings = buildContext.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appBarTitle),
        actions: [
          // This action button will now only appear if the user is signed in
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState.authState == AuthStatus.authenticated) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: strings.menuTooltip,
                  onPressed: () => _showActionMenu(context),
                );
              }
              return Container(); // No actions if not signed in
            },
          ),
        ],
      ),
      body: BlocListener<AuthCubit, AuthState>(
        // This listener handles side effects, like loading data or showing errors
        listener: (context, authState) {
          final homeCubit = context.read<HomeCubit>();
          if (authState.authState == AuthStatus.authenticated) {
            // User just signed in, tell HomeCubit to load data
            homeCubit.loadChat();
            homeCubit.loadPendingOrders();
          }
          // --- build the anonymous flow ---
          if (authState.authState == AuthStatus.unauthenticated) {
            homeCubit.setupAnonymousChat(); // This kicks off the anon flow
          }
          if (authState.authState == AuthStatus.failure) {
            // Show a snackbar on login/register failure
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(authState.errorMessage)));
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final homeCubit = context.read<HomeCubit>();

            // --- handles the initial loading ---
            _log.i("Checking Auth State: ${authState.authState}");
            if (authState.authState == AuthStatus.inProgress || authState.authState == AuthStatus.none) {
              _log.i("Handle Loading (Initial check & InProgress)");
              return const Center(child: CircularProgressIndicator());
            }

            _log.i("Handle Awaiting Verification)");
            if (authState.authState == AuthStatus.awaitingVerification) {
              return VerificationView(
                onResend: () => context.read<AuthCubit>().sendEmailVerification(),
                onCancel: () => context.read<AuthCubit>().logOut(),
              );
            }

            // --- Unauthenticated and Authenticated builders ---
            
            // Both unauthenticated and authenticated users will see a ChatView.
            // The only difference is the *data* and *callbacks* we pass in.
            
            _log.i("Handle Unauthenticated, Failure, or Authenticated State");
            if (authState.authState ==  AuthStatus.unauthenticated || 
                authState.authState ==  AuthStatus.failure ||
                authState.authState ==  AuthStatus.authenticated) {
                  
                return BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, homeState) {
                    
                    final List<ChatItem> chatItems = _mapHomeStateToChatItems(strings, homeState, homeCubit);
                    final bool isAuthenticated = authState.authState == AuthStatus.authenticated;

                    // --- Configure Callbacks ---
                    final inputBarCallbacks = ChatInputBarCallbacks(
                      onSendMessage: homeCubit.submitOrderPrompt, // This now handles auth AND orders
                      onTyping: homeCubit.onTyping,
                      onShowActionMenu: isAuthenticated 
                        ? () => _showActionMenu(buildContext) // Use buildContext
                        : () {}, // No menu for anon
                      onSendVoiceOrder: isAuthenticated 
                        ? homeCubit.sendVoiceOrder
                        : () {}, // No voice for anon
                    );
                    
                    final chatViewCallbacks = ChatViewCallbacks(
                      inputBarCallbacks: inputBarCallbacks,
                    );

                    // --- Configure Input Bar UI ---
                    final inputBarInput = ChatInputBarInput(
                      isTyping: homeState.isTyping,
                      isLoading: homeState.geminiIsLoading, // Shows loading during sign-in
                      hintText: isAuthenticated 
                        ? strings.chatHint // "Type a message..."
                        : _getHintText(homeState.authStep, strings), 
                      isDisabled: false, 
                    );

                    final chatViewInput = ChatViewInput(
                      chatItems: chatItems,
                      inputBarInput: inputBarInput,
                    );
                      
                    return ChatView(
                      input: chatViewInput,
                      callbacks: chatViewCallbacks,
                    );
                  },
                );
            }

            // Should be unreachable, but good for safety
            _log.i("Fell through all auth states. Current state: ${authState.authState}");
            return Center(child: Text(strings.unknownAuthState));
          },
        ),
      ),
    );
  }
}