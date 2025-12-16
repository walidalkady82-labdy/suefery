import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:suefery/data/model/model_order.dart';

import '../../../../data/enum/message_sender.dart';
import '../../../../data/enum/promotion_type.dart';
import '../../../../data/model/model_ai_parsed_order.dart';

@immutable
abstract class ChatItem extends Equatable{
  const ChatItem();
}

@immutable
class LoadingChatItem extends ChatItem {
  const LoadingChatItem();
  
  @override
  List<Object?> get props => [];
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
  
  @override
  List<Object?> get props => [id, text, sender];
  
}

// @immutable
// class SignInFormItem extends ChatItem {
//   const SignInFormItem();
// }

// @immutable
// class RegisterFormItem extends ChatItem {
//   const RegisterFormItem();
// }

@immutable
class PendingOrderChatItem extends ChatItem {
  const PendingOrderChatItem({
    required this.messageId,
    required this.parsedOrder,
    required this.isActioned,
    this.actionStatus,
    this.order, // New field for real-time order data
    required this.onConfirm,
    required this.onSubmitDraft,
    required this.onCancel,
    required this.onUpdateQuantity,
  });

  final String messageId;
  final ModelAiParsedOrder parsedOrder;
  final bool isActioned;
  final String? actionStatus;
  final ModelOrder? order; // New field

  // Callbacks for the bubble's buttons
  final Future<void> Function() onConfirm;
  final VoidCallback onSubmitDraft;
  final Future<void> Function() onCancel;
  final Future<void> Function(int itemIndex, int change) onUpdateQuantity;
  @override
  List<Object?> get props => [messageId , parsedOrder, isActioned, actionStatus, order, onConfirm, onSubmitDraft, onCancel, onUpdateQuantity];
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
    @override
  List<Object?> get props => [id, orderNumber, itemsSummary, totalPrice];
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
    @override
  List<Object?> get props => [id, title, imageUrl, description];
}

@immutable
class PromotionItem extends ChatItem {
  const PromotionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.promoCode,
    this.imageUrl,
    this.type = PromotionType.customerSpecific, // Default to generic/loyalty
    this.eligibleItems = const [],
  });

  final String id;
  final String title;
  final String description;
  final String promoCode;
  final String? imageUrl;

  /// Determines the visual style (Gold vs Blue)
  final PromotionType type;

  /// If type is [itemSpecific], these are the tags shown (e.g. ["Pepsi", "Chips"])
  final List<String> eligibleItems;
  @override
  List<Object?> get props => [id, title, description, promoCode, imageUrl, type, eligibleItems];
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
  @override
  List<Object?> get props => [id, title, videoUrl, onVideoEnd];

}

// @immutable
// class AuthChoiceItem extends ChatItem {
//   final String id;
//   final String text;
//   final List<String> choices;
//   final ValueChanged<String> onChoiceSelected;
//   final MessageSender sender; // <-- ADDED THIS

//   const AuthChoiceItem({
//     required this.id,
//     required this.text,
//     required this.choices,
//     required this.onChoiceSelected,
//     this.sender = MessageSender.gemini, // <-- ADDED THIS
//   });
// }

// @immutable
// class VerificationPromptItem extends ChatItem {
//   final String id;
//   final String text;
//   final List<String> choices;
//   final Function(String) onChoiceSelected;
//   final MessageSender sender;

//   const VerificationPromptItem({
//     required this.id,
//     required this.text,
//     this.choices = const [],
//     required this.onChoiceSelected,
//     required this.sender,
//   });
// }

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
  @override
  List<Object?> get props => [id, text, sender];
}

@immutable
class PaymentSelectionItem extends ChatItem {
  final String id;
  final double totalAmount;
  final String currency;
  final Function(String method) onPaymentMethodSelected; // e.g., 'COD', 'CARD'
  final MessageSender sender;

  const PaymentSelectionItem({
    required this.id,
    required this.totalAmount,
    this.currency = 'EGP',
    required this.onPaymentMethodSelected,
    this.sender = MessageSender.gemini,
  });
  @override
  List<Object?> get props => [id, totalAmount, currency, onPaymentMethodSelected, sender];
}

@immutable
class DraftOrderItem extends ChatItem {
  const DraftOrderItem({
    required this.messageId,
    required this.parsedOrder,
    this.order, // New field for real-time order data
    required this.onConfirm,
    required this.onCancel,
    required this.onUpdateQuantity,
    required this.onAddItem,
    required this.onUpdateItem,
  });

  final String messageId;
  final ModelAiParsedOrder parsedOrder;
  final ModelOrder? order; // New field

  // Callbacks for the bubble's buttons
  final Future<void> Function() onConfirm;
  final Future<void> Function() onCancel;
  final Future<void> Function(int itemIndex, int change) onUpdateQuantity;
  final Future<void> Function(ModelOrderItem item) onAddItem;
  final Future<void> Function(int itemIndex, ModelOrderItem item) onUpdateItem;

  @override
  List<Object?> get props => [messageId, parsedOrder, order, onConfirm, onCancel, onUpdateQuantity, onAddItem, onUpdateItem];
}


