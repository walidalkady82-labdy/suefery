import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';
import '../../data/enums/chat_message_type.dart';
import '../../data/enums/message_sender.dart';
import '../../data/models/chat_message.dart';
// import '../history/customer_order_history.txt';
import 'home_cubit.dart';

// Customer App Screen (S1 Focus)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
    
  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return BlocProvider(
      create: (context) => HomeCubit()..loadChat(12345)..loadPendingOrders(),
      child: BlocListener<HomeCubit, HomeState>(
        // This 'listenWhen' is important. It only fires
        // when a pendingOrder *appears* (goes from null to non-null).
        listenWhen: (previous, current) =>
            previous.pendingOrder == null && current.pendingOrder != null,
        listener: (context, state) {
          // When a pending order appears, show the modal
          if (state.pendingOrder != null) {
            _showOrderConfirmation(context, state.pendingOrder!);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(strings.customerTitle),
            backgroundColor: Colors.teal.shade800,
            actions: [
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),  
              IconButton(icon: const Icon(Icons.logout),onPressed: () => context.read<AuthCubit>().logOut()),
            ],
          ),
          backgroundColor: Colors.teal.shade50,
          body: DefaultTabController(
            length: 3, // Added History Tab
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.request_page), text: 'AI Order (S1)'),
                    Tab(icon: Icon(Icons.pending), text: 'Pending Orders'),
                    Tab(icon: Icon(Icons.history), text: 'History'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // --- TAB 1: Conversational Ordering (S1) ---
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                              // --- 1. THE CONVERSATION AREA ---
                              // This expands to fill all available space
                              Expanded(child: ChatMessageList(),),
                              // --- 2. THE TEXTING & VOICE AREA ---
                              ChatInputBar(),
                          ],
                        ),
                      ),
                      // --- TAB 2: Pending orders ---
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Expanded(child: PendingOrdersTab(),),
                          ],
                        ),
                      ),
                      // --- TAB 3: Order History ---
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(strings.orderHistoryTitle, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 16),
                            // In a real app, this list would come from a BLoC
                            Expanded(
                              child: ListView(
                                children: [
                                  _buildMetricCard(strings.orderHistoryTitle, strings.noOrders),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showOrderConfirmation(BuildContext context, AiParsedOrder order) {
    // We pass the cubit's context down so the modal can call it
    final cubit = context.read<HomeCubit>(); 
    
    showModalBottomSheet(
      context: context,
      builder: (_) {
        // We pass the cubit and the order to the modal
        return BlocProvider.value(
          value: cubit,
          child: OrderConfirmationModal(order: order),
        );
      },
      // This ensures the cubit can clear the state if dismissed
    ).whenComplete(() {
      // If the modal is just dismissed (not cancelled),
      // we should probably treat it as a cancel.
      if (cubit.state.pendingOrder != null) {
        cubit.cancelPendingOrder();
      }
    });
  }

  Widget _buildMetricCard(String title, String value) {
  return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
      ),
    );
  }
}

class OrderConfirmationModal extends StatelessWidget {
  final AiParsedOrder order;
  const OrderConfirmationModal({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Placeholder logic to calculate total price.
    // In a real app, this data would come from your state/model.
    final double totalPrice = order.requestedItems.fold(0.0, (sum, item) {
      const placeholderPrice = 10.0; // Using a placeholder price
      return sum + (item.quantity * placeholderPrice);
    });
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Your Order?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // Display Total Price
          ListTile(
            title: const Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              'EGP ${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
            ),
          ),
          const Divider(),
          // List the items from the AI
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: order.requestedItems.length,
              itemBuilder: (context, index) {
                final item = order.requestedItems[index];
                const placeholderPrice = 10.0; // Placeholder price
                final itemTotal = item.quantity * placeholderPrice;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(item.quantity.toString()),
                  ),
                  title: Text(item.itemName),
                  subtitle: Text('${item.quantity} x EGP ${placeholderPrice.toStringAsFixed(2)}'),
                  trailing: Text('EGP ${itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Confirmation buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    // 1. Call the cubit's cancel method
                    context.read<HomeCubit>().cancelPendingOrder();
                    // 2. Close the modal
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    // 1. Call the cubit's confirm method
                    context.read<HomeCubit>().confirmPendingOrder();
                    // 2. Close the modal
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                  ),
                  child: const Text('CONFIRM ORDER'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- TAB 1: AI Conversational Ordering (S1 USP) ---

  // --- WIDGET 1: THE CHAT LIST ---
class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.isLoading && state.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: state.messages.length,
          itemBuilder: (context, index) {
            final message = state.messages[index];
            
            // --- NEW LOGIC ---
            // Check the message type
            if (message.messageType == ChatMessageType.recipe) {
              return RecipeBubble(message: message);
            }

            // --- OLD LOGIC (for text) ---
            final bool isFromUser = message.senderType == 'user';
            return Align(
              alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
              child: TextBubble(message: message, isFromUser: isFromUser),
            );
          },
        );
      },
    );
  }
}

// --- WIDGET 2: RENAMED from ChatBubble to TextBubble ---
class TextBubble extends StatelessWidget {
  const TextBubble({
    super.key,
    required this.message,
    required this.isFromUser,
  });

  final ChatMessage message;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isFromUser ? Colors.green.shade100 : Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// --- WIDGET 3: NEW RECIPE BUBBLE WIDGET ---
class RecipeBubble extends StatelessWidget {
  final ChatMessage message;
  const RecipeBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        color: Colors.blue.shade50, // Special color
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.recipeName ?? "Recipe Suggestion",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Divider(height: 16),
              const Text(
                "Ingredients you'll need:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // Loop through the ingredients
              if (message.recipeIngredients != null)
                ...message.recipeIngredients!.map(
                  (ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• ", style: TextStyle(color: Colors.grey.shade700)),
                        Expanded(
                          child: Text(
                            ingredient,
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET 4: CHAT INPUT BAR (STATELESS) ---
class ChatInputBar extends StatelessWidget {
  ChatInputBar({super.key});

  final TextEditingController _controller = TextEditingController();

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      context.read<HomeCubit>().submitOrderPrompt(text);
      _controller.clear();
      // After sending, notify cubit that typing has stopped
      context.read<HomeCubit>().onTyping('');
    }
  }

  void _sendVoiceOrder(BuildContext context) {
    // TODO: Implement voice order
    print("Voice order initiated");
  }

  void _showActionMenu(BuildContext context) {
    final cubit = context.read<HomeCubit>();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: const Text('Suggest a Lunch Recipe'),
                onTap: () {
                  Navigator.of(context).pop();
                  cubit.suggestRecipe();
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('My Past Orders'),
                onTap: () {
                  // TODO: Implement past orders logic
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help'),
                onTap: () {
                  // TODO: Implement help logic
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We get the cubit once
    final cubit = context.read<HomeCubit>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showActionMenu(context),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              // Call the cubit's method on every change
              onChanged: cubit.onTyping,
              decoration: InputDecoration(
                hintText: 'Type your order...',
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 4),
          // Use BlocBuilder to reactively build the button
          BlocBuilder<HomeCubit, HomeState>(
            // Only rebuild when isTyping changes
            buildWhen: (previous, current) => previous.isTyping != current.isTyping,
            builder: (context, state) {
              return FloatingActionButton(
                mini: true,
                backgroundColor: Colors.teal.shade700,
                onPressed: () {
                  if (state.isTyping) {
                    _sendMessage(context);
                  } else {
                    _sendVoiceOrder(context);
                  }
                },
                child: Icon(state.isTyping ? Icons.send : Icons.mic),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- TAB 2: Pending orders ---

class PendingOrdersTab extends StatelessWidget {
  const PendingOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Create and provide the new cubit for this tab
    return BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.orders.isEmpty) {
            return const Center(
              child: Text(
                'You have no pending orders.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final order = state.orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.receipt, color: Colors.teal),
                  ),
                  title: Text(
                    'Order #${order.orderId.substring(0, 6)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: ${order.status.name}', // e.g., "Pending"
                  ),
                  trailing: Text(
                    '${order.estimatedTotal + order.deliveryFee} EGP',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    // TODO: Navigate to order details screen
                  },
                ),
              );
            },
          );
        },
      );
  }
}

// --- TAB 3: Order history ---




class StoreBrowseTab extends StatelessWidget {
  const StoreBrowseTab({super.key});

  // Mock list of local partner stores (W2 Mitigation Focus)
  final List<String> _stores = const [
    'University Mini-Mart (0.5km)',
    'Campus Pharmacy (0.8km)',
    'Main Street Cafe (1.2km)',
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "browseStoreList",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ..._stores.map((store) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.local_mall, color: Colors.green),
                title: Text(store, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(strings!.fastestDeliveryZone),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to the store's inventory browsing screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      //strings.translate('Navigating to $store inventory...', 'الانتقال إلى مخزون $store...')
                      "Navigating to $store inventory..."
                      )),
                  );
                },
              ),
            ),
          )).toList(),
          const SizedBox(height: 24),
          const Divider(),
          // Text(
          //   strings.translate('Why order from a store?', 'لماذا تطلب من متجر؟'),
          //   style: Theme.of(context).textTheme.titleLarge,
          // ),
          // const SizedBox(height: 8),
          // Text(
          //   strings.translate('Guarantees stock availability and gives you full control over product selection, mitigating inventory errors (W2).', 'يضمن توافر المخزون ويمنحك السيطرة الكاملة على اختيار المنتج، مما يقلل من أخطاء المخزون.'),
          //   style: Theme.of(context).textTheme.bodyMedium,
          // ),
        ],
      ),
    );
  }
}
