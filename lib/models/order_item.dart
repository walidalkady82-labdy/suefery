// Represents an individual item in the order
class OrderItem {
  final String itemId;
  final String name;
  int quantity;
  final double unitPrice;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}


