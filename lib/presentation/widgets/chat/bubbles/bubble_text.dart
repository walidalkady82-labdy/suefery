import 'package:flutter/material.dart';
import '../models/chat_item.dart';
import 'bubble_layout.dart';

class BubbleText extends StatelessWidget {
  final TextChatItem item;

  const BubbleText({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return BubbleLayout(
      sender: item.sender,
      child: Text(item.text),
    );
  }
}