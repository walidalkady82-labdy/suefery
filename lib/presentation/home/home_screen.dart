import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:suefery/core/l10n/app_localizations.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/order_item.dart';
import 'package:suefery/data/models/structured_order.dart';
import 'package:suefery/presentation/settings/settings_cubit.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';
import '../../data/enums/chat_message_type.dart';
import '../../data/enums/order_status.dart';
import '../../data/enums/message_sender.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/order_service.dart';
import 'package:suefery/presentation/settings/settings_screen.dart';
import '../../locator.dart';
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
        return MultiBlocProvider(
          providers: [
            BlocProvider<HomeCubit>(
              create: (context) => HomeCubit()..loadChat()..loadPendingOrders(),
            ),
            BlocProvider<SettingsCubit>(
              create: (context) => SettingsCubit()..loadSettings(),
            ),
          ],
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(strings.customerTitle),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showSettingsMenu(context);
                      },
                    ),
                    IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => context.read<AuthCubit>().logOut()),
                  ],
                ),
                body: IndexedStack(
                  index: state.selectedViewIndex,
                  children: const [
                    // --- VIEW 0: Conversational Ordering (S1) ---
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: ChatView(),
                    ),
                    // --- VIEW 1: Pending orders ---
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: PendingOrdersTab(),
                    ),
                    // --- VIEW 2: Order History ---
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: OrderHistoryTab(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Shows a menu for settings and other options.
void _showSettingsMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext bc) {
      final cubit = context.read<HomeCubit>();
      return SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.request_page),
              title: const Text('AI Order (S1)'),
              onTap: () {
                Navigator.pop(bc);
                cubit.changeView(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending),
              title: const Text('Pending Orders'),
              onTap: () {
                Navigator.pop(bc);
                cubit.changeView(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
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
          ],
        ),
      );
    },
  );
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

  @override
  void initState() {
    super.initState();
    // Create a deep copy of the items to modify them locally.
    _items = widget.order.items.map((item) => OrderItem.fromMap(item.toMap())).toList();
  }

  void _updateQuantity(int index, int change) {
    // The button's onPressed will be null if not modifiable, but this is an extra safeguard.
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
    final OrderService orderService = sl<OrderService>();

    return StreamBuilder<StructuredOrder?>(
      stream: orderService.getOrderStream(widget.order.orderId),
      builder: (context, snapshot) {
        // Use the initial order data while the stream is loading
        final currentOrder = snapshot.data ?? widget.order;
        final isModifiable = currentOrder.status == OrderStatus.New;
        // An order is cancellable if it's new or confirmed, but not yet assigned.
        final isCancellable = currentOrder.status == OrderStatus.New ||
                              currentOrder.status == OrderStatus.Confirmed;

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(heightFactor: 4, child: CircularProgressIndicator());
        }


        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${currentOrder.orderId.substring(0,6)}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // --- NEW: Replaced status text with a visual stepper ---
              if (currentOrder.status != OrderStatus.Cancelled)
                OrderStatusStepper(order: currentOrder)
              else
                Text('Status: ${currentOrder.status.name}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red)),
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
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: isModifiable ? () => _updateQuantity(index, -1) : null,
                          ), 
                          Text(item.quantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: isModifiable ? () => _updateQuantity(index, 1) : null, 
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
                    child: OutlinedButton(
                      // Changed to OutlinedButton for better styling
                      style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      onPressed: isCancellable
                          ? () {
                              cubit.cancelOrderById(currentOrder.orderId);
                              Navigator.of(context).pop();
                            }
                          : null, // Disable if not cancellable
                      child: Text(isCancellable ? 'CANCEL ORDER' : 'CANNOT CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Update Button (only enabled if modifiable)
                  Expanded(
                    child: FilledButton(
                      onPressed: isModifiable
                          ? () {
                              cubit.updateOrder(currentOrder.orderId, _items);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('UPDATE ORDER'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// --- NEW WIDGET: A stepper to visualize the order status ---
class OrderStatusStepper extends StatefulWidget {
  final StructuredOrder order;

  const OrderStatusStepper({super.key, required this.order});

  // Define the order of statuses for the stepper
  static const List<OrderStatus> stepOrder = [
    OrderStatus.New,
    OrderStatus.Confirmed,
    OrderStatus.Assigned,
    OrderStatus.OutForDelivery,
    OrderStatus.Delivered,
  ];

  // Define estimated durations for each step transition
  static const Map<OrderStatus, Duration> stepDurations = {
    OrderStatus.New: Duration(minutes: 2),
    OrderStatus.Confirmed: Duration(minutes: 5),
    OrderStatus.Assigned: Duration(minutes: 15),
    OrderStatus.OutForDelivery: Duration(minutes: 10),
    OrderStatus.Delivered: Duration.zero,
  };

  @override
  State<OrderStatusStepper> createState() => _OrderStatusStepperState();
}

class _OrderStatusStepperState extends State<OrderStatusStepper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousIndex = -1;
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _updateIndex(firstBuild: true);
  }

  @override
  void didUpdateWidget(covariant OrderStatusStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.status != widget.order.status) {
      _updateIndex();
    }
  }

  void _updateIndex({bool firstBuild = false}) {
    _previousIndex = _currentIndex;
    _currentIndex = OrderStatusStepper.stepOrder.indexOf(widget.order.status);
    if (!firstBuild && _currentIndex > _previousIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: List.generate(OrderStatusStepper.stepOrder.length * 2 - 1, (index) {
          if (index.isEven) {
            return _buildStep(context, index ~/ 2);
          } else {
            return _buildDivider(context, index ~/ 2);
          }
        }),
      ),
    );
  }

  Widget _buildStep(BuildContext context, int index) {
    final status = OrderStatusStepper.stepOrder[index];
    final isCompleted = index <= _currentIndex;
    final color = isCompleted ? Theme.of(context).colorScheme.primary : Colors.grey;

    // --- NEW: Calculate estimated time ---
    DateTime estimatedTime = widget.order.createdAt;
    for (int i = 0; i < index; i++) {
      estimatedTime = estimatedTime.add(OrderStatusStepper.stepDurations[OrderStatusStepper.stepOrder[i]]!);
    }
    // For the first step, the time is createdAt + duration of the first step
    if (index >= 0) {
       estimatedTime = estimatedTime.add(OrderStatusStepper.stepDurations[OrderStatusStepper.stepOrder[index]]!);
    }

    IconData iconData;
    String label;

    switch (status) {
      case OrderStatus.New:
        iconData = Icons.receipt_long;
        label = 'Placed';
        break;
      case OrderStatus.Confirmed:
        iconData = Icons.check_circle_outline;
        label = 'Confirmed';
        break;
      case OrderStatus.Assigned:
        iconData = Icons.kitchen_outlined;
        label = 'Preparing';
        break;
      case OrderStatus.OutForDelivery:
        iconData = Icons.delivery_dining;
        label = 'On its way';
        break;
      case OrderStatus.Delivered:
        iconData = Icons.check_circle;
        label = 'Delivered';
        break;
      default:
        iconData = Icons.help;
        label = 'Unknown';
    }

    // If this is the step that is currently being animated to, wrap it.
    if (index == _currentIndex && _currentIndex > _previousIndex) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final animatedColor = Color.lerp(Colors.grey, Theme.of(context).colorScheme.primary, _animation.value);
          return _buildIconAndLabel(context, iconData, label, animatedColor!, isCompleted, estimatedTime, index);
        },
      );
    }

    return _buildIconAndLabel(context, iconData, label, color, isCompleted, estimatedTime, index);
  }

  Widget _buildIconAndLabel(BuildContext context, IconData icon, String label, Color color, bool isCompleted, DateTime estimatedTime, int index) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // --- NEW: Display estimated time ---
      if (!isCompleted || index == _currentIndex) // Show time for current and future steps
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            DateFormat('h:mm a').format(estimatedTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        )
      else // For completed steps, just add space to keep alignment
        const SizedBox(height: 15),
    ]);
  }

  Widget _buildDivider(BuildContext context, int index) {
    final isPassed = index < _currentIndex;
    if (index == _previousIndex && _currentIndex > _previousIndex) {
      return Expanded(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Divider(color: Color.lerp(Colors.grey, Theme.of(context).colorScheme.primary, _animation.value)),
        ),
      );
    }
    return Expanded(
      child: Divider(color: isPassed ? Theme.of(context).colorScheme.primary : Colors.grey),
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
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Display Total Price
          ListTile(
            title: const Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              'EGP ${totalPrice.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor),
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
                  trailing: Text('EGP ${itemTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
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
                  }, style: FilledButton.styleFrom(
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

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom(ScrollController scrollController) {
    // A short delay ensures the list has built the new item before we scroll.
    Future.delayed(const Duration(milliseconds: 50), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) => _scrollToBottom(_scrollController),
      listenWhen: (prev, current) => prev.messages.length < current.messages.length,
      child: Column(
        children: [
          Expanded(child: ChatMessageList(scrollController: _scrollController)),
          ChatInputBar(),
        ],
      ),
    );
  }
}


class ChatMessageList extends StatelessWidget {
  final ScrollController scrollController;
  const ChatMessageList({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to react to both message list and loading state changes.
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.isLoading && state.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Add 1 to the item count if Gemini is loading to show the shimmer bubble.
        final itemCount = state.messages.length + (state.geminiIsLoading ? 1 : 0);

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(8.0),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            List<Widget> widgets = [];

            // If the index is the last one and Gemini is loading, show the typing indicator.
            if (index == state.messages.length && state.geminiIsLoading) {
              widgets.add(const TypingIndicator());
            } else {
              final message = state.messages[index];

              // Add date separator if the date changes from the previous message
              if (index == 0 ||
                  !_isSameDay(state.messages[index - 1].timestamp, message.timestamp)) {
                widgets.add(DateSeparator(date: message.timestamp));
              }

              // Check the message type to display the correct bubble
              if (message.messageType == ChatMessageType.recipe) {
                widgets.add(RecipeBubble(message: message));
              } else if (message.messageType == ChatMessageType.orderConfirmation &&
                  message.parsedOrder != null) {
                // --- NEW: Handle the order confirmation bubble ---
                widgets.add(OrderConfirmationBubble(message: message));
              } else {
                final isFromUser = message.senderType == MessageSender.user;
                widgets.add(Align(
                  alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: TextBubble(message: message, isFromUser: isFromUser),
                ));
              }
            }
            return Column(children: widgets);
          },
        );
      },
    );
  }

  // Helper function to check if two DateTimes are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}


// --- NEW WIDGET: Date Separator ---
class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          DateFormat('MMM d, yyyy').format(date),
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
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
    return Card( // This now uses CardTheme from the theme file
      color: isFromUser
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(DateFormat('hh:mm a').format(message.timestamp),
                style: Theme.of(context).textTheme.labelSmall),
          ],
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
      child: Card( // This now uses CardTheme from the theme file
        color: Colors.blue.shade50, // Special color
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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge?.copyWith(color: Colors.blue),
              ),
              const Divider(height: 16),
              Text(
                "Ingredients you'll need:",
                style: Theme.of(context).textTheme.titleMedium,
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
                        Text("• ", style: Theme.of(context).textTheme.bodySmall),
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


// --- WIDGET 6: NEW SHIMMER LOADING BUBBLE ---
class ShimmerBubble extends StatelessWidget {
  const ShimmerBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: double.infinity, height: 10.0, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: double.infinity, height: 10.0, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 40.0, height: 10.0, color: Colors.white),
              ],
            ),
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

    // Wrap the bubble's content in a BlocBuilder to react to item quantity changes. The
    // previous buildWhen condition was not reliably detecting changes in the nested
    // list. By removing it, the BlocBuilder will rebuild whenever the HomeState
    // changes, ensuring the UI reflects updated item quantities.
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // The items are now sourced directly from the message object itself,
        // as the cubit updates the message in the state when quantities change.
        final items = message.parsedOrder?.requestedItems ?? [];
        final order = message.parsedOrder!;

        final double subtotal = items.fold(0.0, (sum, item) {
          return sum + (item.quantity * item.unitPrice);
        });

        const double deliveryFee = 10.0; // Placeholder delivery fee
        final double grandTotal = subtotal + deliveryFee;

        return Align(
          alignment: Alignment.centerLeft,
          child: Card( // This now uses CardTheme from the theme file
            color: Colors.amber.shade50,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Here is your order summary:", // The AI's friendly confirmation text
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order Ref: ${message.orderId ?? '#${message.id.substring(0, 6).toUpperCase()}'}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const Divider(height: 16),
                  // --- NEW: Use a Card to give the list a "modal" look ---
                  Card( // This now uses CardTheme from the theme file
                    elevation: 0,
                    color: Colors.white.withOpacity(0.5),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Set a max height to prevent layout errors with long lists
                        maxHeight: MediaQuery.of(context).size.height * 0.2,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final itemTotal = item.quantity * item.unitPrice;
                          return ListTile(
                            dense: true,
                            title: Text(item.itemName,
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: message.isActioned
                                      ? null
                                      : () => cubit.updatePendingOrderItemQuantity(
                                          message.id, index, -1),
                                ),
                                Text(item.quantity.toString(),
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: message.isActioned
                                      ? null
                                      : () => cubit.updatePendingOrderItemQuantity(
                                          message.id, index, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.black54)),
                      Text('EGP ${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Delivery Fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee', style: TextStyle(color: Colors.black54)),
                      Text(
                        'EGP ${deliveryFee.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Grand Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'EGP ${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // --- Show status and buttons based on whether the order has been actioned --- //
                  message.isActioned && message.orderId != null ? 
                    // If the message has an orderId, listen to the live order status.
                    StreamBuilder<StructuredOrder?>(
                            stream: sl<OrderService>().getOrderStream(message.orderId!),
                            builder: (context, orderSnapshot) {
                              final currentOrder = orderSnapshot.data;
                              // An order is cancellable if it's new or confirmed.
                              final isCancellable = currentOrder != null && (currentOrder.status == OrderStatus.New || currentOrder.status == OrderStatus.Confirmed);
                              // An order is modifiable only when it is new.
                              final isModifiable = currentOrder?.status == OrderStatus.Confirmed;

                              return Column(
                                children: [
                                  // --- 1. Show Stepper if order is confirmed ---
                                  if (currentOrder != null && currentOrder.status != OrderStatus.Cancelled)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: OrderStatusStepper(order: currentOrder),
                                    )
                                  else
                                    _buildStatusChip(context, message.actionStatus ?? 'Pending'),

                                  const SizedBox(height: 12),

                                  // --- 2. Show Buttons with updated logic ---
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: isCancellable
                                              ? () => cubit.cancelOrderById(message.orderId!)
                                              : null, // Disable if not cancellable
                                          child: const Text('CANCEL'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          // Allow updating only if the order is new
                                          onPressed: isModifiable
                                              ? () => _showPendingOrderDetails(context, currentOrder!)
                                              : null,
                                          child: Text(isModifiable ? 'UPDATE' : 'CONFIRMED'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          )
                  :
                    // --- BEFORE CONFIRMATION: Show initial buttons ---
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => cubit.cancelParsedOrder(message),
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            // onPressed: () => cubit.confirmParsedOrder(order, message),
                            // child: const Text('CONFIRM'),
                            onPressed: () => cubit.confirmAndPayForOrder(context, order, message),
                            child: const Text('PROCEED TO PAY'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BuildContext context,String status) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Center(
        child: Text(
          'Order $status',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: status ==
                      'Confirmed' ||
                  status == 'Assigned' ||
                  status == 'Delivered'
              ? Colors.green.shade700
              : Colors.red.shade700),
        ),
      ),
    );
  }
}


// --- WIDGET 7: TYPING INDICATOR ---
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Card( // This now uses CardTheme from the theme file
        color: Colors.grey.shade200,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: const Text(
            "Thinking...",
            style: TextStyle(fontStyle: FontStyle.italic),
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
      color: Theme.of(context).colorScheme.surface,
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
              decoration: const InputDecoration(hintText: 'Type your order...'),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 4),
          // Use BlocBuilder to reactively build the button
          BlocBuilder<HomeCubit, HomeState>(
            // Rebuild when typing status OR loading status changes.
            buildWhen: (previous, current) =>
                previous.isTyping != current.isTyping ||
                previous.geminiIsLoading != current.geminiIsLoading,
            builder: (context, state) {
              return FloatingActionButton(
                mini: true,
                // Disable button and change color when Gemini is loading.
                backgroundColor: state.geminiIsLoading
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
                onPressed: state.geminiIsLoading
                    ? null // This disables the button
                    : () {
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
    return BlocBuilder<HomeCubit, HomeState>(builder: (context, state) {
      if (state.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      final pendingOrders = state.orders
          .where((o) =>
              o.status != OrderStatus.Delivered && o.status != OrderStatus.Cancelled)
          .toList();
      if (pendingOrders.isEmpty) {
        return const Center(
          child: Text(
            'You have no pending orders.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        itemCount: pendingOrders.length,
        itemBuilder: (context, index) {
          final order = pendingOrders[index];
          // --- NEW: Wrap ListTile with a StreamBuilder for real-time status updates ---
          return StreamBuilder<StructuredOrder?>(
            stream: sl<OrderService>().getOrderStream(order.orderId),
            builder: (context, snapshot) {
              final currentOrder = snapshot.data ?? order;
              return Card( // This now uses CardTheme from the theme file
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                child: ListTile( // This now uses CardTheme from the theme file
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: const Icon(Icons.receipt, color: Colors.teal),
                  ),
                  title: Text(
                    'Order #${currentOrder.orderId.substring(0, 6)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: ${currentOrder.status.name}', // This will now update in real-time
                  ),
                  trailing: Text(
                    '${currentOrder.estimatedTotal + currentOrder.deliveryFee} EGP',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showPendingOrderDetails(context, currentOrder),
                ),
              );
            },
          );
        },
      );
    });
  }
}


// --- WIDGET FOR TAB 3: Order History ---
class OrderHistoryTab extends StatelessWidget {
  const OrderHistoryTab({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final historyOrders = state.orders 
            .where((o) => o.status == OrderStatus.Delivered || o.status == OrderStatus.Cancelled)
            .toList();
        if (state.isLoading && historyOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (historyOrders.isEmpty) {
          return Center(
            child: Text(
              context.l10n.noHistory,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: historyOrders.length,
          itemBuilder: (context, index) {
            final order = historyOrders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
                  child: Icon(_getStatusIcon(order.status),
                      color: _getStatusColor(order.status)),
                ),
                title: Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Status: ${order.status.name}'),
                trailing: Text(
                  '${order.grandTotal.toStringAsFixed(2)} EGP',
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

  Color _getStatusColor(OrderStatus status) {
    return status == OrderStatus.Delivered
        ? Colors.green
        : (status == OrderStatus.Cancelled ? Colors.red : Colors.orange);
  }

  IconData _getStatusIcon(OrderStatus status) {
    return status == OrderStatus.Delivered
        ? Icons.check_circle
        : (status == OrderStatus.Cancelled ? Icons.cancel : Icons.pending);
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
                  child: ListTile(
                    leading: const Icon(Icons.local_mall, color: Colors.green),
                    title: Text(store, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(strings!.fastestDeliveryZone),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to the store's inventory browsing screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                //strings.translate('Navigating to $store inventory...', 'الانتقال إلى مخزون $store...')
                                "Navigating to $store inventory...")),
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
