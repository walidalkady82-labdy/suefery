abstract class IRepoFirebaseAi {

  /// Generates a structured JSON response for a delivery order.
  /// Takes a [history] of chat messages.
  Future<Map<String, dynamic>> generateOrderContent(
    List<Map<String, dynamic>> history,
    {int? timeOut}
  );

  /// Generates a structured JSON response for a recipe suggestion.
  /// Takes a simple [prompt].
  Future<Map<String, dynamic>> generateRecipeContent(String prompt,{int? timeOut});

  /// Generates a free-form text response.
  /// Takes a [prompt] and an optional [history].
  Future<String> generateText({
    required String prompt,
    List<Map<String, dynamic>>? history,
    int? timeOut
  });
}