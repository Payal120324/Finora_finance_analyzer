class ChatbotMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String status; // e.g., 'sent', 'delivered', 'read'

  ChatbotMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.status = 'sent',
  }) : timestamp = timestamp ?? DateTime.now();
}
