import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/core/widgets/chat/bubbles/bubble_layout.dart';
import 'package:suefery/core/widgets/chat/models/chat_item.dart';
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/models/ai_parsed_order.dart';

/// A chat bubble that represents a pending order proposal.
/// It manages the UI state from draft, to quote, to confirmation.
class PendingOrderBubble extends StatelessWidget {
  final PendingOrderChatItem item;

  const PendingOrderBubble({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);

    // Determine the total price. Only available when a quote is ready.
    final bool hasPrice =
        false;
        item.parsedOrder.requestedItems.any((item) => item.unitPrice > 0);
    final double subtotal = item.parsedOrder.requestedItems.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );

    return BubbleLayout(
      sender: MessageSender.gemini,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.parsedOrder.aiResponseText,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          // Item List
          for (var i = 0; i < item.parsedOrder.requestedItems.length; i++)
            _ItemRow(
              item: item.parsedOrder.requestedItems[i],
              itemIndex: i,
              onUpdateQuantity: item.onUpdateQuantity,
              // Quantity can be updated only in the initial draft stage (before being actioned).
              canUpdateQuantity: !item.isActioned && !hasPrice,
              isQuoteReady: hasPrice,
            ),
          const Divider(height: 24),
          if (hasPrice)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(strings.total, style: theme.textTheme.titleMedium),
                  Text(
                    NumberFormat.currency(symbol: 'EGP ').format(subtotal),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// Builds the correct button(s) or status text based on the `actionStatus`.
  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;

    // If the order is actioned AND not a ready quote, show a status chip.
    // A 'QuoteReady' status means we should show the confirmation buttons again.
    if (item.isActioned && item.actionStatus != 'QuoteReady') {
      switch (item.actionStatus) {
        case 'AwaitingQuote':
          return const Center(child: Text("⏳ Waiting for partner quote..."));
        case 'Paid':
          return Center(
              child: Chip(
                  label: Text("✅ ${strings.orderTextButton} Confirmed"),
                  backgroundColor: Colors.green.shade100));
        case 'Cancelled':
          return Center(
              child: Chip(
                  label: Text("❌ ${strings.orderTextButton} Cancelled"),
                  backgroundColor: Colors.red.shade100));
        default:
          return Center(child: Chip(label: Text("✅ ${item.actionStatus}")));
      }
    }

    // If a quote is ready (indicated by having prices), show Confirm & Pay.
    final bool hasPrice =
        item.parsedOrder.requestedItems.any((item) => item.unitPrice > 0) ||
        item.actionStatus == 'QuoteReady';
    if (hasPrice) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: item.onCancel,
              child: Text(strings.cancelOrder), // You may need to add this string
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              onPressed: () => item.onConfirm(context),
              child:
                  Text(strings.confirmAndPay), // You may need to add this string
            ),
          ),
        ],
      );
    }

    // The initial state: a draft ready to be submitted for a quote.
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: item.onSubmitDraft,
        child: Text("Submit for Quote"), // You may need to add this string
      ),
    );
  }
}

/// A private helper widget to display a single item in the order list.
class _ItemRow extends StatelessWidget {
  final AiParsedItem item;
  final int itemIndex;
  final void Function(int, int) onUpdateQuantity;
  final bool canUpdateQuantity;
  final bool isQuoteReady;

  const _ItemRow({
    required this.item,
    required this.itemIndex,
    required this.onUpdateQuantity,
    required this.canUpdateQuantity,
    required this.isQuoteReady,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text('${item.quantity} x ${item.itemName}'),
          ),
          if (isQuoteReady)
            Text(NumberFormat.currency(symbol: 'EGP ')
                .format(item.unitPrice * item.quantity)),
          if (canUpdateQuantity) // Only show quantity controls on a draft order
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => onUpdateQuantity(itemIndex, -1)),
                IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => onUpdateQuantity(itemIndex, 1)),
              ],
            ),
        ],
      ),
    );
  }
}