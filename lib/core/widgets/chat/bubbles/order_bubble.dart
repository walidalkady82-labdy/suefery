

import 'package:flutter/material.dart';

import '../models/chat_item.dart';

class OrderBubble extends StatelessWidget {
  const OrderBubble({super.key, required this.item});
  
  final OrderSummeryItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey[100], // Or your theme's color
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Confirmed: #${item.orderNumber}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 16),
            Text(item.itemsSummary),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: \$${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}