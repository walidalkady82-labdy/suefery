/// This is a DTO, not a database model.
/// It holds the data parsed by the AI from a tool call.
/// This is the class your 'ai_response.dart' file defines as ParsedOrder.
class AiParsedOrder {
  final List<AiParsedItem> requestedItems;
  final String aiResponseText;

  const AiParsedOrder({
    required this.requestedItems,
    required this.aiResponseText,
  });

  factory AiParsedOrder.fromMap(Map<String, dynamic> map) {
    return AiParsedOrder(
      requestedItems: (map['items'] as List)
          .map((item) => AiParsedItem.fromMap(item))
          .toList(),
      aiResponseText: map['aiResponseText'] as String,
    );
  }

   AiParsedOrder copyWith({
  List<AiParsedItem>? requestedItems,
  String? aiResponseText
  }) {
    return AiParsedOrder(
      requestedItems: this.requestedItems,
      aiResponseText: this.aiResponseText,
    );
  }

}

class AiParsedItem {
  final String itemName;
  final int quantity;
  final String? notes;
  final double unitPrice;

  const AiParsedItem({
    required this.itemName,
    required this.quantity,
    this.notes,
    required this.unitPrice,
  });

  factory AiParsedItem.fromMap(Map<String, dynamic> map) {
    return AiParsedItem(
      itemName: map['itemName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      notes: map['notes'] as String?,
      unitPrice: (map['unitPrice'] as num).toDouble(),
    );
  }
  
  AiParsedItem copyWith({ int? quantity }) {
    return AiParsedItem(
      itemName: this.itemName,
      quantity: quantity ?? this.quantity,
      notes: this.notes,
      unitPrice: this.unitPrice,
    );
  }
}