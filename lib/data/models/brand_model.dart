class BrandModel {
  final String name;
  final String category;
  final String? imageUrl;

  BrandModel({required this.name, required this.category , this.imageUrl});

  factory BrandModel.fromMap(Map<String, dynamic> map) {
    return BrandModel(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',

    );
  }
}