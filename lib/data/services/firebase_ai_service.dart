import 'dart:async';
import 'dart:math';
import 'package:suefery/data/models/ai_response.dart';
import 'package:suefery/data/models/chat_message.dart';
import 'package:flutter/foundation.dart';
import 'package:suefery/data/repositories/i_repo_firebase_ai.dart';

import '../repositories/repo_log.dart';

class FirebaseAiService {
  final _log = RepoLog('GeminiService');
  final IRepoFirebaseAi _repository;
  final bool _useMocks;
  final _random = Random();

  FirebaseAiService(this._repository, this._useMocks);
  
  /// Processes a chat history as the **Delivery Assistant**.
  Future<AiResponse> getAiOrderResponse(List<ChatMessage> history) async {
    // Check the config value *every time*
    if (_useMocks) {
      debugPrint("GeminiService: Using MOCK for getAiOrderResponse()");
      return _getAiOrderResponseMock();
    }

    final contents = history
        .map((m) => {
              'role': m.senderType == 'user' ? 'user' : 'model',
              'parts': [{'text': m.text}]
            })
        .toList();

    try {
      final Map<String, dynamic> rawJsonResponse =
          await _repository.generateOrderContent(contents);
      return AiResponse.fromMap(rawJsonResponse);
    } catch (e) {
      _log.e('GeminiService Error: $e');
      return AiResponse.error(
          'Sorry, I\'m having trouble connecting. Please try again.');
    }
  }

  /// Generates recipe ideas as the **Chef**.
  Future<Map<String, dynamic>> generateRecipeSuggestion() async {
    if (_useMocks) {
      debugPrint("GeminiService: Using MOCK for generateRecipeSuggestion()"); //
      return _generateRecipeSuggestionMock();
    }

    final userPrompt =
        "Please suggest two popular and quick Egyptian lunch ideas I can make today.";

    try {
      // Both methods now call the *same* repository method,
      // just with a different payload.
      final Map<String, dynamic> rawJsonResponse =
          await _repository.generateRecipeContent(userPrompt);
      
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
        'ingredients': [
          {'name':'Mock Rice', 'quantity':'1'}, 
          {'name':'Mock Lentils', 'quantity':'2'},  
          {'name':'Mock Tomato Sauce', 'quantity':'3'}, 
          ]
      },
      {
        'name': 'Mock Molokhia',
        'ingredients': [
          {'name':'Molokhia leaves', 'quantity':'1'}, 
          {'name':'Chicken Broth', 'quantity':'1'}, 
          {'name':'Garlic', 'quantity':'1'}, 
          ]
      }
    ];
    return mockRecipes[_random.nextInt(mockRecipes.length)];
  }
}