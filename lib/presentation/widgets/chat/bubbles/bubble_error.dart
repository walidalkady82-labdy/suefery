import 'package:flutter/material.dart';
import 'package:suefery/presentation/widgets/chat/bubbles/bubble_layout.dart';

import '../models/chat_item.dart';

class BubbleError extends StatelessWidget {
  final ErrorItem item;

  const BubbleError({
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