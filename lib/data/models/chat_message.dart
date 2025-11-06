import 'package:cloud_firestore/cloud_firestore.dart';

import 'ai_response.dart';
import '../enums/chat_message_type.dart';
import '../enums/message_sender.dart';

class ChatMessage {
  final String id;
  final MessageSender senderType;
  final String senderId;
  final String text;
  final DateTime timestamp;

  final ChatMessageType messageType;
  final String? recipeName;
  final List<String>? recipeIngredients;
  final AiParsedOrder? parsedOrder;
  final bool isActioned;
  final String? actionStatus;
  final String? orderId;
  
  ChatMessage({
    required this.id,
    required this.senderType,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.messageType = ChatMessageType.text, 
    this.recipeName,
    this.recipeIngredients,
    this.parsedOrder,
    this.isActioned = false,
    this.actionStatus,
    this.orderId,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    
    // Helper function to safely parse Firebase Timestamps or other date formats
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      // This is a basic mock. A real app would check `timestamp is Timestamp`
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }

      if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      // Fallback for DateTime objects
      return timestamp as DateTime;
    }

    return ChatMessage(
      id: data['id'] ?? '',
      senderId: data['senderId'] != null ? data['senderId'] as String : 'unknown_sender',
      text: data['text']  != null ? data['text'] as String : '',
      senderType: MessageSender.values.firstWhere(
        (e) => e.name == data['senderType'],
        orElse: () => MessageSender.system, // Default fallback
      ) ,
      timestamp: parseTimestamp(data['timestamp']),
      messageType: ChatMessageType.values.firstWhere(
        (e) => e.name == data['messageType'],
        orElse: () => ChatMessageType.text, // Default to text if not found
      ),
      recipeName: data['recipeName'],
      recipeIngredients: data['recipeIngredients'] != null
          ? List<String>.from(data['recipeIngredients'])
          : null,
      parsedOrder: data['parsedOrder'] != null
          ? AiParsedOrder.fromMap(data['parsedOrder'])
          : null,
      isActioned: data['isActioned'] ?? false,
      actionStatus: data['actionStatus'],
      orderId: data['orderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderType': senderType.name,
      'senderId': senderId,
      'text': text,
      // Use Firestore's serverTimestamp for consistency if possible, 
      // but passing DateTime is fine for the mock
      'timestamp': Timestamp.fromDate(timestamp), 
      'messageType': messageType.name, // Save enum as a string
      'recipeName': recipeName,
      'recipeIngredients': recipeIngredients,
      'parsedOrder': parsedOrder?.toMap(),
      'isActioned': isActioned,
      'actionStatus': actionStatus,
      'orderId': orderId,
    };
  }

  ChatMessage copyWith({
    String? id,
    MessageSender? senderType,
    String? senderId,
    String? text,
    DateTime? timestamp,
    ChatMessageType? messageType,
    String? recipeName,
    List<String>? recipeIngredients,
    AiParsedOrder? parsedOrder,
    bool? isActioned,
    String? actionStatus,
    String? orderId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderType: senderType ?? this.senderType,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      recipeName: recipeName ?? this.recipeName,
      recipeIngredients: recipeIngredients ?? this.recipeIngredients,
      parsedOrder: parsedOrder ?? this.parsedOrder,
      isActioned: isActioned ?? this.isActioned,
      actionStatus: actionStatus ?? this.actionStatus,
      orderId: orderId ?? this.orderId,
    );
  }
}