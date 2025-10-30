
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/data/services/firebase_service.dart';

import '../../data/models/chat_message.dart';
import '../../data/services/gemini_service.dart';

class HomeState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool geminiIsLoading;
  final bool geminiIsSuccessful;
  final int? currentOrderId;

  const HomeState({
    this.messages = const [],
    this.isLoading = false,
    this.geminiIsLoading = false,
    this.geminiIsSuccessful = false,
    this.currentOrderId,
  });

  HomeState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? geminiIsLoading,
    bool? geminiIsSuccessful,
    int? currentOrderId,
  }) {
    return HomeState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      geminiIsLoading: geminiIsLoading ?? this.geminiIsLoading,
      geminiIsSuccessful: geminiIsSuccessful ?? this.geminiIsSuccessful,
      currentOrderId: currentOrderId ?? this.currentOrderId,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this.firebaseService,this.geminiService,this.currentUserId) : super(HomeState());
  // Path Structure: /artifacts/{appId}/public/data/chats/{orderId}/messages/{messageId}
  static const String _basePath = 'artifacts/default-app-id/public/data/chats';
  final FirebaseService firebaseService;
  final GeminiService geminiService;
  final String currentUserId;
  StreamSubscription<QuerySnapshot>? _chatSubscription; // Use StreamSubscription

  Future<void> submitOrder(String prompt) async {
    emit(state.copyWith(
      isLoading: true,
    ));
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    // S1 Logic: Mock successful conversion
    final Map<String, dynamic> mockOrder = {
      'partner': 'University Mini-Mart',
      'items': [
        {'name': 'Water', 'qty': 2, 'price': 10},
        {'name': 'Chips', 'qty': 1, 'price': 15},
      ],
      'total': 35.0,
      'notes': prompt,
    };
  }

  @visibleForTesting
  Future<void> submitOrderMock(String prompt) async {
    emit(state.copyWith(
      isLoading: true,
    ));
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    // S1 Logic: Mock successful conversion
    final Map<String, dynamic> mockOrder = {
      'partner': 'University Mini-Mart',
      'items': [
        {'name': 'Water', 'qty': 2, 'price': 10},
        {'name': 'Chips', 'qty': 1, 'price': 15},
      ],
      'total': 35.0,
      'notes': prompt,
    };
    emit(state.copyWith(
      isLoading: true,
    ));
  }

  void loadChat(int orderId) {
    // Cancel previous listener if any
    _chatSubscription?.cancel();
    
    emit(state.copyWith(isLoading: true, currentOrderId: orderId));

    final chatId = orderId.toString();
    final chatCollectionPath = '$_basePath/$chatId/messages'; 

    final messagesCollection = firebaseService.firestore.collection(chatCollectionPath);

    // Set up real-time listener
    _chatSubscription = messagesCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          final messages = snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.data() as Map<String, dynamic>);
          }).toList().reversed.toList(); // Reverse to display chronologically

          updateChat(messages);
        });
  }

  void sendMessage(ChatMessage message) async {
    if (message.text.trim().isEmpty) return;

    final chatId = "";//message.orderId.toString();
    final chatCollectionPath = '$_basePath/$chatId/messages'; 
    final messagesCollection = firebaseService.firestore.collection(chatCollectionPath);

    final newMessage = ChatMessage(
      senderId: message.senderId,
      text: message.text.trim(),
      timestamp: DateTime.now(), 
      senderType: 'user',
    );

    try {
      await messagesCollection.add(newMessage.toMap());
    } catch (e) {
      print('Error sending message: $e'); 
    }
  }

  void updateChat(List<ChatMessage> messages) {
    emit(state.copyWith(messages: messages, isLoading: false));
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}