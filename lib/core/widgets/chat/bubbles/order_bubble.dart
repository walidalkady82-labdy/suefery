

import 'package:flutter/material.dart';

import '../../../../data/enums/message_sender.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

class OrderBubble extends StatelessWidget {
  final OrderSummeryItem item;

  const OrderBubble({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BubbleLayout(
      // This could be from MessageSender.system or .gemini
      sender: MessageSender.gemini,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Confirmed: #${item.orderNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              // Use the bubble's default text color
              color: DefaultTextStyle.of(context).style.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.itemsSummary),
          const SizedBox(height: 8),
          Text(
            'Total: EGP ${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}