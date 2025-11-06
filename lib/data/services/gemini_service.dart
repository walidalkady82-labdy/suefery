import 'dart:async';
import 'dart:math';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/chat_message.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/log_repo.dart';
import '../repositories/i_gemini_repo.dart';
import 'remote_config_service.dart';

class GeminiService {
  final _log = LogRepo('GeminiService');
  final IGeminiRepo _repository;
  final RemoteConfigService _configService;
  final _random = Random();

  GeminiService(this._repository, this._configService);

  // --- 1. PROMPT & CONFIG FOR DELIVERY ASSISTANT ---

  static const String _deliveryAppSystemPrompt = """
    You are the **Suefery** AI Shopping Assistant for a delivery service operating in Beni Suef, Egypt. 
    Your role is to process user messages, extract a confirmed order list, and present it back to the user for confirmation.
    If the user's last message seems to be a confirmation (e.g., 'yes', 'confirm', 'go ahead') for a pending order you just presented, set "order_confirmed": true.
    If the user's last message is a cancellation (e.g., 'no', 'cancel', 'stop'), respond with a cancellation message and set "order_confirmed": false.
    
    1. CONVERSATION: If the user is just chatting or asking general questions, respond naturally (set confirmed=false).
    2. ORDER PARSING: If the user expresses a clear intent to order items, parse the request into a list of items with quantities and notes.
    3. JSON OUTPUT: ALWAYS respond with a JSON object containing two keys: "ai_response_text" and "parsed_order".
    """;

  static final Map<String, dynamic> _deliveryAppGenerationConfig = {
    'responseMimeType': 'application/json',
    'responseSchema': {
      'type': 'OBJECT',
      'properties': {
        'ai_response_text': {'type': 'STRING'},
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
                  'notes': {'type': 'STRING'},
                  'unit_price': {'type': 'NUMBER'}
                }
              }
            }
          }
        }
      }
    }
  };

  // --- 2. PROMPT & CONFIG FOR CHEF ---

  static const String _chefSystemPrompt = """
    You are **"Chef Helmy,"** a friendly and practical Egyptian home cook from Beni Suef. 
    Your goal is to help users decide what to make for lunch *today* by suggesting recipes they can cook using ingredients ordered from our delivery app.
    Your main job is to create a *shopping list* for the user.
    You MUST respond with a JSON object *only* (do not add conversational text).
    """;
    
  static final Map<String, dynamic> _chefGenerationConfig = {
    'responseMimeType': 'application/json',
    'responseSchema': {
      'type': 'OBJECT',
      'properties': {
        'suggestions': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'name': {'type': 'STRING'},
              'description': {'type': 'STRING'},
              'ingredients': {
                'type': 'ARRAY',
                'items': {
                  'type': 'OBJECT',
                  'properties': {
                    'name': {'type': 'STRING'},
                    'quantity': {'type': 'STRING'}
                  }
                }
              }
            }
          }
        }
      }
    }
  };

  // --- 3. SERVICE METHODS (Using the prompts) ---

  /// Processes a chat history as the **Delivery Assistant**.
  Future<AiResponse> getAiOrderResponse(List<ChatMessage> history) async {
    // Check the config value *every time*
    if (_configService.geminiUseMocks) {
      debugPrint("GeminiService: Using MOCK for getAiOrderResponse()");
      return _getAiOrderResponseMock();
    }

    final contents = history
        .map((m) => {
              'role': m.senderType == 'user' ? 'user' : 'model',
              'parts': [{'text': m.text}]
            })
        .toList();

    final payload = {
      'contents': contents,
      'systemInstruction': {
        'parts': [{'text': _deliveryAppSystemPrompt}]
      },
      'generationConfig': _deliveryAppGenerationConfig
    };

    try {
      final Map<String, dynamic> rawJsonResponse =
          await _repository.generateContent(payload);
      return AiResponse.fromMap(rawJsonResponse);
    } catch (e) {
      _log.e('GeminiService Error: $e');
      return AiResponse.error(
          'Sorry, I\'m having trouble connecting. Please try again.');
    }
  }

  /// Generates recipe ideas as the **Chef**.
  Future<Map<String, dynamic>> generateRecipeSuggestion() async {
    if (_configService.geminiUseMocks) {
      debugPrint("GeminiService: Using MOCK for generateRecipeSuggestion()");
      return _generateRecipeSuggestionMock();
    }

    // This is the user's "turn" for this feature
    final userPrompt =
        "Please suggest two popular and quick Egyptian lunch ideas I can make today.";

    // Build the payload specific to the Chef
    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [{'text': userPrompt}]
        }
      ],
      'systemInstruction': {
        'parts': [{'text': _chefSystemPrompt}]
      },
      'generationConfig': _chefGenerationConfig
    };

    try {
      // Both methods now call the *same* repository method,
      // just with a different payload.
      final Map<String, dynamic> rawJsonResponse =
          await _repository.generateContent(payload);
      
      // We return the raw map, which the Cubit will parse
      return rawJsonResponse;
    } catch (e) {
      debugPrint('GeminiService Error (Recipe): $e');
      return {
        'suggestions': []
      }; // Return an empty list on error
    }
  }

  // --- Private Mock Helpers ---

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
            {"item_name": "Water Bottle", "quantity": 2, "notes": "Large", "unit_price": 5.0},
            {"item_name": "Chips", "quantity": 1, "notes": "Spicy", "unit_price": 8.0}
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
            {"item_name": "Molto", "quantity": 5, "notes": "Cheese flavor", "unit_price": 3.0}
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
    final selectedMock = mockResponses[_random.nextInt(mockResponses.length)]; //
    
    return AiResponse.fromMap(selectedMock);
  }


  Future<Map<String, dynamic>> _generateRecipeSuggestionMock() async {
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(500)));
    final mockRecipes = [
      {
        'name': 'Mock Koshari',
        'ingredients': ['Mock Rice', 'Mock Lentils', 'Mock Tomato Sauce']
      },
      {
        'name': 'Mock Molokhia',
        'ingredients': ['Mock Molokhia leaves', 'Mock Chicken Broth', 'Mock Garlic']
      }
    ];
    return mockRecipes[_random.nextInt(mockRecipes.length)];
  }
}