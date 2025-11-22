import 'package:flutter/material.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

import '../../../../data/enums/message_sender.dart';
import '../../../../data/models/ai_parsed_order.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

/// A "dumb" bubble widget that displays a pending order confirmation.
///
/// It allows the user to modify item quantities and confirm or cancel
/// the order via the callbacks provided in [PendingOrderChatItem].
class PendingOrderBubble extends StatefulWidget {
  final PendingOrderChatItem item;

  const PendingOrderBubble({
    super.key,
    required this.item,
  });

  @override
  State<PendingOrderBubble> createState() => _PendingOrderBubbleState();
}

class _PendingOrderBubbleState extends State<PendingOrderBubble> {
  bool _isConfirming = false;

  void _handleConfirm(BuildContext context) async {
    setState(() => _isConfirming = true);
    // The cubit callback will handle payment & async work
    await widget.item.onConfirm(context);
    if (mounted) {
      // The cubit will update the message, but we stop loading
      // in case of a payment failure.
      setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final order = widget.item.parsedOrder;
    final bubbleTextColor = theme.colorScheme.onSecondaryContainer;

    // Build the content for the bubble
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. AI's introductory text
        if (order.aiResponseText != null && order.aiResponseText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(order.aiResponseText!),
          ),

        // 2. List of items
        ..._buildItemList(order.requestedItems, bubbleTextColor),

        // 3. Separator
        Divider(
          height: 20,
          color: bubbleTextColor.withOpacity(0.5),
        ),

        // 4. Action Buttons (or Status)
        if (widget.item.isActioned)
          // Show status if already actioned
          Text(
            widget.item.actionStatus ?? 'Actioned',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: bubbleTextColor, fontWeight: FontWeight.bold),
          )
        else if (_isConfirming)
          // Show loading indicator
          const Center(child: CircularProgressIndicator())
        else
          // Show confirm/cancel buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => widget.item.onCancel(context),
                style: TextButton.styleFrom(foregroundColor: bubbleTextColor),
                child: Text(strings.cancelOrder),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _handleConfirm(context),
                // Style button to pop
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSecondary,
                  foregroundColor: theme.colorScheme.secondary,
                ),
                child: Text(strings.cancelOrder.replaceAll('Cancel', 'Confirm')),
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

  // Helper to build the list of items with quantity steppers
  List<Widget> _buildItemList(List<AiParsedItem> items, Color iconColor) {
    return List.generate(items.length, (index) {
      final item = items[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // Item name
            Expanded(
              child: Text(
                item.itemName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Quantity Stepper
            if (!widget.item.isActioned) // Only show if not actioned
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: iconColor,
                    iconSize: 20,
                    onPressed: item.quantity > 1
                        ? () => widget.item.onUpdateQuantity(index, -1)
                        : null,
                  ),
                  Text(item.quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: iconColor,
                    iconSize: 20,
                    onPressed: () => widget.item.onUpdateQuantity(index, 1),
                  ),
                ],
              ),
            if (widget.item.isActioned) // Show final quantity if actioned
              Text(
                'Qty: ${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      );
    });
  }
}