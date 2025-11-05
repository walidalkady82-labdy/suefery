import 'package:flutter/foundation.dart';

/// Represents a single item parsed by the AI.
@immutable
class AiParsedItem {
  final String itemName;
  final int quantity;
  final String notes;

  const AiParsedItem({
    required this.itemName,
    required this.quantity,
    required this.notes,
  });

  factory AiParsedItem.fromMap(Map<String, dynamic> json) {
    return AiParsedItem(
      itemName: json['item_name'] ?? 'Unknown Item',
      quantity: json['quantity'] ?? 1,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'notes': notes,
    };
  }
}

/// Represents the complete `parsed_order` object from the AI.
@immutable
class AiParsedOrder {
  final bool orderConfirmed;
  final List<AiParsedItem> requestedItems;

  const AiParsedOrder({
    required this.orderConfirmed,
    required this.requestedItems,
  });

  factory AiParsedOrder.fromMap(Map<String, dynamic> json) {
    final itemsList = (json['requested_items'] as List<dynamic>?) ?? [];
    return AiParsedOrder(
      orderConfirmed: json['order_confirmed'] ?? false,
      requestedItems: itemsList
          .map((itemJson) => AiParsedItem.fromMap(itemJson))
          .toList(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'orderConfirmed': orderConfirmed,
      'requestedItems': requestedItems.map((item) => item.toMap()).toList(),
    };
  }
  // Default empty state
  factory AiParsedOrder.empty() {
    return const AiParsedOrder(orderConfirmed: false, requestedItems: []);
  }
}

/// Represents the complete, top-level response from the AI.
@immutable
class AiResponse {
  final String aiResponseText;
  final AiParsedOrder parsedOrder;

  const AiResponse({
    required this.aiResponseText,
    required this.parsedOrder,
  });

  factory AiResponse.fromMap(Map<String, dynamic> json) {
    return AiResponse(
      aiResponseText:
          json['ai_response_text'] ?? 'Sorry, I encountered an error.',
      parsedOrder: AiParsedOrder.fromMap(json['parsed_order'] ?? {}),
    );
  }

  // Default error state
  factory AiResponse.error(String errorMessage) {
    return AiResponse(
      aiResponseText: errorMessage,
      parsedOrder: AiParsedOrder.empty(),
    );
  }
}