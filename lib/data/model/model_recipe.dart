import 'package:equatable/equatable.dart';

class ModelRecipe extends Equatable {
  const ModelRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTime, // e.g., "30 mins"
  });

  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final String prepTime;

  @override
  List<Object?> get props => [
        id,
        title,
        imageUrl,
        description,
        ingredients,
        instructions,
        prepTime
      ];
}