import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_config.dart';
import '../../models/product_model.dart';
import '../../services/chat_push_service.dart';
import '../../services/credit_service.dart';
import '../../services/ugc_moderation_service.dart';
import '../../widgets/ugc_action_sheet.dart';

class ProductChatPage extends StatefulWidget {
  final ProductModel product;
  final String? threadId;

  const ProductChatPage({
    super.key,
    required this.product,
    this.threadId,
  });

  @override
  State<ProductChatPage> createState() => _ProductChatPageState();
}

class _ProductChatPageState extends State<ProductChatPage> {
  final sb = Supabase.instance.client;
  final _creditService = CreditService();

  final ctrl = TextEditingController();
  final listCtrl = ScrollController();

  bool loading = true;
  String? tid;
  String? _buyerIdFromThread;
  String? errorText;
  bool _blocked = false;

  RealtimeChannel? chan;
  final List<_Msg> msgs = [];

  String get me => sb.auth.currentUser!.id;
  String get sellerId => widget.product.ownerId;

  static const Color kBg = Color(0xFFF3F6F6);
  static const Color kDark = Color(0xFF06343A);
  static const Color kMine = Color(0xFF0F766E);
  static const Color kOther = Colors.white;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    ctrl.dispose();
    listCtrl.dispose();
    chan?.unsubscribe();
    super.dispose();
  }

  // ✅ Kredi yetersizse gösterilecek dialog
  Future<void> _showInsufficientCreditsDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yetersiz Kredi"),
        content: Text(
          "Bu satıcıyla yeni bir sohbet başlatmak için ${CreditService.messageThreadCost} "
              "kredi gerekiyor. Mevcut kredin yetersiz görünüyor. Profil sayfandan kredi "
              "yükleyebilirsin.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  Future<void> _boot() async {
    setState(() {
      loading = true;
      errorText = null;
    });

    try {
      final uid = sb.auth.currentUser?.id;
      if (uid == null) throw "Giriş yapmalısın.";

      final incomingTid = widget.threadId?.trim();

      if (incomingTid != null && incomingTid.isNotEmpty) {
        tid = incomingTid;

        final thread = await sb
            .from('chat_threads')
            .select('buyer_id, seller_id')
            .eq('id', incomingTid)
            .maybeSingle();

        _buyerIdFromThread = thread?['buyer_id']?.toString();
      } else {
        final sId = sellerId.trim();
        if (sId.isEmpty) throw "Satıcı ID boş geliyor.";

        if (uid == sId) {
          throw "Kendi ürününe mesaj atamazsın.";
        }

        final bId = uid;

        final existing = await sb
            .from('chat_threads')
            .select('id')
            .eq('product_id', widget.product.id)
            .eq('seller_id', sId)
            .eq('buyer_id', bId)
            .maybeSingle();

        if (existing != null) {
          // ✅ Var olan sohbet -> kredi harcanmaz
          tid = existing['id'].toString();
        } else {
          // ✅ Yeni sohbet açılacak -> Sistem aktifse kredi kontrolü
          if (AppConfig.isCreditSystemActive) {
            final hasCredits = await _creditService.hasEnoughCredits(CreditService.messageThreadCost);
            if (!hasCredits) {
              if (!mounted) return;
              setState(() => loading = false);
              _showInsufficientCreditsDialog();
              Navigator.pop(context);
              return;
            }
          }

          final inserted = await sb.from('chat_threads').insert({
            'product_id': widget.product.id,
            'seller_id': sId,
            'buyer_id': bId,
            'user_a': bId,
            'user_b': sId,
            'title': widget.product.title,
            'last_message': null,
            'updated_at': DateTime.now().toIso8601String(),
          }).select('id').single();

          final newTid = inserted['id'].toString();

          // ✅ Sohbet oluşturulduktan sonra Sistem aktifse kredi düş
          if (AppConfig.isCreditSystemActive) {
            try {
              await _creditService.deductForMessage(referenceId: newTid);
            } catch (e) {
              await sb.from('chat_threads').delete().eq('id', newTid);
              if (e is InsufficientCreditsException) {
                if (!mounted) return;
                setState(() => loading = false);
                _showInsufficientCreditsDialog();
                Navigator.pop(context);
                return;
              }
              rethrow;
            }
          }

          tid = newTid;
        }
      }

      final otherUserId = uid == sellerId ? _buyerIdFromThread : sellerId;
      if (otherUserId != null && otherUserId.isNotEmpty) {
        _blocked = await UgcModerationService.instance.isBlocked(otherUserId);
        if (_blocked) {
          if (!mounted) return;
          setState(() { loading = false; errorText = 'Bu kullanıcı engellendi. Sohbet gösterilmiyor.'; });
          return;
        }
      }

      await _loadMessages();
      _subscribe();

      if (!mounted) return;
      setState(() => loading = false);
      _scrollBottom(delayMs: 150);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorText = e.toString();
      });
    }
  }

  Future<void> _loadMessages() async {
    final threadId = tid;
    if (threadId == null) return;

    final data = await sb
        .from('chat_messages')
        .select('id, sender_id, text, created_at')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);

    msgs
      ..clear()
      ..addAll(
        (data as List).cast<Map<String, dynamic>>().map(
              (r) => _Msg(
            id: r['id'].toString(),
            senderId: r['sender_id'].toString(),
            text: (r['text'] ?? '').toString(),
            createdAt: DateTime.tryParse((r['created_at'] ?? '').toString()),
          ),
        ),
      );
  }

  void _subscribe() {
    final threadId = tid;
    if (threadId == null) return;

    chan?.unsubscribe();
    chan = sb.channel("chat-$threadId");

    chan!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'thread_id',
        value: threadId,
      ),
      callback: (payload) {
        final row = payload.newRecord;
        if (row.isEmpty) return;

        final m = _Msg(
          id: row['id'].toString(),
          senderId: row['sender_id'].toString(),
          text: (row['text'] ?? '').toString(),
          createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()),
        );

        if (msgs.any((x) => x.id == m.id)) return;
        if (!mounted) return;

        setState(() => msgs.add(m));
        _scrollBottom(delayMs: 60);
      },
    )
        .subscribe();
  }

  Future<void> _send() async {
    final threadId = tid;
    if (threadId == null) return;

    final t = ctrl.text.trim();
    if (t.isEmpty) return;

    if (UgcModerationService.instance.containsObjectionableContent(t)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu mesaj topluluk kurallarına aykırı içerik içeriyor.')));
      return;
    }

    ctrl.clear();

    try {
      final row = await sb.from('chat_messages').insert({
        'thread_id': threadId,
        'sender_id': me,
        'text': t,
      }).select('id, sender_id, text, created_at').single();

      final m = _Msg(
        id: row['id'].toString(),
        senderId: row['sender_id'].toString(),
        text: (row['text'] ?? '').toString(),
        createdAt: DateTime.tryParse((row['created_at'] ?? '').toString()),
      );

      if (mounted) {
        setState(() => msgs.add(m));
        _scrollBottom(delayMs: 60);
      }

      await sb.from('chat_threads').update({
        'last_message': t,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', threadId);

      final receiverId = me == sellerId ? _buyerIdFromThread : sellerId;

      if (receiverId != null &&
          receiverId.trim().isNotEmpty &&
          receiverId != me) {
        try {
          await ChatPushService().sendMessagePush(
            receiverUserId: receiverId,
            title: 'Yeni mesajın var 💬',
            body: t,
            threadId: threadId,
            itemId: widget.product.id,
            type: 'product_chat',
          );
        } catch (pushError) {
          debugPrint('❌ Mesaj push gönderilemedi: $pushError');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesaj gönderilemedi: $e")),
      );
    }
  }

  String? get _otherUserId {
    final current = sb.auth.currentUser?.id;
    if (current == null) return null;
    return current == sellerId ? _buyerIdFromThread : sellerId;
  }

  Future<void> _reportOtherUser() async {
    final other = _otherUserId;
    if (other == null || other.isEmpty) return;
    await UgcActionSheet.report(context: context, contentType: 'user', contentId: other, reportedUserId: other, title: 'Kullanıcıyı Şikayet Et');
  }

  Future<void> _blockOtherUser() async {
    final other = _otherUserId;
    if (other == null || other.isEmpty) return;
    final ok = await UgcActionSheet.block(context: context, userId: other, userLabel: widget.product.sellerName.isEmpty ? 'Kullanıcı' : widget.product.sellerName);
    if (ok && mounted) {
      setState(() { _blocked = true; msgs.clear(); errorText = 'Bu kullanıcı engellendi. Sohbet gösterilmiyor.'; });
    }
  }

  Future<void> _deleteMsg(_Msg m) async {
    try {
      if (m.senderId != me) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sadece kendi mesajını silebilirsin.")),
        );
        return;
      }

      await sb.from('chat_messages').delete().eq('id', m.id);

      if (!mounted) return;
      setState(() => msgs.removeWhere((x) => x.id == m.id));

      await _refreshThreadMeta();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silinemedi: $e")),
      );
    }
  }

  Future<void> _refreshThreadMeta() async {
    final threadId = tid;
    if (threadId == null) return;

    final last = await sb
        .from('chat_messages')
        .select('text, created_at')
        .eq('thread_id', threadId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    await sb.from('chat_threads').update({
      'last_message': last?['text']?.toString(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', threadId);
  }

  void _scrollBottom({int delayMs = 0}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (!listCtrl.hasClients) return;
      listCtrl.animateTo(
        listCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _time(DateTime? dt) {
    if (dt == null) return "";
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    final sellerName =
    widget.product.sellerName.isEmpty ? "Satıcı" : widget.product.sellerName;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(.16),
              child: const Icon(Icons.storefront, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    widget.product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') _reportOtherUser();
              if (value == 'block') _blockOtherUser();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('Kullanıcıyı Şikayet Et')),
              PopupMenuItem(value: 'block', child: Text('Kullanıcıyı Engelle')),
            ],
          ),
          IconButton(onPressed: _boot, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorText != null
          ? _ErrorState(text: errorText!, onRetry: _boot)
          : Column(
        children: [
          Expanded(
            child: msgs.isEmpty
                ? const _EmptyState()
                : ListView.builder(
              controller: listCtrl,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              itemCount: msgs.length,
              itemBuilder: (context, i) {
                final m = msgs[i];
                final isMe = m.senderId == me;

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: isMe
                        ? () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Mesaj silinsin mi?"),
                          content: const Text(
                            "Bu işlem geri alınamaz.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("Vazgeç"),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Sil"),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) _deleteMsg(m);
                    }
                        : null,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth:
                        MediaQuery.of(context).size.width * .76,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                      decoration: BoxDecoration(
                        color: isMe ? kMine : kOther,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                        border: Border.all(
                          color: isMe
                              ? Colors.transparent
                              : Colors.black.withOpacity(.06),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            m.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _time(m.createdAt),
                            style: TextStyle(
                              color:
                              isMe ? Colors.white70 : Colors.black45,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_blocked)
            _InputBar(
              controller: ctrl,
              onSend: _send,
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 16,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Mesaj yaz...",
                  filled: true,
                  fillColor: const Color(0xFFF1F5F5),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _ProductChatPageState.kMine,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onSend,
                child: const Padding(
                  padding: EdgeInsets.all(13),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "Henüz mesaj yok.\nİlk mesajı göndererek sohbeti başlat.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.text,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 46, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: const Text("Tekrar dene"),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  _Msg({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });
}