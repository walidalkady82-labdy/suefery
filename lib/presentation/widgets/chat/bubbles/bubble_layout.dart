
import 'package:flutter/material.dart';
import 'package:suefery/data/enum/message_sender.dart';

/// A reusable widget that provides the common layout and styling for a chat bubble.
///
/// It handles alignment (left/right), background color, and rounded corners
/// based on the [sender].
class BubbleLayout extends StatelessWidget {
  /// The sender of the message, used to determine alignment and color.
  final MessageSender sender;

  /// The content to display inside the bubble.
  final Widget child;

  const BubbleLayout({
    super.key,
    required this.sender,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = sender == MessageSender.user;

    return Align(
      // Align bubbles to the left or right based on the sender
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Set a max width so bubbles don't span the entire screen
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          // Use different colors for user and AI
          // color: isUser
          //     ? theme.colorScheme.primaryContainer
          //     : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isUser
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.secondaryContainer,
          )
        ),
        child: child,
      ),
    );
  }
}