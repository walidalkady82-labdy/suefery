import 'package:flutter/material.dart';

import '../localizations/app_localizations.txt';

class OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String locale;

  const OrderHistoryCard({super.key, required this.order, required this.locale});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${s.orderId}: ${order['id']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  order['time'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: 12, thickness: 1),
            // Total
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.orderTotal,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'EGP ${order['total']}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Status
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.orderStatus,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A3A3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order['status'] as String,
                      style: const TextStyle(
                        color: Color(0xFF00A3A3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Summary Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Action to view detailed order summary
                },
                child: Text(
                  s.orderSummary,
                  style: const TextStyle(color: Color(0xFF00A3A3)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}