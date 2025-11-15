import 'package:flutter/material.dart';

import '../models/chat_item.dart';

class RecipeBubble extends StatelessWidget {
  const RecipeBubble({super.key, required this.item});
  final RecipeSuggestionItem item;

  @override
  Widget build(BuildContext context) {
    // A custom widget for showing a recipe
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Image.network(item.imageUrl), // 

// [Image of a recipe]

            const SizedBox(height: 8),
            Text(item.description),
          ],
        ),
      ),
    );
  }
}
