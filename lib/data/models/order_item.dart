// Represents an individual item in the order
class OrderItem {
  final String itemId;
  final String name;
  int quantity;
  final double unitPrice;
  final String notes;


  OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.notes,

  });

  double get totalPrice => quantity * unitPrice;
}


