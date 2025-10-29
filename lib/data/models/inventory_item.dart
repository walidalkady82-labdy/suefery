class InventoryItem {
  final String id;
  final String name;
  double price;
  bool isInStock;
  String category;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isInStock,
    required this.category,
  });

  // Simple copyWith method for state management
  InventoryItem copyWith({
    String? name,
    double? price,
    bool? isInStock,
    String? category,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      isInStock: isInStock ?? this.isInStock,
      category: category ?? this.category,
    );
  }
}