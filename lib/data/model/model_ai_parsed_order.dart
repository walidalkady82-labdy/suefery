import 'package:equatable/equatable.dart';

/// This is a DTO, not a database model.
/// It holds the data parsed by the AI from a tool call.
/// This is the class your 'ai_response.dart' file defines as ParsedOrder.
class ModelAiParsedOrder extends Equatable {
  final List<ModelAiParsedItem> requestedItems;
  final String aiResponseText;

  const ModelAiParsedOrder({
    required this.requestedItems,
    required this.aiResponseText,
  });

  factory ModelAiParsedOrder.fromMap(Map<String, dynamic> map) {
    return ModelAiParsedOrder(
      requestedItems: (map['items'] as List)
          .map((item) => ModelAiParsedItem.fromMap(item))
          .toList(),
      aiResponseText: map['aiResponseText'] as String,
    );
  }

   ModelAiParsedOrder copyWith({
  List<ModelAiParsedItem>? requestedItems,
  String? aiResponseText
  }) {
    return ModelAiParsedOrder(
      requestedItems: requestedItems ?? this.requestedItems,
      aiResponseText: aiResponseText ?? this.aiResponseText,
    );
  }
  @override
  List<Object?> get props => [requestedItems, aiResponseText];
}

class ModelAiParsedItem  extends Equatable  {
  final String itemName;
  final double quantity;
  final String? brand;
  final String? unit;
  final double unitPrice;
  final String? notes;


  const ModelAiParsedItem({
    required this.itemName,
    required this.quantity,
    required this.brand,
    this.unit,
    this.unitPrice = 0.0,
    this.notes,
  });

  factory ModelAiParsedItem.fromMap(Map<String, dynamic> map) {
    return ModelAiParsedItem(
      itemName: map['itemName'] as String,
      brand: map['brand'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
    );
  }

  ModelAiParsedItem copyWith({String? itemName ,String? brand , double? quantity , 
  String? unit,double? unitPrice , String? notes}) {
    return ModelAiParsedItem(
      itemName: this.itemName,
      brand: this.brand,
      quantity: quantity ?? this.quantity,
      unit: this.unit,
      unitPrice: this.unitPrice,
      notes: this.notes,
    );
  }
  @override
  List<Object?> get props => [itemName, brand, quantity, unit, unitPrice, notes];

}