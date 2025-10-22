class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String role; // 'customer' or 'rider'

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.role,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      // Firestore Timestamps need conversion
      timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      role: data['role'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      // Use Firestore's serverTimestamp for consistency if possible, 
      // but passing DateTime is fine for the mock
      'timestamp': timestamp, 
      'role': role,
    };
  }
}