import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/models.dart';

// --- Events ---
sealed class ChatEvent {
  const ChatEvent();
}

class LoadChat extends ChatEvent {
  final int orderId;
  const LoadChat(this.orderId);
}

class SendMessage extends ChatEvent {
  final int orderId;
  final String text;
  final String senderId;
  const SendMessage(this.orderId, this.text, this.senderId);
}

class _UpdateChat extends ChatEvent {
  final List<ChatMessage> messages;
  const _UpdateChat(this.messages);
}

// --- State ---
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final int? currentOrderId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.currentOrderId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    int? currentOrderId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentOrderId: currentOrderId ?? this.currentOrderId,
    );
  }
}

// --- BLoC ---
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot>? _chatSubscription; // Use StreamSubscription
  
  // Path Structure: /artifacts/{appId}/public/data/chats/{orderId}/messages/{messageId}
  static const String _basePath = 'artifacts/default-app-id/public/data/chats';

  ChatBloc(this._firestore, String currentUserId) : 
    super(const ChatState(isLoading: false)) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<_UpdateChat>(_onUpdateChat);
  }

  void _onLoadChat(LoadChat event, Emitter<ChatState> emit) {
    // Cancel previous listener if any
    _chatSubscription?.cancel();
    
    emit(state.copyWith(isLoading: true, currentOrderId: event.orderId));

    final chatId = event.orderId.toString();
    final chatCollectionPath = '$_basePath/$chatId/messages'; 

    final messagesCollection = _firestore.collection(chatCollectionPath);

    // Set up real-time listener
    _chatSubscription = messagesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          final messages = snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.data() as Map<String, dynamic>);
          }).toList().reversed.toList(); // Reverse to display chronologically

          add(_UpdateChat(messages));
        });
  }

  void _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (event.text.trim().isEmpty) return;

    final chatId = event.orderId.toString();
    final chatCollectionPath = '$_basePath/$chatId/messages'; 
    final messagesCollection = _firestore.collection(chatCollectionPath);

    final newMessage = ChatMessage(
      senderId: event.senderId,
      text: event.text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await messagesCollection.add(newMessage.toMap());
    } catch (e) {
      print('Error sending message: $e'); 
    }
  }

  void _onUpdateChat(_UpdateChat event, Emitter<ChatState> emit) {
    emit(state.copyWith(messages: event.messages, isLoading: false));
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
