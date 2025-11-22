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
  final double quantity;
  final String? brand;
  final String? unit;
  final double unitPrice;

  const AiParsedItem({
    required this.itemName,
    required this.quantity,
    required this.brand,
    this.unit,
    this.unitPrice = 0.0,
  });

  factory AiParsedItem.fromMap(Map<String, dynamic> map) {
    return AiParsedItem(
      itemName: map['itemName'] as String,
      brand: map['brand'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  AiParsedItem copyWith({String? itemName ,String? brand , double? quantity , String? unit,double? unitPrice}) {
    return AiParsedItem(
      itemName: this.itemName,
      brand: this.brand,
      quantity: quantity ?? this.quantity,
      unit: this.unit,
      unitPrice: this.unitPrice,
    );
  }
}