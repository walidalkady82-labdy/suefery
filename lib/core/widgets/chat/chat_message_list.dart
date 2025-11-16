import 'package:flutter/material.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/core/widgets/chat/models/chat_item.dart';
import 'package:suefery/core/widgets/chat/models/chat_view_io.dart';
import '../../../data/enums/auth_form_type.dart';
import 'bubbles/bubbles.dart';
import 'bubbles/video_presentation_bubble.dart';


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
    final strings = context.l10n;
    
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
          

          VideoPresentationItem() => VideoPlayerBubble(
              title: item.title,
              videoUrl: item.videoUrl,
              onVideoEnd: item.onVideoEnd,
            ),
          LoadingChatItem() => const LoadingBubble(),
          
          // Fallback for any unhandled types
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}