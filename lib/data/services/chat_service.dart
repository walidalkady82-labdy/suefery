import 'dart:convert';
import 'dart:async';
import 'dart:math' show Random;
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/chat_message.dart';
import '../../domain/repositories/log_repo.dart';
import '../repositories/i_firestore_repository.dart';
import '../repositories/i_gemini_repo.dart';

// IMPORTANT: This API key must be blank for the Canvas environment to provide the token.
const String apiKey = ""; 
const String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$apiKey";

// class GeminiService1 {
//   final String systemPrompt = """
//     You are the **Suefery** AI Shopping Assistant for a delivery service operating in Beni Suef, Egypt. 
//     Your role is to process user messages, extract a confirmed order list, and present it back to the user for confirmation. 
    
//     1. CONVERSATION: If the user is just chatting or asking general questions, respond naturally (set confirmed=false).
//     2. ORDER PARSING: If the user expresses a clear intent to order items, parse the request into a list of items with quantities and notes.
//     3. JSON OUTPUT: ALWAYS respond with a JSON object containing two keys:
//         - "ai_response_text": A friendly, localized conversational response to the user.
//         - "parsed_order": An object matching the ParsedOrder structure.
        
//     ParsedOrder JSON Structure:
//     {
//       "order_confirmed": true | false,
//       "requested_items": [
//         { "item_name": "string", "quantity": number, "notes": "string (e.g., brand, size, color)" }
//       ]
//     }
    
//     If the user's intent is clear enough to form an order, set "order_confirmed" to true.
    
//     Example for "I need 2 bottles of large coke and 1 bag of Lays chips, spicy flavor":
    
//     {
//       "ai_response_text": "Great! I've prepared your Suefery order for confirmation. You requested 2 items: 2 large Cokes and 1 bag of spicy Lays chips. Does this look correct?",
//       "parsed_order": {
//         "order_confirmed": true,
//         "requested_items": [
//           { "item_name": "Large Coca-Cola bottle", "quantity": 2, "notes": "Large size" },
//           { "item_name": "Lays Chips", "quantity": 1, "notes": "Spicy flavor" }
//         ]
//       }
//     }
//     """;

//   Future<Map<String, dynamic>> callGemini(List<ChatMessage> history) async {
//     final contents = history.map((m) => {
//       'role': m.senderType == 'user' ? 'user' : 'model', 
//       'parts': [{'text': m.text}]
//     }).toList();

//     final payload = {
//       'contents': contents,
//       'systemInstruction': { 'parts': [{'text': systemPrompt}] },
//       'generationConfig': {
//         'responseMimeType': 'application/json',
//         'responseSchema': {
//           'type': 'OBJECT',
//           'properties': {
//             'ai_response_text': {'type': 'STRING', 'description': 'A friendly, conversational response to the user.'},
//             'parsed_order': {
//               'type': 'OBJECT',
//               'properties': {
//                 'order_confirmed': {'type': 'BOOLEAN'},
//                 'requested_items': {
//                   'type': 'ARRAY',
//                   'items': {
//                     'type': 'OBJECT',
//                     'properties': {
//                       'item_name': {'type': 'STRING'},
//                       'quantity': {'type': 'INTEGER'},
//                       'notes': {'type': 'STRING'}
//                     }
//                   }
//                 }
//               }
//             }
//           }
//         }
//       }
//     };

//     try {
//       final http.Response response = await fetchWithRetry(apiUrl, {
//         'method': 'POST',
//         'headers': {'Content-Type': 'application/json'},
//         'body': jsonEncode(payload),
//       });

//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body);
//         final jsonText = result['candidates']?[0]['content']?['parts']?[0]?['text'];
//         if (jsonText != null) {
//           return jsonDecode(jsonText);
//         }
//       }
//       return {'ai_response_text': 'Error: Failed to get response from AI.', 'parsed_order': {'order_confirmed': false, 'requested_items': []}};
//     } catch (e) {
//       debugPrint('API Error: $e');
//       return {'ai_response_text': 'Error: Network or API issue.', 'parsed_order': {'order_confirmed': false, 'requested_items': []}};
//     }
//   }

//   // Helper function to process the raw JSON output into a ParsedOrder model
//   StructuredOrder parseGeminiResponse(Map<String, dynamic> jsonResponse) {
//     final parsedOrderJson = jsonResponse['parsed_order'] ?? {};
//     final confirmed = parsedOrderJson['order_confirmed'] ?? false;
//     final itemsList = parsedOrderJson['requested_items'] as List<dynamic>? ?? [];

//     final List<OrderItem> orderItems = itemsList.map((itemJson) {
//       return OrderItem(
//         itemId: '',
//         name: itemJson['item_name'] ?? 'Unknown Item',
//         quantity: itemJson['quantity'] is int ? itemJson['quantity'] : int.tryParse(itemJson['quantity'].toString()) ?? 1,
//         unitPrice: itemJson['unitPrice'] is int ? itemJson['unitPrice'] : int.tryParse(itemJson['unitPrice'].toString()) ?? 1,
//         notes: itemJson['notes'] ?? '',
//       );
//     }).toList();
//     double totalPrice = orderItems.fold(
//       0.0,
//       (sum, item) => sum + (item.unitPrice * item.quantity),
//     );
//     return StructuredOrder(
//       orderId: '',
//       customerId: '', 
//       partnerId: '',
//       // orderConfirmed: confirmed, 
//       // requestedItems: items,  
//       estimatedTotal: totalPrice, 
//       deliveryFee: 0, 
//       deliveryAddress: '', 
//       status: OrderStatus.Assigned, 
//       progress: null, 
//       riderId: '', 
//       items: []
//     );
//   }

//   // Simple fetch retry mechanism 
//   Future<http.Response> fetchWithRetry(
//     String url,
//     Map<String, dynamic> options, {
//     int retries = 3,
//     Duration delay = const Duration(seconds: 2),
//   }) async {
//     for (int i = 0; i < retries; i++) {
//       try {
//         final uri = Uri.parse(url);
//         final headers = (options['headers'] as Map<String, String>?) ?? {};
//         final body = options['body'];

//         final response = await http.post(
//           uri,
//           headers: headers,
//           body: body,
//         ).timeout(const Duration(seconds: 15));

//         // Success, or a client error that shouldn't be retried (e.g., 400 Bad Request)
//         if (response.statusCode < 500 && response.statusCode != 429) {
//           return response;
//         }
        
//         debugPrint('Attempt ${i + 1} failed with status ${response.statusCode}. Retrying in ${delay.inSeconds}s...');
//       } catch (e) {
//         debugPrint('Attempt ${i + 1} failed with exception: $e. Retrying in ${delay.inSeconds}s...');
//       }
      
//       // Wait before the next retry
//       await Future.delayed(delay);
//     }
//     // If all retries fail, throw an exception.
//     throw Exception('Failed to fetch data from $url after $retries retries.');
//   }

//   @visibleForTesting
//   Future<List<ChatMessage>> generateOrderFromPromptMock(String prompt, String userId) async {
//     await Future.delayed(const Duration(seconds: 1));
//     return [
//       ChatMessage(
//         senderId: 'gemini',
//         text: 'SUEFERY AI: I see you need: 2x Water, 1x Chips. Total: 45 EGP. Confirmed?',
//         senderType: MessageSender.gemini,
//         timestamp: DateTime.now(),
//       ),
//     ];
//   }

//   @visibleForTesting
//   Future<Map<String, dynamic>> generateRecipeSuggestionMock() async {
//     await Future.delayed(const Duration(seconds: 2));
//     return {
//       'name': 'Egyptian Koshari',
//       'ingredients': ['Rice (1 cup)', 'Lentils (1/2 cup)', 'Tomato Sauce', 'Fried Onions'],
//     };
//   }

//   Future<Map<String, dynamic>> generateRecipeSuggestion() async {
//     await Future.delayed(const Duration(seconds: 2));
//     return {
//       'name': 'Egyptian Koshari',
//       'ingredients': ['Rice (1 cup)', 'Lentils (1/2 cup)', 'Tomato Sauce', 'Fried Onions'],
//     };
//   }


// }


  /* Note: Your original `parseGeminiResponse` function that created a 
    `StructuredOrder` should now live *outside* this service.

    The correct flow is:
    1. Your UI (e.g., Chat BLoC/Cubit) calls `geminiService.getAiOrderResponse()`.
    2. It gets back an `AiResponse` object.
    3. The BLoC/Cubit checks `aiResponse.parsedOrder.orderConfirmed`.
    4. If true, the BLoC/Cubit can then use that data to create a 
       `StructuredOrder` and move to the order confirmation screen.

    This service's only job is to talk to the AI, not to create
    full-fledged orders in your app's domain.
  */
class ChatService {
  final IGeminiRepo _repository;
  final IFirestoreRepo _firestoreRepo;
  final bool useMocks;
  final _random = Random();
  final _log = LogRepo('ChatService');
  // The service now takes the repository as a dependency
  ChatService(this._repository,this._firestoreRepo, {this.useMocks=false});

   // This logic now lives in the service
  static const String _basePath = 'artifacts/default-app-id/public/data/chats';

  // The system prompt and schema are business logic, so they stay here.
  final String _systemPrompt = """
    You are the **Suefery** AI Shopping Assistant... 
    (Your full system prompt remains unchanged)
    ...
    """;

  final Map<String, dynamic> _generationConfig = {
    'responseMimeType': 'application/json',
    'responseSchema': {
      'type': 'OBJECT',
      'properties': {
        'ai_response_text': {
          'type': 'STRING',
          'description': 'A friendly, conversational response to the user.'
        },
        'parsed_order': {
          'type': 'OBJECT',
          'properties': {
            'order_confirmed': {'type': 'BOOLEAN'},
            'requested_items': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'item_name': {'type': 'STRING'},
                  'quantity': {'type': 'INTEGER'},
                  'notes': {'type': 'STRING'}
                }
              }
            }
          }
        }
      }
    }
  };

  /// Processes a chat history and returns a structured AI response.
  Future<AiResponse> getAiOrderResponse(List<ChatMessage> history) async {
    // ---- START MOCK LOGIC ----
    if (useMocks) {
      _log.i("Using MOCK for getAiOrderResponse()");
      return _getAiOrderResponseMock();
    }
    // ---- END MOCK LOGIC ----
    final contents = history
        .map((m) => {
              'role': m.senderType == MessageSender.user ? 'user' : 'model',
              'parts': [{'text': m.text}]
            })
        .toList();

    final payload = {
      'contents': contents,
      'systemInstruction': {
        'parts': [{'text': _systemPrompt}]
      },
      'generationConfig': _generationConfig
    };

    try {
      // 1. Call the repository to get the raw JSON
      final Map<String, dynamic> rawJsonResponse =
          await _repository.generateContent(payload);

      // 2. Parse the raw JSON into our clean AiResponse model
      return AiResponse.fromJson(rawJsonResponse);
    } catch (e) {
      _log.e('GeminiService Error: $e');
      // 3. Return a clean error-state model
      return AiResponse.error('Sorry, I\'m having trouble connecting. Please try again in a moment.');
    }
  }

  /// Generates a simple text-based recipe suggestion.
  Future<Map<String, dynamic>> generateRecipeSuggestion() async {
    // 1. Create a prompt for the AI
    // ---- START MOCK LOGIC ----
    if (useMocks) {
      _log.i("GeminiService: Using MOCK for generateRecipeSuggestion()");
      return _generateRecipeSuggestionMock();
    }
    // ---- END MOCK LOGIC ----
    final prompt = """
      You are a helpful Egyptian cooking assistant.
      Suggest a simple, popular Egyptian recipe.
      Respond with ONLY a JSON object in this exact format:
      {
        "name": "Recipe Name",
        "ingredients": ["Ingredient 1", "Ingredient 2", "Ingredient 3"]
      }
      """;

    try {
      // 2. Call the new text-generation method
      final String textResponse = await _repository.generateText(prompt: prompt);

      // 3. Parse the text response (which we asked to be JSON)
      final Map<String, dynamic> jsonResult = jsonDecode(textResponse);
      
      return {
        'name': jsonResult['name'] ?? 'Unknown Recipe',
        'ingredients': (jsonResult['ingredients'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [],
      };
      
    } catch (e) {
      _log.e('GeminiService Error (Recipe): $e');
      // Return a safe fallback
      return {
        'name': 'Koshari (Error)',
        'ingredients': ['Rice', 'Lentils', 'Tomato Sauce'],
      };
    }
  }

  Future<AiResponse> _getAiOrderResponseMock() async {
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(700)));

    // --- 3. CREATE A LIST OF MOCK ORDER RESPONSES ---
    final mockResponses = [
      // Mock 1: Confirmed order
      {
        "ai_response_text":
            "Mock 1: Sure thing! I've got 2 bottles of Water and 1 bag of Chips. Does this look correct?",
        "parsed_order": {
          "order_confirmed": true,
          "requested_items": [
            {"item_name": "Water Bottle", "quantity": 2, "notes": "Large"},
            {"item_name": "Chips", "quantity": 1, "notes": "Spicy"}
          ]
        }
      },
      // Mock 2: Just chatting (order NOT confirmed)
      {
        "ai_response_text":
            "Mock 2: Hello! How can I help you today?",
        "parsed_order": {
          "order_confirmed": false,
          "requested_items": []
        }
      },
      // Mock 3: Another confirmed order
      {
        "ai_response_text":
            "Mock 3: You got it. That's 5 packs of Molto. Ready to confirm?",
        "parsed_order": {
          "order_confirmed": true,
          "requested_items": [
            {"item_name": "Molto", "quantity": 5, "notes": "Cheese flavor"}
          ]
        }
      },
      // Mock 4: Just chatting
      {
        "ai_response_text":
            "Mock 4: We deliver all over Beni Suef! What can I get for you?",
        "parsed_order": {
          "order_confirmed": false,
          "requested_items": []
        }
      }
    ];

    // --- 4. PICK A RANDOM ONE ---
    final selectedMock = mockResponses[2]; //_random.nextInt(mockResponses.length)
    
    return AiResponse.fromJson(selectedMock);
  }

  Future<Map<String, dynamic>> _generateRecipeSuggestionMock() async {
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(500)));

    // --- 3. CREATE A LIST OF MOCK RECIPES ---
    final mockRecipes = [
      {
        'name': 'Mock Koshari',
        'ingredients': ['Mock Rice', 'Mock Lentils', 'Mock Tomato Sauce']
      },
      {
        'name': 'Mock Molokhia',
        'ingredients': ['Mock Molokhia leaves', 'Mock Chicken Broth', 'Mock Garlic']
      },
      {
        'name': 'Mock Ful Medames',
        'ingredients': ['Mock Fava Beans', 'Mock Lemon', 'Mock Cumin', 'Mock Olive Oil']
      }
    ];

    // --- 4. PICK A RANDOM ONE ---
    return mockRecipes[_random.nextInt(mockRecipes.length)];
  }


  // order handling 
  /// Builds the Firestore path for a given chat.
   String _getCollectionPath(String chatId) {
    return '$_basePath/$chatId/messages';
  }

  /// Gets a stream of [ChatMessage] for a given chat ID.
  Stream<List<ChatMessage>> getChatStream(String chatId) {
    final path = _getCollectionPath(chatId);

    return _firestoreRepo
        .quaryCollectionStream(
      path,
      orderBy: 'timestamp',
      isDescending: true, // Get latest messages first
    )
        .map((snapshot) {
      // This is the business logic from your Cubit
      final messages = snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data());
      }).toList();
      // Reverse to display chronologically (oldest at bottom)
      return messages.reversed.toList();
    }).handleError((error) {
      _log.e('Error in chat stream: $error');
      // Return an empty list on error to keep the stream alive
      return <ChatMessage>[];
    });
  }

  /// Sends a new message to a specific chat.
  Future<void> sendMessage(String chatId, ChatMessage message) async {
    if (message.text.trim().isEmpty) return;

    final path = _getCollectionPath(chatId);

    try {
      // The repo 'add' method automatically creates an ID
      // and adds it to the map for us.
      await _firestoreRepo.add(path, message.toMap());
    } catch (e) {
      _log.e('Error sending message: $e');
      rethrow;
    }
  }

}