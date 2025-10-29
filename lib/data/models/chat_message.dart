class ChatMessage {
  final String senderType;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.senderType,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      senderType: data['senderType'] as String,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      // Firestore Timestamps need conversion
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderType': senderType,
      'senderId': senderId,
      'text': text,
      // Use Firestore's serverTimestamp for consistency if possible, 
      // but passing DateTime is fine for the mock
      'timestamp': timestamp, 
    };
  }
}