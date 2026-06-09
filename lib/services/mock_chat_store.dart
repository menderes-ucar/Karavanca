
import '../models/chat_model.dart';

class MockChatStore {
  MockChatStore._();
  static final I = MockChatStore._();

  // Demo sohbet listesi
  final List<ChatThread> threads = [
    ChatThread(
      id: 't1',
      title: 'Ahmet (Karavan Satıcısı)',
      avatarUrl: '',
      lastMessage: 'Tamam kanka, fiyat son 780k.',
      lastAt: DateTime.now().subtract(const Duration(minutes: 12)),
      unread: 2,
    ),
    ChatThread(
      id: 't2',
      title: 'Zeynep (Kiralık Karavan)',
      avatarUrl: '',
      lastMessage: 'Hafta sonu müsait, tarih netleşince yaz.',
      lastAt: DateTime.now().subtract(const Duration(hours: 3)),
      unread: 0,
    ),
    ChatThread(
      id: 't3',
      title: 'Kamp Grubu: Ağva',
      avatarUrl: '',
      lastMessage: 'Yola çıkan var mı?',
      lastAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      unread: 5,
    ),
  ];

  // Mesajlar (threadId -> list)
  final Map<String, List<ChatMessage>> _messages = {
    't1': [
      ChatMessage(
        id: 'm1',
        threadId: 't1',
        senderId: 'other',
        text: 'Selam, ilanı gördüm. Hala satılık mı?',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ChatMessage(
        id: 'm2',
        threadId: 't1',
        senderId: 'me',
        text: 'Evet satılık knk. Detay istersen yaz.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)),
      ),
      ChatMessage(
        id: 'm3',
        threadId: 't1',
        senderId: 'other',
        text: 'Pazarlık var mı?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        id: 'm4',
        threadId: 't1',
        senderId: 'other',
        text: 'Tamam kanka, fiyat son 780k.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    ],
    't2': [
      ChatMessage(
        id: 'm5',
        threadId: 't2',
        senderId: 'me',
        text: 'Merhaba, 2 gece kiralama var mı?',
        createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      ),
      ChatMessage(
        id: 'm6',
        threadId: 't2',
        senderId: 'other',
        text: 'Var, hafta içi daha uygun.',
        createdAt: DateTime.now().subtract(const Duration(hours: 8, minutes: 40)),
      ),
      ChatMessage(
        id: 'm7',
        threadId: 't2',
        senderId: 'other',
        text: 'Hafta sonu müsait, tarih netleşince yaz.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
    't3': [
      ChatMessage(
        id: 'm8',
        threadId: 't3',
        senderId: 'other',
        text: 'Cuma akşamı çıkıyoruz.',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      ),
      ChatMessage(
        id: 'm9',
        threadId: 't3',
        senderId: 'other',
        text: 'Yola çıkan var mı?',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
    ],
  };

  List<ChatMessage> getMessages(String threadId) {
    return List<ChatMessage>.from(_messages[threadId] ?? []);
  }

  void markRead(String threadId) {
    final t = threads.firstWhere((e) => e.id == threadId);
    t.unread = 0;
  }

  void sendMessage(String threadId, String text) {
    final msg = ChatMessage(
      id: 'm${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      senderId: 'me',
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    _messages.putIfAbsent(threadId, () => []);
    _messages[threadId]!.add(msg);

    final t = threads.firstWhere((e) => e.id == threadId);
    t.lastMessage = msg.text;
    t.lastAt = msg.createdAt;
  }
}
