import 'package:equatable/equatable.dart';

class ModelBrand extends Equatable {
  final String name;
  final String category;
  final String? imageUrl;

  const ModelBrand({required this.name, required this.category , this.imageUrl});

  factory ModelBrand.fromMap(Map<String, dynamic> map) {
    return ModelBrand(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',

    );
  }
  @override
  List<Object?> get props => [name, category, imageUrl];
}

