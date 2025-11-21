import 'package:flutter/material.dart';

import '../../../../data/enums/message_sender.dart';
import '../../../../data/models/ai_parsed_order.dart';

@immutable
abstract class ChatItem {
  const ChatItem();
}

@immutable
class LoadingChatItem extends ChatItem {
  const LoadingChatItem();
}

@immutable
class TextChatItem extends ChatItem {
  const TextChatItem({
    required this.id,
    required this.text,
    required this.sender,
  });
  final String id;
  final String text;
  final MessageSender sender;
}

@immutable
class SignInFormItem extends ChatItem {
  const SignInFormItem();
}

@immutable
class RegisterFormItem extends ChatItem {
  const RegisterFormItem();
}

@immutable
class PendingOrderChatItem extends ChatItem {
  const PendingOrderChatItem({
    required this.messageId,
    required this.parsedOrder,
    required this.isActioned,
    this.actionStatus,
    required this.onConfirm,
    required this.onSubmitDraft,
    required this.onCancel,
    required this.onUpdateQuantity,
  });

  final String messageId;
  final AiParsedOrder parsedOrder;
  final bool isActioned;
  final String? actionStatus;

  // Callbacks for the bubble's buttons
  final Future<bool?> Function(BuildContext context) onConfirm;
  final VoidCallback onSubmitDraft;
  final VoidCallback onCancel;
  final Function(int itemIndex, int change) onUpdateQuantity;
}

@immutable
class OrderSummeryItem extends ChatItem {
  const OrderSummeryItem({
    required this.id,
    required this.orderNumber,
    required this.itemsSummary, // e.g., "2x Burger, 1x Fries"
    required this.totalPrice,
  });
  
  final String id;
  final String orderNumber;
  final String itemsSummary;
  final double totalPrice;
}

@immutable
class RecipeSuggestionItem extends ChatItem {
  const RecipeSuggestionItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
  });
  final String id;
  final String title;
  final String imageUrl;
  final String description;
}

@immutable
class PromotionItem extends ChatItem {
  const PromotionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.promoCode,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final String promoCode;
  final String? imageUrl;
}

@immutable
class VideoPresentationItem extends ChatItem {
  final String id;
  final String title;
  final String videoUrl;
  final VoidCallback? onVideoEnd;

  const VideoPresentationItem({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.onVideoEnd,
  }); 
}

@immutable
class AuthChoiceItem extends ChatItem {
  final String id;
  final String text;
  final List<String> choices;
  final ValueChanged<String> onChoiceSelected;
  final MessageSender sender; // <-- ADDED THIS

  const AuthChoiceItem({
    required this.id,
    required this.text,
    required this.choices,
    required this.onChoiceSelected,
    this.sender = MessageSender.gemini, // <-- ADDED THIS
  });
}

@immutable
class VerificationPromptItem extends ChatItem {
  final String id;
  final String text;
  final List<String> choices;
  final Function(String) onChoiceSelected;
  final MessageSender sender;

  const VerificationPromptItem({
    required this.id,
    required this.text,
    this.choices = const [],
    required this.onChoiceSelected,
    required this.sender,
  });
}
@immutable
class ErrorItem extends ChatItem {
  final MessageSender sender;
  final String id;
  final String text;
  const ErrorItem({
    required this.id,
    required this.text,
    required this.sender,
  });
}