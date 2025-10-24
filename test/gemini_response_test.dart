import 'dart:convert';

class GeminiService {
  // Mock API Key, left empty as per guidelines
  static const String _apiKey = ''; 
  
  // A map to simulate the structured response the Gemini API would return
  // after processing the natural language prompt.
  static const String mockJsonResponse = '''
  {
    "items": [
      {"name": "Water Bottle (1.5L)", "quantity": 2, "notes": ""},
      {"name": "Small Chips (Spicy)", "quantity": 1, "notes": ""},
      {"name": "Lab Notebook", "quantity": 1, "notes": "From University Bookstore"},
      {"name": "Black Coffee", "quantity": 1, "notes": "No sugar"}
    ],
    "deliveryLocation": "Dorm 3, Room 402",
    "paymentMethod": "Digital Wallet (Fawry)",
    "estimatedTime": "14 minutes"
  }
  ''';

  Future<StructuredOrder> generateStructuredOrder(String conversationalPrompt) async {
    // 1. Simulate Network Delay (Crucial for user experience)
    await Future.delayed(const Duration(seconds: 2)); 

    // 2. In a real app, this is where you would call the Gemini API:
    //    The prompt (conversationalPrompt) would be sent with a specific
    //    JSON response schema to ensure structured output (S1).
    
    //    const apiUrl = '.../gemini-2.5-flash-preview-09-2025:generateContent?key=$_apiKey';
    //    ... fetch logic ...

    // 3. For this prototype, we use a mock response.
    try {
      final jsonResponse = json.decode(mockJsonResponse);
      return StructuredOrder.fromJson(jsonResponse);
    } catch (e) {
      throw Exception("Error parsing structured response: $e");
    }
  }
}