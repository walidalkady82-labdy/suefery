import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/chat_message_type.dart';
import '../enums/message_sender.dart';

class ChatMessage {
  final MessageSender senderType;
  final String senderId;
  final String text;
  final DateTime timestamp;

  final ChatMessageType messageType;
  final String? recipeName;
  final List<String>? recipeIngredients;
  
  ChatMessage({
    required this.senderType,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.messageType = ChatMessageType.text, 
    this.recipeName,
    this.recipeIngredients,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    // Helper function to safely parse Firebase Timestamps or other date formats
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      // This is a basic mock. A real app would check `timestamp is Timestamp`
      // from the `cloud_firestore` package and call `timestamp.toDate()`.
      if (timestamp is Map && timestamp.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000);
      }
      if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      // Fallback for DateTime objects
      return timestamp as DateTime;
    }

    return ChatMessage(
      senderId: data['senderId'] as String? ?? 'unknown_sender',
      text: data['text'] as String? ?? '',
      senderType: MessageSender.values.firstWhere(
        (e) => e.name == data['senderType'],
        orElse: () => MessageSender.system, // Default fallback
      ),
      timestamp: parseTimestamp(data['timestamp']),
      messageType: ChatMessageType.values.firstWhere(
        (e) => e.name == data['messageType'],
        orElse: () => ChatMessageType.text, // Default to text if not found
      ),
      recipeName: data['recipeName'],
      recipeIngredients: data['recipeIngredients'] != null
          ? List<String>.from(data['recipeIngredients'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderType': senderType,
      'senderId': senderId,
      'text': text,
      // Use Firestore's serverTimestamp for consistency if possible, 
      // but passing DateTime is fine for the mock
      'timestamp': Timestamp.fromDate(timestamp), 
      'messageType': messageType.name, // Save enum as a string
      'recipeName': recipeName,
      'recipeIngredients': recipeIngredients,
    };
  }
}