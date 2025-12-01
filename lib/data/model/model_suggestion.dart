import 'package:equatable/equatable.dart';

import '../enum/suggestion_type.dart';

class ModelSuggestion extends Equatable {
  final String title;
  final String? subtitle;
  final SuggestionType type;
  final String? imageUrl;

  const ModelSuggestion({
    required this.title,
    required this.type,
    this.subtitle,
    this.imageUrl,
  });
  
  @override
  List<Object?> get props => [title, subtitle, type, imageUrl];
}

