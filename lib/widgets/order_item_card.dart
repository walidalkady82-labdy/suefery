import 'package:flutter/material.dart';

class OrderItemCard extends StatelessWidget {
  final String itemName;
  final int quantity;
  final String? notes;

  const OrderItemCard({
    super.key,
    required this.itemName,
    required this.quantity,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity Badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade300, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${quantity}x',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Item Name and Notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (notes != null && notes!.isNotEmpty)
                  Text(
                    'Note: $notes',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}