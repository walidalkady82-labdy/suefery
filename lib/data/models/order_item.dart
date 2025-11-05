// Represents an individual item in the order
class OrderItem {
  final String itemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String notes;


  OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.notes,

  });
    factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'],
      name: map['name'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'],
      notes: map['notes'],

    );
  }
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'notes': notes,
    };
  }
  double get totalPrice => quantity * unitPrice;

  OrderItem copyWith({
    String? itemId,
    String? name,
    int? quantity,
    double? unitPrice,
    String? notes,
  }) {
    return OrderItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
    );
  }
}
