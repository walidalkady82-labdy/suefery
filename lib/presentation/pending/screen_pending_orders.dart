import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

import '../../data/model/model_order.dart';
import '../../data/enum/order_status.dart'; // Import OrderStatus
import '../home/cubit_order.dart'; // Import CubitOrder
import 'cubit_pending_orders.dart';
import 'package:suefery/core/l10n/app_localizations.dart';

class ScreenPendingOrders extends StatelessWidget {
  final String? initialOrderId;
  const ScreenPendingOrders({super.key, this.initialOrderId});

  static void showOrderModal(BuildContext context, ModelOrder order) {
    // Access CubitOrder from the context
    final CubitOrder cubitOrder = context.read<CubitOrder>();
    final TextEditingController descriptionController =
        TextEditingController(text: order.description);
    final strings = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text('Order ID: ${order.id}'),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description', // Using a hardcoded string as it was missing from l10n
                      ),
                      readOnly: order.status != OrderStatus.draft,
                    ),
                    Text('Total: \$${order.estimatedTotal.toStringAsFixed(2)}'),
                    Text('Status: ${order.status.name}'),
                    const SizedBox(height: 16),
                    Text('Items:', style: Theme.of(context).textTheme.titleMedium),
                    Expanded(
                      child: ListView.builder(
                        itemCount: order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return ListTile(
                            title: Text(item.description),
                            subtitle: Text('${item.quantity} ${item.unit} x \$${item.unitPrice}'),
                            trailing: order.status == OrderStatus.draft
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: () {
                                          // Decrement quantity logic
                                          cubitOrder.updateOrderItemQuantity(
                                            order.id,
                                            item.id,
                                            item.quantity - 1,
                                          );
                                        },
                                      ),
                                      Text(item.quantity.toString()),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        onPressed: () {
                                          // Increment quantity logic
                                          cubitOrder.updateOrderItemQuantity(
                                            order.id,
                                            item.id,
                                            item.quantity + 1,
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          // Delete item logic
                                          cubitOrder.removeOrderItem(order.id, item.id);
                                        },
                                      ),
                                    ],
                                  )
                                : null, // No actions for non-draft items
                          );
                        },
                      ),
                    ),
                    if (order.status == OrderStatus.draft) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text(strings.save),
                            onPressed: () {
                              final updatedOrder = order.copyWith(
                                description: descriptionController.text,
                              );
                              cubitOrder.updateOrder(updatedOrder);
                              Navigator.pop(context); // Close modal
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: Text(strings.delete),
                            onPressed: () {
                              Navigator.pop(context); // Close modal
                              _confirmAndDeleteOrder(context, cubitOrder, order, strings);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal
                        },
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      descriptionController.dispose();
    });
  }

  static Future<void> _confirmAndDeleteOrder(
      BuildContext context, CubitOrder cubitOrder, ModelOrder order, AppLocalizations strings) async {
    
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.deleteConfirmationMessage),
            content: Text(strings.deleteOrderPrompt(order.id)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.delete),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await cubitOrder.deleteOrder(order.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.orderDeletedMessage(order.id))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.pendingOrdersTextButton)),
      body: BlocProvider(
        create: (context) => CubitPendingOrders()..loadOrderPending(),
        child: BlocBuilder<CubitPendingOrders, StatePendingOrders>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
        
            if (state.pendingOrders.isEmpty) {
              return Center(child: Text(strings.noOrders));
            }
        
            return ListView.builder(
              itemCount: state.pendingOrders.length,
              itemBuilder: (context, index) {
                final ModelOrder order = state.pendingOrders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${strings.orderId}: ${order.id}'),
                    subtitle: Text(order.description),
                    trailing: Text('\$${order.estimatedTotal.toStringAsFixed(2)}'),
                    onTap: () => showOrderModal(context, order),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}