import '../enums/suggestion_type.dart';

class SuggestionModel {
  final String title;
  final String? subtitle;
  final SuggestionType type;
  final String? imageUrl;

  SuggestionModel({
    required this.title,
    required this.type,
    this.subtitle,
    this.imageUrl,
  });
}