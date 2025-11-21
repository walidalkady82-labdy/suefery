import 'package:flutter/material.dart';
import 'package:suefery/core/widgets/chat/models/chat_item.dart';
import 'package:suefery/core/widgets/chat/models/chat_view_io.dart';
import 'bubbles/bubbles.dart';
import 'bubbles/error_bubble.dart';
import 'bubbles/verification_prompt_bubble.dart';


class ChatMessageList extends StatelessWidget {
  const ChatMessageList({
    super.key,
    required this.scrollController,
    required this.chatItems,
    required this.callbacks,
  });

  final ScrollController scrollController;
  final List<ChatItem> chatItems;
  final ChatViewCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: chatItems.length,
      itemBuilder: (context, index) {
        final item = chatItems[index];
        // --- Use a switch expression for type matching ---
        return switch (item) {
          
          TextChatItem() => TextBubble(item: item),
          
          RecipeSuggestionItem() => RecipeBubble(item: item),
          
          PromotionItem() => PromotionBubble(item: item),

          OrderSummeryItem() => OrderBubble(item: item),
          
          AuthChoiceItem() => AuthChoiceBubble(item: item),
          
          ErrorItem() => ErrorBubble(item: item),
          
          VerificationPromptItem() => VerificationPromptBubble(item: item),  

          LoadingChatItem() => const LoadingBubble(),
          
          // Fallback for any unhandled types
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}