import 'package:flutter/material.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_item.dart';
import 'package:suefery/presentation/widgets/chat/bubbles/bubble_layout.dart';

class BubblePaymentSelection extends StatelessWidget {
  final PaymentSelectionItem item;

  const BubblePaymentSelection({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BubbleLayout(
      sender: item.sender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header
          Row(
            children: [
              Icon(Icons.payment, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Complete Payment",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 2. Total Amount Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor..withAlpha(128),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total to Pay:", style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  "${item.totalAmount.toStringAsFixed(2)} ${item.currency}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Payment Options
          const Text("Choose a method:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),

          _PaymentOptionTile(
            icon: Icons.money,
            title: "Cash on Delivery",
            subtitle: "Pay when you receive the order",
            onTap: () => item.onPaymentMethodSelected('COD'),
            theme: theme,
          ),
          const SizedBox(height: 8),
          _PaymentOptionTile(
            icon: Icons.credit_card,
            title: "Pay with Card",
            subtitle: "Secure online payment",
            onTap: () => item.onPaymentMethodSelected('CARD'),
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.scaffoldBackgroundColor,
              child: Icon(icon, color: theme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}