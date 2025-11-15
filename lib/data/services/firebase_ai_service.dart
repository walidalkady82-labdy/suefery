import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:suefery/data/enums/message_sender.dart';

import '../models/chat_message_model.dart';
import '../models/tool_use_response.dart';
import '../repositories/repo_log.dart';

class FirebaseAiService {
  final _log = RepoLog('FirebaseAiService');
  final FirebaseFunctions _functions;
  final bool _useMocks;

  FirebaseAiService(this._functions, this._useMocks);

  /// --- NEW: Define the tools your app provides ---
  /// This list is sent to the AI so it knows what it can do.
  final _appTools = [
    {
      "name": "createOrder",
      "description": "Creates a new food order from a list of items.",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "items": {
            "type": "ARRAY",
            "description": "A list of food items to order.",
            "items": {
              "type": "OBJECT",
              "properties": {
                "itemName": {"type": "STRING"},
                "quantity": {"type": "NUMBER"},
                "notes": {"type": "STRING", "description": "e.g., 'extra spicy'"},
                "unitPrice": {"type": "NUMBER", "description": "The estimated price per item"}
              },
              "required": ["itemName", "quantity", "unitPrice"]
            }
          },
          "aiResponseText": {"type": "STRING", "description": "A confirmation message to show the user."}
        },
        "required": ["items", "aiResponseText"]
      }
    },
    {
      "name": "suggestRecipe",
      "description": "Suggests a recipe for the user.",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "recipeName": {"type": "STRING"},
          "imageUrl": {"type": "STRING"},
          "ingredients": {"type": "ARRAY", "items": {"type": "STRING"}},
          "instructions": {"type": "ARRAY", "items": {"type": "STRING"}}
        },
        "required": ["recipeName", "ingredients", "instructions"]
      }
    },
    {
      "name": "getHelp",
      "description": "Provides a help message about the app.",
      "parameters": {
        "type": "OBJECT",
        "properties": {
          "helpText": {"type": "STRING"}
        },
        "required": ["helpText"]
      }
    }
  ];

  /// --- REPLACES ALL OTHER METHODS ---
  /// Gets a structured response from the AI, which will be
  /// either a tool call or a simple text message.
  Future<ToolUseResponse> getStructuredResponse(List<ChatMessageModel> history) async {
    if (_useMocks) {
      _log.i("FirebaseAiService: Using MOCK for getStructuredResponse()");
      return _getMockResponse(history.last.content ?? "");
    }

    try {
      _log.i('Calling geminiProxy with tool definitions...');
      final callable = _functions.httpsCallable('geminiProxy');
      
      // Assumes your 'geminiProxy' function is updated
      // to accept a 'tools' argument.
      final response = await callable.call<Map<String, dynamic>>({
        'history': history
            .map((m) => {
                  'role': m.senderType == MessageSender.user ? 'user' : 'model',
                  'text': m.content,
                })
            .toList(),
        'tools': _appTools, // <-- Pass the tool definitions
      });

      _log.i('Successfully received structured response from geminiProxy.');

      // --- Parse the AI's response ---
      final data = response.data;

      // Check if the AI wants to call a tool
      if (data.containsKey('toolCall')) {
        final toolName = data['toolCall']['name'] as String;
        final arguments = data['toolCall']['arguments'] as Map<String, dynamic>;
        
        return ToolUseResponse.tool(toolName, arguments);
      }
      
      // Otherwise, it's a simple text response
      final text = data['text'] as String? ?? "Sorry, I'm not sure how to help with that.";
      return ToolUseResponse.text(text);

    } on FirebaseFunctionsException catch (e, s) {
      _log.e('FunctionsException calling geminiProxy: ${e.message}', stackTrace: s);
      return ToolUseResponse.error('Sorry, I\'m having trouble connecting. Please try again.');
    } catch (e, s) {
      _log.e('Generic error calling geminiProxy: $e', stackTrace: s);
      rethrow;
    }
  }

  // --- Mock Helper (Updated) ---
  Future<ToolUseResponse> _getMockResponse(String lastMessage) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final lowerMessage = lastMessage.toLowerCase();

    if (lowerMessage.contains("recipe") || lowerMessage.contains("chef")) {
      return ToolUseResponse.tool("suggestRecipe", {
        "recipeName": "Mock Koshari",
        "imageUrl": "https://via.placeholder.com/150",
        "ingredients": ["1 cup Mock Rice", "1 cup Mock Lentils"],
        "instructions": ["Boil water...", "Serve hot."]
      });
    }

    if (lowerMessage.contains("burger") || lowerMessage.contains("order")) {
      return ToolUseResponse.tool("createOrder", {
        "items": [
          {"itemName": "Burger", "quantity": 2, "notes": "extra cheese", "unitPrice": 50.0}
        ],
        "aiResponseText": "Mock: I have 2 burgers with extra cheese. Sound good?"
      });
    }
    
    if (lowerMessage.contains("help")) {
      return ToolUseResponse.tool("getHelp", {
        "helpText": "Mock: I'm here to help! You can order food or ask for recipes."
      });
    }

    return ToolUseResponse.text("Mock: I'm not sure how to help with that.");
  }
}

// class FirebaseAiService {
//   final _log = RepoLog('FirebaseAiService');
//   final FirebaseFunctions _functions;
//   final bool _useMocks;

//   FirebaseAiService(this._functions, this._useMocks);

//   /// A generic method to call the geminiProxy Cloud Function.
//   Future<Map<String, dynamic>> _callGeminiProxy({
//     required String modelType,
//     required List<ChatMessage> history,
//   }) async {
//     try {
//       _log.i('Calling geminiProxy with modelType: $modelType...');
//       final callable = _functions.httpsCallable('geminiProxy');
//       final response = await callable.call<Map<String, dynamic>>({
//         'modelType': modelType,
//         'history': history
//             .map((m) => {
//                   'role': m.senderType == MessageSender.user ? 'user' : 'model',
//                   'text': m.content,
//                 })
//             .toList(),
//       });
//       _log.i('Successfully received response from geminiProxy.');
//       return response.data;
//     } on FirebaseFunctionsException catch (e, s) {
//       _log.e(
//         'FirebaseFunctionsException calling geminiProxy: ${e.code} - ${e.message}',
//         stackTrace: s,
//       );
//       // Rethrow to be handled by the calling method.
//       rethrow;
//     } catch (e, s) {
//       _log.e('Generic error calling geminiProxy: $e', stackTrace: s);
//       rethrow;
//     }
//   }

//   /// Processes a chat history as the **Delivery Assistant**.
//   Future<AiResponse> getAiOrderResponse(List<ChatMessage> history) async {
//     // Check the config value *every time*
//     if (_useMocks) {
//       debugPrint("GeminiService: Using MOCK for getAiOrderResponse()");
//       return _getAiOrderResponseMock();
//     }

//     try {
//       final rawJsonResponse = await _callGeminiProxy(modelType: 'order', history: history);
//       return AiResponse.fromMap(rawJsonResponse);
//     } catch (e) {
//       _log.e('getAiOrderResponse Error: $e');
//       return AiResponse.error('Sorry, I\'m having trouble connecting. Please try again.');
//     }
//   }

//   /// Generates recipe ideas as the **Chef**.
//   Future<Map<String, dynamic>> generateRecipeSuggestion() async {
//     if (_useMocks) {
//       debugPrint("GeminiService: Using MOCK for generateRecipeSuggestion()"); //
//       return _generateRecipeSuggestionMock();
//     }

//     try {
//       // The 'chef' model in the backend doesn't require history.
//       final rawJsonResponse = await _callGeminiProxy(modelType: 'chef', history: []);
//       return rawJsonResponse;
//     } catch (e) {
//       _log.e('generateRecipeSuggestion Error: $e');
//       return {'suggestions': []}; // Return an empty list on error
//     }
//   }

//   /// Generates a generic text response as the **General Assistant**.
//   Future<String> generateText({required String prompt, List<Map<String, dynamic>>? history}) async {
//     if (_useMocks) {
//       debugPrint("FirebaseAiService: Using MOCK for generateText()");
//       return "This is a mock response to your question.";
//     }

//     // The cloud function expects a List<ChatMessage>. We'll convert the raw history
//     // and add the new prompt as the last message.
//     final chatHistory = (history ?? [])
//         .map((h) => ChatMessage.fromMap(h..['id'] = 'temp'..['timestamp'] = DateTime.now().toIso8601String()))
//         .toList();
//     //TODO: check id and sender id
//     chatHistory.add(ChatMessage(
//       id: 'temp_user_prompt',
//       senderId: 'temp_user',
//       content: prompt,
//       senderType: MessageSender.user,
//       timestamp: DateTime.now(),
//     ));

//     try {
//       final result = await _callGeminiProxy(modelType: 'general', history: chatHistory);
//       // The 'general' model returns a map like {'text': '...'}
//       return result['text'] as String? ?? "Sorry, I couldn't process that.";
//     } catch (e) {
//       _log.e('generateText Error: $e');
//       return "I'm having trouble thinking right now. Please try again in a moment.";
//     }
//   }

//   // --- Private Mock Helpers ---

//   Future<AiResponse> _getAiOrderResponseMock() async {
//     await Future.delayed(const Duration(seconds: 1));
//     return AiResponse.fromMap({
//       "ai_response_text": "Mock: I've got 2 bottles of Water and 1 bag of Chips. Correct?",
//       "parsed_order": {
//         "order_confirmed": true,
//         "requested_items": [
//           {"item_name": "Water Bottle", "quantity": 2, "notes": "Large", "unit_price": 5.0},
//           {"item_name": "Chips", "quantity": 1, "notes": "Spicy", "unit_price": 8.0}
//         ]
//       }
//     });
//   }

//   Future<Map<String, dynamic>> _generateRecipeSuggestionMock() async {
//     await Future.delayed(const Duration(seconds: 1));
//     return {
//       'name': 'Mock Koshari',
//       'ingredients': [
//         {'name': 'Mock Rice', 'quantity': '1 cup'},
//         {'name': 'Mock Lentils', 'quantity': '1 cup'},
//       ]
//     };
//   }
// }

