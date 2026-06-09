class ChatThread {
  final String id;
  final String title;
  final String avatarUrl; // boş bırakabilirsin
  String lastMessage;
  DateTime lastAt;
  int unread;

  ChatThread({
    required this.id,
    required this.title,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastAt,
    this.unread = 0,
  });
}

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId; // "me" / "other"
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  bool get isMe => senderId == 'me';
}
