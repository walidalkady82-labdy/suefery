import 'package:flutter/material.dart';

import '../../../../data/models/ai_parsed_order.dart';
import '../models/chat_item.dart';

/// A "dumb" bubble widget that displays a pending order confirmation.
///
/// It allows the user to modify item quantities and confirm or cancel
/// the order via the callbacks provided in [PendingOrderChatItem].
class PendingOrderBubble extends StatelessWidget {
  const PendingOrderBubble({super.key, required this.item});

  final PendingOrderChatItem item;

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final double subtotal = item.parsedOrder.requestedItems.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    // TODO: Get fee from a config/service, not hardcoded
    const double deliveryFee = 10.0; 
    final double grandTotal = subtotal + deliveryFee;

    return Card(
      elevation: 2.0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Confirmation",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 16),

            // --- List of Items ---
            ...item.parsedOrder.requestedItems.asMap().entries.map((entry) {
              int index = entry.key;
              AiParsedItem orderItem = entry.value;
              return _buildItemRow(
                context,
                orderItem,
                index,
                !item.isActioned, // Enabled if not actioned
              );
            }),

            const Divider(height: 16),

            // --- Totals ---
            _buildTotalRow("Subtotal", subtotal),
            _buildTotalRow("Delivery Fee", deliveryFee),
            _buildTotalRow("Grand Total", grandTotal, isBold: true),

            const SizedBox(height: 16),

            // --- Action Buttons ---
            if (item.isActioned)
              _buildActionedChip(context)
            else
              _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Builds a single row for an item in the order list.
  Widget _buildItemRow(
    BuildContext context,
    AiParsedItem orderItem,
    int index,
    bool isEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // --- Quantity Controls ---
          SizedBox(
            width: 90, // Fixed width for controls
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton.filledTonal(
                    iconSize: 14,
                    icon: const Icon(Icons.remove),
                    onPressed: isEnabled
                        ? () => item.onUpdateQuantity(index, -1)
                        : null,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${orderItem.quantity}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: IconButton.filledTonal(
                    iconSize: 14,
                    icon: const Icon(Icons.add),
                    onPressed: isEnabled
                        ? () => item.onUpdateQuantity(index, 1)
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // --- Item Name & Notes ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderItem.itemName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (orderItem.notes != null && orderItem.notes!.isNotEmpty)
                  Text(
                    orderItem.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // --- Line Item Total ---
          Text(
            "EGP ${(orderItem.quantity * orderItem.unitPrice).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Builds a row for displaying a total (e.g., "Subtotal", "EGP 150.00")
  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "EGP ${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the "Cancel" and "Confirm" buttons.
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: item.onCancel,
            child: const Text("Cancel"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            child: const Text("Confirm & Pay"),
            onPressed: () => item.onConfirm(context),
          ),
        ),
      ],
    );
  }

  /// Builds the "chip" that shows the final status (e.g., "Confirmed").
  Widget _buildActionedChip(BuildContext context) {
    final bool isCancelled =
        item.actionStatus?.toLowerCase() == 'cancelled';
    return Center(
      child: Chip(
        label: Text(
          item.actionStatus ?? "Actioned",
          style: TextStyle(
            color: isCancelled
                ? Theme.of(context).colorScheme.onError
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        backgroundColor: isCancelled
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
  }
}