
/// Abstract interface for the Gemini Repository.
/// This allows for dependency injection and easy mocking.
abstract class IGeminiRepo {
  /// Sends a structured payload to the Gemini API and returns the
  /// decoded JSON response from the model.
  Future<Map<String, dynamic>> generateContent(Map<String, dynamic> payload);

  /// Sends a simple text prompt and returns a plain text response.
  Future<String> generateText(
      {required String prompt, List<Map<String, dynamic>>? history});
}