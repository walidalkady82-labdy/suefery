import 'package:suefery/data/models/ai_response.dart';

/// A wrapper class to hold one of several possible AI response types
/// returned by the [ChatService]. This allows the UI layer (Cubit) to
/// easily handle different outcomes from a single service call.
class AiChatResponse {
  /// A structured response for a delivery order.
  final AiResponse? orderResponse;

  /// A map containing a recipe suggestion.
  final Map<String, dynamic>? recipeSuggestion;

  /// A simple text response for a generic chat message.
  final String? genericChatResponse;

  const AiChatResponse({
    this.orderResponse,
    this.recipeSuggestion,
    this.genericChatResponse,
  });

  /// True if the response is a structured order.
  bool get isOrderResponse => orderResponse != null;

  /// True if the response is a recipe suggestion.
  bool get isRecipeSuggestion => recipeSuggestion != null;

  /// True if the response is a generic chat message.
  bool get isGenericChat => genericChatResponse != null;
}