import 'package:flutter_test/flutter_test.dart';
import 'package:suefery/data/enums/message_sender.dart';
import 'package:suefery/data/models/chat_message.dart';
import 'package:suefery/data/services/chat_service.dart';

void main() {
  test('GeminiService should parse a successful response', () async {
    // 1. ARRANGE
    final mockRepo = MockGeminiRepo();
    final service = ChatService(mockRepo);
    final history = [ChatMessage(
      text: 'i need 2 coke and 1 chips', 
      senderType: MessageSender.user, 
      senderId: '', 
      timestamp: DateTime.now()
      )];

    // 2. ACT
    final aiResponse = await service.getAiOrderResponse(history);

    // 3. ASSERT
    expect(aiResponse.aiResponseText, contains('Mock response'));
    expect(aiResponse.parsedOrder.orderConfirmed, true);
    expect(aiResponse.parsedOrder.requestedItems.length, 2);
    expect(aiResponse.parsedOrder.requestedItems[0].itemName, 'Coca-Cola');
  });

  test('GeminiService should handle a failure response', () async {
    // 1. ARRANGE
    final mockRepo = MockGeminiFailureRepo();
    final service = ChatService(mockRepo);
    final history = [ChatMessage(
      text: 'hi', 
      senderType: MessageSender.user, 
      senderId: '', 
      timestamp: DateTime.now()
      )];

    // 2. ACT
    final aiResponse = await service.getAiOrderResponse(history);

    // 3. ASSERT
    expect(aiResponse.aiResponseText, contains('Sorry, I\'m having trouble'));
    expect(aiResponse.parsedOrder.orderConfirmed, false);
    expect(aiResponse.parsedOrder.requestedItems.isEmpty, true);
  });
}


