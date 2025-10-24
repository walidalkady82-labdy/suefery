import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_localizations.dart';

class ConversationalOrderingScreen extends StatefulWidget {
  const ConversationalOrderingScreen({super.key});

  @override
  State<ConversationalOrderingScreen> createState() => _ConversationalOrderingScreenState();
}

class _ConversationalOrderingScreenState extends State<ConversationalOrderingScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Mock message structure
  final List<Map<String, dynamic>> _messages = [
    {
      'type': 'system',
      'content': 'Hi! I\'m your SUEFERY Assistant. Just tell me what you need, for example: "I need 2 bottles of water and a pack of chewing gum."',
    },
  ];

  // --- MOCK GEMINI API CALL ---
  // This simulates the core S1 functionality:
  // converting natural language into a structured JSON order.
  Future<Map<String, dynamic>> _processOrderWithGemini(String prompt) async {
    // Simulate network latency
    await Future.delayed(const Duration(seconds: 2));

    // Simple mock logic to return a structured response based on input
    String structuredOrderJson;
    String statusMessage;

    if (prompt.toLowerCase().contains('water') && prompt.toLowerCase().contains('gum')) {
      structuredOrderJson = jsonEncode({
        'items': [
          {'name': 'Water Bottle (1L)', 'quantity': 2},
          {'name': 'Chewing Gum (Pack)', 'quantity': 1},
        ],
        'shop': 'University Mini-Mart',
        'estimated_cost_egp': 65.00,
      });
      statusMessage = 'Order structured successfully. Review the items below.';
    } else if (prompt.toLowerCase().contains('battery') || prompt.toLowerCase().contains('charger')) {
       structuredOrderJson = jsonEncode({
        'items': [
          {'name': 'AA Batteries (4 Pack)', 'quantity': 1},
        ],
        'shop': 'Technology Express',
        'estimated_cost_egp': 120.00,
      });
      statusMessage = 'Found essential tech item. Please confirm the details.';
    }
     else {
      structuredOrderJson = jsonEncode({'error': 'Item not clearly identified or out of stock in pilot zone.'});
      statusMessage = 'Sorry, I couldn\'t find that. Can you be more specific?';
    }

    return {
      'text': statusMessage,
      'structured_order': structuredOrderJson,
    };
  }

  // --- SEND MESSAGE HANDLER ---
  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 1. Add User Message
    setState(() {
      _messages.add({'type': 'user', 'content': text});
      _textController.clear();
      _isLoading = true;
    });

    // Scroll to bottom after adding user message
    _scrollToBottom();

    try {
      // 2. Process with Mock Gemini
      final geminiResponse = await _processOrderWithGemini(text);

      // 3. Add System Response (Text + Structured Order)
      setState(() {
        _messages.add({
          'type': 'system',
          'content': geminiResponse['text'],
          'structured_order': geminiResponse['structured_order'],
        });
      });
    } catch (e) {
      // Handle API failure
      setState(() {
        _messages.add({
          'type': 'system',
          'content': 'Error: Could not connect to the ordering service.',
          'structured_order': jsonEncode({'error': e.toString()}),
        });
      });
    } finally {
      // 4. Update loading state and scroll
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Use a slight delay to ensure the ListView has finished rendering the new item
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- WIDGET BUILDER: Single Message Bubble ---
  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['type'] == 'user';
    final content = message['content'] as String;
    final structuredOrder = message['structured_order'] as String?;

    // Determine colors and alignment
    final color = isUser ? const Color(0xFF673AB7) : const Color(0xFF3A3A3A);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final margin = isUser ? const EdgeInsets.only(left: 60) : const EdgeInsets.only(right: 60);

    // Parse the structured order for display
    Map<String, dynamic>? orderData;
    if (structuredOrder != null) {
      try {
        orderData = jsonDecode(structuredOrder);
      } catch (_) {
        orderData = null; // Could not decode JSON
      }
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: margin.copyWith(top: 8, bottom: 8, left: isUser ? 60 : 12, right: isUser ? 12 : 60),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the main conversational text
            Text(
              content,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            // Display the structured order if available (S1 value)
            if (orderData != null && orderData.containsKey('items') && orderData['items'] is List)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Color(0xFFE91E63), height: 16, thickness: 1),
                    Text(
                      'AI Structured Order:',
                      style: TextStyle(color: Colors.yellow[700], fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    ...?orderData['items']?.map<Widget>((item) => Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '• ${item['quantity']}x ${item['name']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    )).toList(),
                    if (orderData.containsKey('shop'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'From: ${orderData['shop']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    if (orderData.containsKey('estimated_cost_egp'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Est. Cost: EGP ${orderData['estimated_cost_egp'].toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            if (orderData != null && orderData.containsKey('error'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Error: ${orderData['error']}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER: MAIN ---
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.customerTitle,    //'SUEFERY Q-Commerce Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFFE91E63)),
            onPressed: () {
              // Mock action: show info about S1 feature
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Text('Date: ${s.formatDate(DateTime.now())}'),
          // 1. Message History (Chat Bubbles)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          
          // 2. Input/Send Bar
          Container(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16, top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  // Text Input Field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (text) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Type your order or describe your need...',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  
                  // Send/Mic Button
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: FloatingActionButton(
                      onPressed: _isLoading ? null : _handleSend,
                      backgroundColor: _isLoading ? Colors.grey : const Color(0xFFE91E63),
                      elevation: 0,
                      mini: true,
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
