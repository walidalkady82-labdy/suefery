import 'package:firebase_ai/firebase_ai.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/repository/i_repo_firebase_ai.dart';
import 'dart:convert';
import 'dart:async';

class RepoFirebaseAi with LogMixin implements IRepoFirebaseAi {
  final GenerativeModel _orderModel;
  final GenerativeModel _chefModel;
  final GenerativeModel _chatModel;

  RepoFirebaseAi._({
    required GenerativeModel orderModel,
    required GenerativeModel chefModel,
    required GenerativeModel chatModel,
  })  : _orderModel = orderModel,
        _chefModel = chefModel,
        _chatModel = chatModel;

  factory RepoFirebaseAi.create() {
    final generativeModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        );

    // --- REFACTORED: Use Function Calling (Tools) for the Order Model ---
    // This is more reliable than prompt-forcing JSON.
    final orderModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      // The system prompt is now simpler. It just guides the *conversation*.
      // It doesn't need to explain the JSON structure.
      systemInstruction: Content.system(_deliveryAppSystemPrompt),
      // We provide the formal "Tool" definition.
      tools: [
        Tool.functionDeclarations([_orderTool, _cancelOrderTool, _addItemTool, _removeItemTool]),
      ],
    );

    // Configuration for the Chef model
    final chefModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(_chefSystemPrompt),
      // --- FIX: Instantiate GenerationConfig directly ---
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 2048,
        // We must also specify the response MIME type for JSON output
        responseMimeType: 'application/json',
      ),
    );

    // Configuration for the generic Chat model
    final chatModel = generativeModel;

    return RepoFirebaseAi._(
      orderModel: orderModel,
      chefModel: chefModel,
      chatModel: chatModel,
    );
  }

  @override
  Future<Map<String, dynamic>> generateOrderContent(
      List<Map<String, dynamic>> history,{int? timeOut}) async {
    try {
      logInfo('Generating content with Order model (Tools)...');
      final contents = history.map((item) {
        final role = item['role'] as String;
        final parts = item['parts'] as List<dynamic>;
        if (parts.isNotEmpty && parts[0]['text'] != null) {
          final text = parts[0]['text'] as String;
          return Content(role,[TextPart(text)]);
        }
        return Content.text('');
      }).toList();

      final response = await _orderModel.generateContent(contents);

      // --- REFACTORED: Check for a function call ---
      final functionCalls = response.functionCalls;
      if (functionCalls.isNotEmpty) {
        final call = functionCalls.first;
        if (call.name == 'confirmOrder') {
          // The model decided to call our function!
          // The arguments map is the exact JSON we want.
          logInfo('Gemini Tool call succeeded: confirmOrder');
          return call.args as Map<String, dynamic>;
        }
      }

      // --- Fallback: Model is just chatting ---
      // If the model didn't call the function, it's just chatting.
      final text = response.text;
      if (text != null) {
        logInfo('Gemini returned a chat response.');
        // We still return the expected Map structure, but with no order.
        return {
          "ai_response_text": text,
          "parsed_order": {
            "order_confirmed": false,
            "requested_items": [],
          }
        };
      }

      logError('API Error: Response was empty (no text or function call).');
      throw Exception('Failed to get response from AI: Response was empty.');
    } catch (e, s) {
      logError('API Error in generateContent $e',stackTrace:   s);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> generateRecipeContent(String prompt,{int? timeOut}) async {
    try {
      logInfo('Generating content with Chef model...');
      final content = [Content.text(prompt)];
      final response = await _chefModel.generateContent(content);

      final jsonText = response.text;
      if (jsonText == null) {
        logError('API Error: Response text is null or empty.');
        throw Exception('Failed to get response from AI: No text in response.');
      }
      return jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e, s) {
      logError('API Error in generateRecipeContent: $e',stackTrace:  s);
      rethrow;
    }
  }

  @override
  Future<String> generateText(
      {required String prompt, List<Map<String, dynamic>>? history,int? timeOut}) async {
    try {
      logInfo('Generating text with Chat model...');

      // Convert history and current prompt into List<Content>
      final List<Content> contents = [];
      if (history != null) {
        for (var item in history) {
          final role = item['role'] as String;
          final parts = item['parts'] as List<dynamic>;
          if (parts.isNotEmpty && parts[0]['text'] != null) {
            final text = parts[0]['text'] as String;
            contents.add(Content(role,[TextPart(text)]));
          }
        }
      }

      contents.add(Content('user', [TextPart(prompt)])); 

      final response = await _chatModel.generateContent(contents);

      if (response.text != null) {
        return response.text!;
      } else {
        throw Exception('Failed to get response from AI: No text in response.');
      }
    } catch (e, s) {
      logError('API Error in generateText: $e', stackTrace:  s);
      rethrow;
    }
  }
}

// --- NEW: Simplified System Prompt for Tool-based Model ---
const String _deliveryAppSystemPrompt = """
You are a helpful and friendly delivery assistant for a local service called "Suefery".
Your primary goal is to understand the user's order from their chat messages.
When you are confident about the items and quantities, you MUST use the `confirmOrder` tool.
If the user is just asking a question or making small talk, just respond as a friendly assistant without using the tool.
""";

// --- NEW: Formal Tool Definition ---
final _orderTool =  FunctionDeclaration(
      // This is the function the model will "call"
      'confirmOrder',
      'Use this function when the user has confirmed an order and you have all the details.',
      // Define the *exact* structure of the arguments (our old JSON)
      parameters:{
            'ai_response_text': Schema.string(
              description: 'A friendly, conversational confirmation message to show the user in their language (e.g., "You got it! I have your order for... Is that correct?").',
            ),
            'parsed_order': Schema.object(
              description: 'parsed order.',
              properties:{
                'order_confirmed': Schema.boolean(
                  description: 'Set to true now that the order is being confirmed.',
                ),
                'requested_items': Schema.array(
                  description: 'A list of all items the user wants to order.',
                  items: Schema.object(
                    properties: {
                    'item_name': Schema.string(
                      description: 'The name of the item.'
                    ),
                    'unit': Schema.string(
                      description: 'The meauring unit of the items.'
                    ),
                    'quantity': Schema.integer(
                      description: 'The number of units.'
                    ),
                    'notes': Schema.string(
                      description: 'Optional notes like "Large" or "Spicy".'
                    ),
                    'unit_price': Schema.number(
                      description: 'The estimated price per unit.'
                    ),
                  },
                  optionalProperties:  ['notes'],
                  ),
                  
                )
              }
            ),
          },
);

// --- NEW: Tool for Cancelling an Order ---
final _cancelOrderTool = FunctionDeclaration(
  'cancelOrder',
  'Use this function when the user wants to cancel their order.',
  parameters: {
    'ai_response_text': Schema.string(
      description: 'A friendly confirmation that the order will be cancelled (e.g., "Okay, I will cancel that order for you.").',
    ),
  },
);

// --- NEW: Tool for Adding an Item to an Order ---
final _addItemTool = FunctionDeclaration(
  'addItem',
  'Use this function when the user wants to add one or more items to their existing order.',
  parameters: {
    'ai_response_text': Schema.string(
      description: 'A friendly confirmation message (e.g., "Sure, I will add that for you.").',
    ),
    'items_to_add': Schema.array(
      description: 'A list of items to add to the order.',
      items: Schema.object(
        properties: {
          'item_name': Schema.string(description: 'The name of the item.'),
          'quantity': Schema.integer(description: 'The number of units.'),
          'unit': Schema.string(description: 'The measuring unit of the item (e.g., "kg", "piece").'),
        },
        optionalProperties: ['unit'],
      ),
    ),
  },
);

// --- NEW: Tool for Removing an Item from an Order ---
final _removeItemTool = FunctionDeclaration(
    'removeItem', 'Use this function when the user wants to remove an item from their order.',
    parameters: {'item_name': Schema.string(description: 'The name of the item to remove.')});
// --- Chef Model Configuration (Unchanged) ---
const String _chefSystemPrompt = """
You are a helpful chef specializing in Egyptian cuisine. 
Your goal is to provide recipe suggestions in a structured JSON format. 
The root of the JSON should be a key named 'suggestions', which is a list of recipe objects. 
Each recipe object must have a 'name' (string) and a list of 'ingredients' (list of objects, each with 'name' and 'quantity' as strings).
You MUST only output the JSON object, with no other text.
""";