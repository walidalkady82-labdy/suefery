import 'package:flutter/material.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_item.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_view_io.dart';
import 'bubbles/bubbles.dart';



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
        return switch (item) {
          
          TextChatItem() => BubbleText(item: item),
          
          RecipeSuggestionItem() => BubbleRecipe(item: item),
          
          PromotionItem() => BubblePromotion(item: item),

          PendingOrderChatItem() => BubbleOrderPending(item: item),
          
          DraftOrderItem() => BubbleDraftOrder(item: item),

          PaymentSelectionItem() => BubblePaymentSelection(item: item),

          LoadingChatItem() => const BubbleLoading(),
          
          ErrorItem() => BubbleError(item: item),
          
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}