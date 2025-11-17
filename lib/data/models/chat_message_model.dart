import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:suefery/data/enums/chat_message_type.dart';
import 'package:suefery/data/enums/message_sender.dart';

import 'ai_parsed_order.dart';

/// The definitive model for a single message in the chat collection.
class ChatMessageModel extends Equatable {
  final String id;
  final String senderId;
  final MessageSender senderType;
  final DateTime timestamp;
  final ChatMessageType messageType;
  final String? content; // For text messages
  final String? mediaUrl; // For video messages
  final List<String>? choices;

  // Data fields for special message types
  final AiParsedOrder? parsedOrder;
  final String? recipeName;
  final List<String>? recipeIngredients;
  
  // Fields for tracking bubble state
  final bool isActioned;
  final String? actionStatus;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.timestamp,
    this.messageType = ChatMessageType.text,
    this.content,
    this.parsedOrder,
    this.recipeName,
    this.recipeIngredients,
    this.isActioned = false,
    this.actionStatus,
    this.mediaUrl,
    this.choices,
  });

  @override
  List<Object?> get props => [id, timestamp, messageType, isActioned, actionStatus];

  /// Creates an empty chat message.
  factory ChatMessageModel.empty() {
    return ChatMessageModel(
      id: '',
      senderId: '',
      senderType: MessageSender.system,
      timestamp: DateTime(0),
    );
  }
  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      senderType: MessageSender.values
          .firstWhere((e) => e.name == map['senderType'], orElse: () => MessageSender.system),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      messageType: ChatMessageType.values
          .firstWhere((e) => e.name == map['messageType'], orElse: () => ChatMessageType.text),
      content: map['content'] as String?,
      parsedOrder: map['parsedOrderData'] != null
          ? AiParsedOrder.fromMap(map['parsedOrderData'])
          : null,
      recipeName: map['recipeName'] as String?,
      recipeIngredients: (map['recipeIngredients'] as List?)?.cast<String>(),
      isActioned: map['isActioned'] as bool? ?? false,
      actionStatus: map['actionStatus'] as String?,
      mediaUrl: map['mediaUrl'] as String?,
      choices: (map['choices'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderType': senderType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType.name,
      'content': content,
      // Store the parsed order as a nested map
      'parsedOrderData': parsedOrder != null 
          ? {
              'items': parsedOrder!.requestedItems.map((e) => {
                'itemName': e.itemName,
                'quantity': e.quantity,
              }).toList(),
              'aiResponseText': parsedOrder!.aiResponseText,
            }
          : null,
      'recipeName': recipeName,
      'recipeIngredients': recipeIngredients,
      'isActioned': isActioned,
      'actionStatus': actionStatus,
      'mediaUrl': mediaUrl,
      'choices': choices,
    };
  }
  
  // for cubit
  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    MessageSender? senderType,
    DateTime? timestamp,
    ChatMessageType? messageType,
    String? content,
    AiParsedOrder? parsedOrder,
    String? recipeName,
    List<String>? recipeIngredients,
    bool? isActioned,
    String? actionStatus,
    String? mediaUrl,
    List<String>? choices,
  }) {
    return ChatMessageModel(
      id: this.id,
      senderId: this.senderId,
      senderType: this.senderType,
      timestamp: this.timestamp,
      messageType: this.messageType,
      content: this.content,
      parsedOrder: parsedOrder ?? this.parsedOrder,
      recipeName: this.recipeName,
      recipeIngredients: this.recipeIngredients,
      isActioned: isActioned ?? this.isActioned,
      actionStatus: actionStatus ?? this.actionStatus,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      choices: choices ?? this.choices,
    );
  }
}