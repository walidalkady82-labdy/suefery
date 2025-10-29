import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:suefery/data/enums/order_status.dart';
import '../models/models.dart';

// IMPORTANT: This API key must be blank for the Canvas environment to provide the token.
const String apiKey = ""; 
const String apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$apiKey";

class GeminiService {
  final String systemPrompt = """
    You are the **Suefery** AI Shopping Assistant for a delivery service operating in Beni Suef, Egypt. 
    Your role is to process user messages, extract a confirmed order list, and present it back to the user for confirmation. 
    
    1. CONVERSATION: If the user is just chatting or asking general questions, respond naturally (set confirmed=false).
    2. ORDER PARSING: If the user expresses a clear intent to order items, parse the request into a list of items with quantities and notes.
    3. JSON OUTPUT: ALWAYS respond with a JSON object containing two keys:
        - "ai_response_text": A friendly, localized conversational response to the user.
        - "parsed_order": An object matching the ParsedOrder structure.
        
    ParsedOrder JSON Structure:
    {
      "order_confirmed": true | false,
      "requested_items": [
        { "item_name": "string", "quantity": number, "notes": "string (e.g., brand, size, color)" }
      ]
    }
    
    If the user's intent is clear enough to form an order, set "order_confirmed" to true.
    
    Example for "I need 2 bottles of large coke and 1 bag of Lays chips, spicy flavor":
    
    {
      "ai_response_text": "Great! I've prepared your Suefery order for confirmation. You requested 2 items: 2 large Cokes and 1 bag of spicy Lays chips. Does this look correct?",
      "parsed_order": {
        "order_confirmed": true,
        "requested_items": [
          { "item_name": "Large Coca-Cola bottle", "quantity": 2, "notes": "Large size" },
          { "item_name": "Lays Chips", "quantity": 1, "notes": "Spicy flavor" }
        ]
      }
    }
    """;

  Future<Map<String, dynamic>> callGemini(List<ChatMessage> history) async {
    final contents = history.map((m) => {
      'role': m.senderType == 'user' ? 'user' : 'model', 
      'parts': [{'text': m.text}]
    }).toList();

    final payload = {
      'contents': contents,
      'systemInstruction': { 'parts': [{'text': systemPrompt}] },
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'ai_response_text': {'type': 'STRING', 'description': 'A friendly, conversational response to the user.'},
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
      }
    };

    try {
      final http.Response response = await fetchWithRetry(apiUrl, {
        'method': 'POST',
        'headers': {'Content-Type': 'application/json'},
        'body': jsonEncode(payload),
      });

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final jsonText = result['candidates']?[0]['content']?['parts']?[0]?['text'];
        if (jsonText != null) {
          return jsonDecode(jsonText);
        }
      }
      return {'ai_response_text': 'Error: Failed to get response from AI.', 'parsed_order': {'order_confirmed': false, 'requested_items': []}};
    } catch (e) {
      debugPrint('API Error: $e');
      return {'ai_response_text': 'Error: Network or API issue.', 'parsed_order': {'order_confirmed': false, 'requested_items': []}};
    }
  }

  // Helper function to process the raw JSON output into a ParsedOrder model
  StructuredOrder parseGeminiResponse(Map<String, dynamic> jsonResponse) {
    final parsedOrderJson = jsonResponse['parsed_order'] ?? {};
    final confirmed = parsedOrderJson['order_confirmed'] ?? false;
    final itemsList = parsedOrderJson['requested_items'] as List<dynamic>? ?? [];

    final List<OrderItem> orderItems = itemsList.map((itemJson) {
      return OrderItem(
        itemId: '',
        name: itemJson['item_name'] ?? 'Unknown Item',
        quantity: itemJson['quantity'] is int ? itemJson['quantity'] : int.tryParse(itemJson['quantity'].toString()) ?? 1,
        unitPrice: itemJson['unitPrice'] is int ? itemJson['unitPrice'] : int.tryParse(itemJson['unitPrice'].toString()) ?? 1,
        notes: itemJson['notes'] ?? '',
      );
    }).toList();
    double totalPrice = orderItems.fold(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );
    return StructuredOrder(
      orderId: '',
      customerId: '', 
      partnerId: '',
      // orderConfirmed: confirmed, 
      // requestedItems: items,  
      estimatedTotal: totalPrice, 
      deliveryFee: 0, 
      deliveryAddress: '', 
      status: OrderStatus.Assigned, 
      progress: null, 
      riderId: '', 
      items: []
    );
  }

  // Simple fetch retry mechanism (implementation omitted for brevity in file block)
  Future<http.Response> fetchWithRetry(
    String url,
    Map<String, dynamic> options, {
    int retries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final uri = Uri.parse(url);
        final headers = (options['headers'] as Map<String, String>?) ?? {};
        final body = options['body'];

        final response = await http.post(
          uri,
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 15));

        // Success, or a client error that shouldn't be retried (e.g., 400 Bad Request)
        if (response.statusCode < 500 && response.statusCode != 429) {
          return response;
        }
        
        debugPrint('Attempt ${i + 1} failed with status ${response.statusCode}. Retrying in ${delay.inSeconds}s...');
      } catch (e) {
        debugPrint('Attempt ${i + 1} failed with exception: $e. Retrying in ${delay.inSeconds}s...');
      }
      
      // Wait before the next retry
      await Future.delayed(delay);
    }
    // If all retries fail, throw an exception.
    throw Exception('Failed to fetch data from $url after $retries retries.');
  }
}
