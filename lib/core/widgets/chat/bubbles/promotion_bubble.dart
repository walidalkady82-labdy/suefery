import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import '../../../../data/enums/message_sender.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

class PromotionBubble extends StatelessWidget {
  const PromotionBubble({super.key, required this.item});

  final PromotionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the bubble's default text color
    final bubbleTextColor = DefaultTextStyle.of(context).style.color;

    return BubbleLayout(
      sender: MessageSender.gemini,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  item.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),
            ),
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: bubbleTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.description),
          const SizedBox(height: 12),
          // Promo code section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              // Use a slightly lighter/darker shade for contrast
              color: theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CODE: ${item.promoCode}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: bubbleTextColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: bubbleTextColor),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.promoCode));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Promo code copied!')),
                      );
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}