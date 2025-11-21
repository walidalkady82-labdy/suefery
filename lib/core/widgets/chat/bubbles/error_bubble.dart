import 'package:flutter/material.dart';
import 'package:suefery/core/widgets/chat/bubbles/bubble_layout.dart';

import '../models/chat_item.dart';

class ErrorBubble extends StatelessWidget {
  final ErrorItem item;

  const ErrorBubble({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return BubbleLayout(
      sender: item.sender,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(item.text)),
        ],
      ),
    );
  }
}