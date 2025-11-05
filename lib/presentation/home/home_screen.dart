import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/order_item.dart';
import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';
import '../../data/enums/chat_message_type.dart';
import '../../data/enums/order_status.dart';
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

    // Wrap with a BlocBuilder to ensure we have the user before building the UI
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Get the user from the AuthState
        final user = authState.user;

        // If there's no user yet, show a loading indicator.
        // This prevents trying to load a chat with a null ID.
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Once we have the user, provide the HomeCubit and build the main UI
        return BlocProvider(
          create: (context) => HomeCubit()..loadChat()..loadPendingOrders(),
          child: Scaffold(
              appBar: AppBar(
                title: Text(strings.customerTitle),
                backgroundColor: Colors.teal.shade800,
                actions: [
                  IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AuthCubit>().logOut()),
                ],
              ),
              backgroundColor: Colors.teal.shade50,
              body: DefaultTabController(
                length: 3,
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
                                Expanded(child: ChatMessageList()),
                                ChatInputBar(),
                              ],
                            ),
                          ),
                          // --- TAB 2: Pending orders ---
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Expanded(child: PendingOrdersTab()),
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
        );
      },
    );
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

/// Shows the modal bottom sheet for viewing and editing a pending order.
void _showPendingOrderDetails(BuildContext context, StructuredOrder order) {
  final cubit = context.read<HomeCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Important for taller content
    builder: (_) {
      return BlocProvider.value(
        value: cubit,
        child: PendingOrderDetailsModal(order: order),
      );
    },
  );
}

class PendingOrderDetailsModal extends StatefulWidget {
  final StructuredOrder order;
  const PendingOrderDetailsModal({super.key, required this.order});

  @override
  State<PendingOrderDetailsModal> createState() => _PendingOrderDetailsModalState();
}

class _PendingOrderDetailsModalState extends State<PendingOrderDetailsModal> {
  late List<OrderItem> _items;
  bool get _isModifiable => widget.order.status == OrderStatus.New;

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the items to modify them locally
    _items = widget.order.items.map((item) => OrderItem.fromMap(item.toMap())).toList();
  }

  void _updateQuantity(int index, int change) {
    if (!_isModifiable) return;
    setState(() {
      final newQuantity = _items[index].quantity + change;
      if (newQuantity > 0) {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${widget.order.orderId.substring(0, 6)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Status: ${widget.order.status.name}', style: Theme.of(context).textTheme.titleMedium),
          const Divider(height: 24),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Price: EGP ${item.unitPrice.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isModifiable)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _updateQuantity(index, -1),
                        ),
                      Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_isModifiable)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _updateQuantity(index, 1),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    cubit.cancelOrderById(widget.order.orderId);
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL ORDER'),
                ),
              ),
              const SizedBox(width: 12),
              // Update Button (only enabled if modifiable)
              Expanded(
                child: FilledButton(
                  onPressed: _isModifiable
                      ? () {
                          cubit.updateOrder(widget.order.orderId, _items);
                          Navigator.of(context).pop();
                        }
                      : null, // Disable button if not modifiable
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text('UPDATE ORDER'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
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
                  onPressed: () {},
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
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
    // Use BlocSelector for performance: only rebuild if the messages list changes.
    return BlocSelector<HomeCubit, HomeState, List<ChatMessage>>(
      selector: (state) => state.messages,
      builder: (context, messages) {
        // Check loading state separately to show initial spinner
        final isLoading = context.select((HomeCubit cubit) => cubit.state.isLoading);
        if (isLoading && messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];

            // Check the message type to display the correct bubble
            if (message.messageType == ChatMessageType.recipe) {
              return RecipeBubble(message: message);
            }

            // --- NEW: Handle the order confirmation bubble ---
            if (message.messageType == ChatMessageType.orderConfirmation && message.parsedOrder != null) {
              return OrderConfirmationBubble(message: message);
            }

            final isFromUser = message.senderType == MessageSender.user;
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

// --- WIDGET 5: NEW ORDER CONFIRMATION BUBBLE ---
class OrderConfirmationBubble extends StatelessWidget {
  final ChatMessage message;
  const OrderConfirmationBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    final order = message.parsedOrder!;

    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        color: Colors.amber.shade50,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text, // The AI's confirmation text
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 16),
              // List the items
              ...order.requestedItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.itemName)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              // Confirmation Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                      onPressed: () {
                        // Call the cubit's cancel method
                        cubit.cancelParsedOrder();
                      },
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        // Call the cubit's confirm method, passing the order data
                        cubit.confirmParsedOrder(order);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                      ),
                      child: const Text('CONFIRM'),
                    ),
                  ),
                ],
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
                  onTap: () => _showPendingOrderDetails(context, order),
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
