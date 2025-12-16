import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/model/model_order.dart';
import 'package:suefery/presentation/auth/cubit_auth.dart';
import 'package:suefery/presentation/history/screen_order_history.dart';
import 'package:suefery/presentation/pending/screen_pending_orders.dart';

// --- Services ---

// --- Cubits ---
import 'package:suefery/presentation/home/cubit_home.dart';
import 'package:suefery/presentation/home/cubit_chat.dart';
import 'package:suefery/presentation/home/cubit_order.dart';
import 'package:suefery/presentation/home/cubit_recipe.dart';
import 'package:suefery/presentation/settings/settings_screen.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_item.dart';

// --- Enums & Models ---
import '../../data/enum/auth_status.dart';
import '../../data/enum/chat_message_type.dart';
import 'package:suefery/core/l10n/app_localizations.dart';

import '../../data/model/model_chat_message.dart';

// --- UI Kit ---
import 'package:suefery/presentation/widgets/chat/chat_view.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_view_io.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_input_bar_io.dart';
import 'package:suefery/presentation/pending/cubit_pending_orders.dart';
import 'package:collection/collection.dart';

class ScreenHome extends StatelessWidget {
  final String? orderId;
  const ScreenHome({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    // 1. Provide ALL domain cubits here
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CubitHome()),
          BlocProvider(create: (_) => CubitChat()..loadChat()),
          BlocProvider(create: (_) => CubitRecipe()),
      ],
      // By placing the listener here, it's always active and can't miss the auth state change.
      child: BlocListener<CubitAuth, StateAuth>(
        listener: (context, authState) {
          if (authState.authState == AuthStatus.authenticated) {
            // User Logged In: Load all necessary data for the home screen.
            context.read<CubitChat>().loadChat();
          } else if (authState.authState == AuthStatus.failure) {
            // Show any authentication errors directly in the chat view.
            context.read<CubitChat>().showAuthErrorAsBubble(authState.errorMessage);
          }
        },
        child: _HomeBody(),
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return BlocProvider( // Provide CubitPendingOrders here
      create: (context) => CubitPendingOrders()..loadOrderPending(),
      child: Scaffold(
          appBar: AppBar(
            title: Text(strings.appBarTitle),
            actions: [
              // Action menu only if authenticated
              BlocBuilder<CubitAuth, StateAuth>(
                builder: (context, authState) {
                  if (authState.authState == AuthStatus.authenticated) {
                    return IconButton(
                      icon: const Icon(Icons.menu),
                      tooltip: strings.menuTooltip,
                      onPressed: () => _showActionMenu(context),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: BlocBuilder<CubitHome, StateHome>(
                builder: (context, homeState) {
                  if (homeState.selectedViewIndex == 0) {
                    return _buildChatTab(context);
                  } else if (homeState.selectedViewIndex == 1) {
                    return const ScreenPendingOrders();
                  } else if (homeState.selectedViewIndex == 2) {
                    return const ScreenOrderHistory();
                  }
                  return _buildChatTab(context);
                },
            ),
          ),
          // Bottom Nav Bar controlled by CubitHome
        ),
    );
  }

  Widget _buildChatTab(BuildContext context) {
    // Rebuilds when Chat State changes (messages, loading, auth steps)
    return BlocBuilder<CubitChat, StateChat>(
      builder: (context, chatState) {
        final cubitChat = context.read<CubitChat>();
        final strings = context.l10n;

        // 1. Map Data Models to UI Items
        final chatItems = _mapChatStateToUI(context, chatState, strings);

        // 2. Configure Input Bar
        final bool isAuth = context.read<CubitAuth>().state.authState == AuthStatus.authenticated;
        
        final inputBarCallbacks = ChatInputBarCallbacks(
          onSendMessage: (text) => cubitChat.handleUserMessage(text),
          onTyping: cubitChat.onTyping,
          onShowActionMenu: isAuth ? () => _showActionMenu(context) : () {},
          onSendVoiceOrder: isAuth ? () => cubitChat.sendVoiceOrder() : () {},
        );

        final inputBarInput = ChatInputBarInput(
          isTyping: chatState.isTyping,
          isLoading: chatState.geminiIsLoading,
          hintText: strings.chatHint //isAuth ? strings.chatHint : _getAuthHintText(chatState.authStep, strings),
        );

        return ChatView(
          input: ChatViewInput(
            chatItems: chatItems,
            inputBarInput: inputBarInput,
          ),
          callbacks: ChatViewCallbacks(inputBarCallbacks: inputBarCallbacks),
        );
      },
    );
  }

  /// Maps the ChatMessageModel list to the UI widgets (Bubbles)
  List<ChatItem> _mapChatStateToUI(BuildContext context, StateChat state, AppLocalizations strings) {
    final cubitOrder = context.read<CubitOrder>();
    final List<ModelOrder> currentOrders = cubitOrder.state.orders;

    final items = state.messages.map((msg) {
      final ModelOrder? currentOrder = msg.orderId != null
          ? currentOrders.firstWhereOrNull((order) => order.id == msg.orderId)
          : null;

      switch (msg.messageType) {
        case ChatMessageType.videoPresentation:
          return VideoPresentationItem(
            id: msg.id,
            title: msg.content ?? strings.welcomeLottieTitle,
            videoUrl: msg.mediaUrl ?? "",
          );

        case ChatMessageType.orderConfirmation:
          if (msg.parsedOrder == null) return null;
          return PendingOrderChatItem(
            messageId: msg.id, 
            parsedOrder: msg.parsedOrder!,
            isActioned: msg.isActioned,
            actionStatus: msg.actionStatus,
            order: currentOrder, // Pass the current order
            // --- DELEGATE TO ORDER CUBIT ---
            onSubmitDraft: () => cubitOrder.submitDraftOrder(msg),
            onConfirm: () => cubitOrder.confirmDraftOrder(msg),
            onCancel: () => cubitOrder.cancelParsedOrder(msg),
            onUpdateQuantity: (idx, chg) => cubitOrder.updatePendingOrderItemQuantity(msg, idx, chg),
          );

        case ChatMessageType.draftOrder:
          if (msg.parsedOrder == null) return null;
          return DraftOrderItem(
            messageId: msg.id,
            parsedOrder: msg.parsedOrder!,
            order: currentOrder, // Pass the current order
            onConfirm: () => cubitOrder.confirmDraftOrder(msg),
            onCancel: () => cubitOrder.cancelParsedOrder(msg),
            onUpdateQuantity: (idx, chg) => cubitOrder.updatePendingOrderItemQuantity(msg, idx, chg),
            onAddItem: (item) => cubitOrder.addPendingOrderItem(msg, item),
            onUpdateItem: (idx, item) => cubitOrder.updatePendingOrderItem(msg, idx, item),
          );

        case ChatMessageType.recipe:
          return RecipeSuggestionItem(
            id: msg.id,
            title: msg.recipeName ?? strings.recipeTitleFallback,
            description: msg.recipeIngredients?.join('\n') ?? strings.recipeNoIngredients,
            imageUrl: 'https://via.placeholder.com/150',
          );

        // case ChatMessageType.authChoice:
        //   return AuthChoiceItem(
        //     id: msg.id,
        //     text: msg.content ?? '',
        //     choices: msg.choices ?? [],
        //     onChoiceSelected: (choice) => cubitChat.handleAuthChoice(choice),
        //     sender: msg.senderType,
        //   );
          
        case ChatMessageType.paymentSelection:
          return PaymentSelectionItem(
            id: msg.id,
            totalAmount: 150.0, // Should come from msg
            onPaymentMethodSelected: (method) {
               if (method == 'COD') {
                 cubitOrder.confirmAndPayForOrder(context, msg.parsedOrder!, msg);
               } else {
                 _handleCardPayment(context, msg);
               }
            }
          );

        default:
          return TextChatItem(
            id: msg.id,
            text: msg.content ?? '',
            sender: msg.senderType,
          );
      }
    }).whereType<ChatItem>().toList();

    if (state.geminiIsLoading) items.add(const LoadingChatItem());
    return items;
  }

  void _showActionMenu(BuildContext context) {
    final strings = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (bc) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.request_page_outlined),
                title: Text(strings.orderTextButton),
                onTap: () { 
                  Navigator.pop(bc);   
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScreenPendingOrders()));
                  },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(strings.historyTitle),
                onTap: () { 
                  Navigator.pop(bc); 
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ScreenOrderHistory()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_applications_outlined),
                title: Text(strings.settingsTitle),
                onTap: () { 
                  Navigator.pop(bc); 
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(strings.logoutTextButton),
                onTap: () { Navigator.pop(bc); context.read<CubitAuth>().logOut(); },
              ),
            ],
          ),
        );
      },
    );
  }
  
  //TODO --- Payment Helper ---
  Future<void> _handleCardPayment(BuildContext context, ModelChatMessage message) async {
     final cubitOrder = context.read<CubitOrder>();
     //Handle card payment (WebView logic) ...

     // On success:
     cubitOrder.confirmAndPayForOrder(context, message.parsedOrder!, message);
  }

}