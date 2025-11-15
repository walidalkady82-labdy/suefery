import 'package:flutter/material.dart';
import 'package:suefery/data/enums/message_sender.dart';

import '../models/chat_item.dart';

class TextBubble extends StatelessWidget {
  const TextBubble({super.key, required this.item});
  final TextChatItem item;

  @override
  Widget build(BuildContext context) {
    // A simple text bubble implementation
    return Align(
      alignment: item.sender == MessageSender.user ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: item.sender == MessageSender.user
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(item.text),
        ),
      ),
    );
  }
}