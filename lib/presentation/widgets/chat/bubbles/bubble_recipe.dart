import 'package:flutter/material.dart';

import '../../../../data/enum/message_sender.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

class BubbleRecipe extends StatelessWidget {
  final RecipeSuggestionItem item;

  const BubbleRecipe({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return BubbleLayout(
      sender: MessageSender.gemini, // This bubble is always from the AI
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Placeholder Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              item.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              // Error builder in case the image fails to load
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
          const SizedBox(height: 12),

          // 2. Title
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DefaultTextStyle.of(context).style.color,
                ),
          ),
          const SizedBox(height: 8),

          // 3. Description / Ingredients
          Text(item.description),
        ],
      ),
    );
  }
}