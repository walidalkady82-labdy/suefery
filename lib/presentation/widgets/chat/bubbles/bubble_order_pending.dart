import 'package:flutter/material.dart';
import 'package:suefery/core/extensions/is_not_null_or_empty.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/enum/order_item_status.dart'; // Import OrderItemStatus
import 'package:suefery/data/enum/order_status.dart';
import 'package:suefery/data/model/model_order.dart'; // Import ModelOrder

import '../../../../data/enum/message_sender.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

/// A "dumb" bubble widget that displays a pending order confirmation.
///
/// It allows the user to modify item quantities and confirm or cancel
/// the order via the callbacks provided in [PendingOrderChatItem].
class BubbleOrderPending extends StatefulWidget {
  final PendingOrderChatItem item;

  const BubbleOrderPending({
    super.key,
    required this.item,
  });

  @override
  State<BubbleOrderPending> createState() => _BubbleOrderPendingState();
}

class _BubbleOrderPendingState extends State<BubbleOrderPending> {
  bool _isConfirming = false;
  bool _termsAccepted = false;

  void _handleConfirm(BuildContext context) async {
    setState(() => _isConfirming = true);
    // The cubit callback will handle payment & async work
    await widget.item.onConfirm();
    if (mounted) {
      // The cubit will update the message, but we stop loading
      // in case of a payment failure.
      setState(() => _isConfirming = false);
    }
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.pendingOrderTermsTitle),
          content: SingleChildScrollView(
            child: Text(context.l10n.pendingOrderTermsBody),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.close))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final order = widget.item.parsedOrder;
    final bubbleTextColor = theme.colorScheme.onSecondaryContainer;
    final realOrder = widget.item.order; // The real-time order data

    // Determine which item list to use
    final itemsToDisplay = realOrder?.items ?? order.requestedItems.map((e) => ModelOrderItem(id: '', description: e.itemName, brand: e.brand ?? '', quantity: e.quantity, unit: e.unit ?? '', unitPrice: e.unitPrice )).toList();


    // Build the content for the bubble
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. AI's introductory text
        if (order.aiResponseText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(order.aiResponseText),
          ),

        // 2. Order Progress (if realOrder is available)
        if (realOrder != null && realOrder.status != OrderStatus.draft && realOrder.status != OrderStatus.quoteReceived) ...[
          _buildStepper(context, realOrder, bubbleTextColor),
          const SizedBox(height: 12),
        ],

        // 3. List of items
        ..._buildItemList(itemsToDisplay, bubbleTextColor),

        // 4. Separator
        Divider(
          height: 20,
          color: bubbleTextColor..withAlpha(128),
        ),

        // 5. Action Buttons (or Status)
        if (widget.item.isActioned || (realOrder != null && realOrder.status != OrderStatus.draft && realOrder.status != OrderStatus.quoteReceived))
          // Show status if already actioned or realOrder exists and is not draft
          Text(
            widget.item.actionStatus ?? realOrder?.status.name.capitalizeFirstLetter() ?? 'Actioned',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: bubbleTextColor, fontWeight: FontWeight.bold),
          )
        else if (_isConfirming)
          // Show loading indicator
          const Center(child: CircularProgressIndicator())
        else
          // Show T&C and confirm/cancel buttons
          Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (bool? value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _showTermsAndConditions(context),
                      child: Text(
                        strings.pendingOrderTermsTitle,
                        style: TextStyle(decoration: TextDecoration.underline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => widget.item.onCancel(),
                    style: TextButton.styleFrom(foregroundColor: bubbleTextColor),
                    child: Text(strings.cancelOrder),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _termsAccepted ? () => _handleConfirm(context) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.onSecondary,
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                    child: Text(strings.confirmAndPay),
                  ),
                ],
              ),
            ],
          ),
      ],
    );

    // Return the content wrapped in the layout
    return BubbleLayout(
      sender: MessageSender.gemini, // This bubble is always from the AI
      child: content,
    );
  }

  Widget _buildStepper(BuildContext context, ModelOrder order, Color textColor) {
    final theme = Theme.of(context);
    final orderStatus = order.status;

    // Define the steps for the stepper based on OrderStatus
    final steps = [
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.assigned,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    int currentStep = steps.indexOf(orderStatus);
    if (currentStep == -1) {
      if (orderStatus == OrderStatus.cancelled) {
        // Handle cancelled case if needed, maybe show a specific message
        return const SizedBox.shrink();
      }
      currentStep = 0; // Default to the first step if status is not in the list
    }

    return Stepper(
      currentStep: currentStep,
      controlsBuilder: (context, details) => const SizedBox.shrink(), // Hide controls
      steps: steps.map((status) {
        return Step(
          title: Text(
            status.name.capitalizeFirstLetter(),
            style: theme.textTheme.bodySmall?.copyWith(color: textColor),
          ),
          content: const SizedBox.shrink(),
          isActive: steps.indexOf(status) <= currentStep,
          state: steps.indexOf(status) < currentStep ? StepState.complete : StepState.indexed,
        );
      }).toList(),
      physics: const ClampingScrollPhysics(),
    );
  }
  // Helper to build the list of items with quantity steppers and status/feedback
  List<Widget> _buildItemList(List<ModelOrderItem> items, Color iconColor) {
    final strings = context.l10n;
    return List.generate(items.length, (index) {
      final item = items[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          children: [
            Row(
              children: [
                // Item name
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Quantity Stepper (only if not actioned AND no realOrder or realOrder status is draft)
                if (!widget.item.isActioned && (widget.item.order == null || widget.item.order?.status == OrderStatus.draft))
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: iconColor,
                        iconSize: 20,
                        onPressed: item.quantity > 1
                            ? () async {
                                await widget.item.onUpdateQuantity(index, -1);
                                if (mounted) setState(() {});
                              }
                            : null,
                      ),
                      Text(
                        '${item.quantity}${item.unit.isNotNullOrEmpty ? ' ${item.unit}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: iconColor,
                        iconSize: 20,
                        onPressed: () async {
                          await widget.item.onUpdateQuantity(index, 1);
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                if (widget.item.isActioned || (widget.item.order != null && widget.item.order?.status != OrderStatus.draft)) // Show final quantity if actioned or realOrder is not draft
                  Text(
                    strings.quantityLabel(item.quantity.toInt()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            // Item Status and Partner Notes
            if (widget.item.order != null && item.itemStatus != OrderItemStatus.available)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(
                      item.itemStatus == OrderItemStatus.unavailable
                          ? Icons.cancel
                          : Icons.find_replace,
                      color: item.itemStatus == OrderItemStatus.unavailable
                          ? Colors.red
                          : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.itemStatus.name.capitalizeFirstLetter()}${item.partnerNotes.isNotNullOrEmpty ? ': ${item.partnerNotes}' : ''}',
                      style: TextStyle(
                        color: item.itemStatus == OrderItemStatus.unavailable
                            ? Colors.red
                            : Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}