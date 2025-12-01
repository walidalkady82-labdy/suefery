import 'package:flutter/material.dart';
import 'package:suefery/core/extensions/is_not_null_or_empty.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/data/model/model_order.dart'; // Import ModelOrderItem
import 'package:suefery/presentation/widgets/chat/dialogs/edit_order_item_dialog.dart'; // Import EditOrderItemDialog

import '../../../../data/enum/message_sender.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

class BubbleDraftOrder extends StatefulWidget {
  final DraftOrderItem item;

  const BubbleDraftOrder({
    super.key,
    required this.item,
  });

  @override
  State<BubbleDraftOrder> createState() => _BubbleDraftOrderState();
}

class _BubbleDraftOrderState extends State<BubbleDraftOrder> {
  
  bool _isConfirming = false;

  void _handleConfirm(BuildContext context) async {
    setState(() => _isConfirming = true);
    await widget.item.onConfirm();
    if (mounted) {
      setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final parsedOrder = widget.item.parsedOrder;
    // Use the real order items if available, otherwise fallback to parsed items
    final List<ModelOrderItem> orderItems = widget.item.order?.items ?? parsedOrder.requestedItems.map((e) => ModelOrderItem(
      id: '', // ID will be generated when order is confirmed
      description: e.itemName,
      brand: e.brand ?? '',
      quantity: e.quantity,
      unit: e.unit ?? '',
      unitPrice: e.unitPrice,
      notes: e.notes,
    )).toList();

    final bubbleTextColor = theme.colorScheme.onSecondaryContainer;

    // Build the content for the bubble
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. AI's introductory text
        if (parsedOrder.aiResponseText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(parsedOrder.aiResponseText),
          ),

        // 2. List of items
        ..._buildItemList(orderItems, bubbleTextColor),
        
        // Add new Item button
        TextButton.icon(
          onPressed: () {
            widget.item.onAddItem(
              ModelOrderItem(
                id: '',
                description: strings.itemName, // Empty description for new item
                brand: strings.brand,
                quantity: 1, 
                unit: '',
                unitPrice: 0.0,
              ));
          },
          icon: const Icon(Icons.add),
          label: Text(strings.add),
        ),

        // 3. Separator
        Divider(
          height: 20,
          color: bubbleTextColor.withAlpha(128),
        ),

        // 4. Action Buttons (or Status)
        if (_isConfirming)
          // Show loading indicator
          const Center(child: CircularProgressIndicator())
        else
          // Show confirm/cancel buttons
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
                onPressed: () => _handleConfirm(context),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSecondary,
                  foregroundColor: theme.colorScheme.secondary,
                ),
                child: Text(strings.confirm),
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

  // Helper to build the list of items with quantity steppers and edit buttons
  List<Widget> _buildItemList(List<ModelOrderItem> items, Color iconColor) {
    return List.generate(items.length, (index) {
      final item = items[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // Item name
            Expanded(
              child: Column(
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(children: [
                    Text(
                    item.brand,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ],)
                ],
              ),
            ),
            // Quantity Stepper
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
                // Edit Item button
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: iconColor,
                  iconSize: 20,
                  onPressed: () async {
                    final updatedItem = await showDialog<ModelOrderItem>(
                      context: context,
                      builder: (context) => EditOrderItemDialog(item: item),
                    );
                    if (updatedItem != null) {
                      await widget.item.onUpdateItem(index, updatedItem);
                      if (mounted) setState(() {});
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
