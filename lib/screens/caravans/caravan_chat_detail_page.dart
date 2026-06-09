import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/chat_push_service.dart';

class CaravanChatDetailPage extends StatefulWidget {
  final String caravanId;
  final String caravanTitle;
  final String sellerId;
  final String sellerName;
  final String? threadId;

  const CaravanChatDetailPage({
    super.key,
    required this.caravanId,
    required this.caravanTitle,
    required this.sellerId,
    required this.sellerName,
    this.threadId,
  });

  @override
  State<CaravanChatDetailPage> createState() => _CaravanChatDetailPageState();
}

class _CaravanChatDetailPageState extends State<CaravanChatDetailPage> {
  final sb = Supabase.instance.client;

  final ctrl = TextEditingController();
  final listCtrl = ScrollController();

  bool loading = true;
  String? tid;
  String? _buyerIdFromThread;
  String? errorText;

  RealtimeChannel? chan;
  final List<_Msg> msgs = [];

  String get me => sb.auth.currentUser!.id;

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
        final sId = widget.sellerId.trim();
        if (sId.isEmpty) throw "Satıcı ID boş geliyor.";

        if (uid == sId) {
          throw "Kendi ilanına mesaj atamazsın.";
        }

        final bId = uid;

        final existing = await sb
            .from('chat_threads')
            .select('id')
            .eq('caravan_id', widget.caravanId)
            .eq('seller_id', sId)
            .eq('buyer_id', bId)
            .maybeSingle();

        if (existing != null) {
          tid = existing['id'].toString();
        } else {
          final inserted = await sb
              .from('chat_threads')
              .insert({
            'caravan_id': widget.caravanId,
            'seller_id': sId,
            'buyer_id': bId,
            'user_a': bId,
            'user_b': sId,
            'title': widget.caravanTitle,
            'updated_at': DateTime.now().toIso8601String(),
            'last_message': null,
          })
              .select('id')
              .single();

          tid = inserted['id'].toString();
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
    chan = sb.channel("caravan-chat-$threadId");

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

      final receiverId =
      me == widget.sellerId ? _buyerIdFromThread : widget.sellerId;

      if (receiverId != null &&
          receiverId.trim().isNotEmpty &&
          receiverId != me) {
        try {
          await ChatPushService().sendMessagePush(
            receiverUserId: receiverId,
            title: 'Yeni karavan mesajın var 🚐',
            body: t,
            threadId: threadId,
            itemId: widget.caravanId,
            type: 'caravan_chat',
          );
        } catch (pushError) {
          debugPrint('❌ Caravan chat push gönderilemedi: $pushError');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Mesaj gönderilemedi: $e")),
      );
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
    widget.sellerName.trim().isEmpty ? "Satıcı" : widget.sellerName;

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
              child: const Icon(Icons.rv_hookup, color: Colors.white),
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
                    widget.caravanTitle,
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
                final isMine = m.senderId == me;

                return Align(
                  alignment: isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: isMine
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
                              onPressed: () => Navigator.pop(
                                  context, false),
                              child: const Text("Vazgeç"),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(
                                  context, true),
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
                      padding:
                      const EdgeInsets.fromLTRB(13, 10, 13, 8),
                      decoration: BoxDecoration(
                        color: isMine ? kMine : kOther,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft:
                          Radius.circular(isMine ? 18 : 4),
                          bottomRight:
                          Radius.circular(isMine ? 4 : 18),
                        ),
                        border: Border.all(
                          color: isMine
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
                              color: isMine
                                  ? Colors.white
                                  : Colors.black87,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _time(m.createdAt),
                            style: TextStyle(
                              color: isMine
                                  ? Colors.white70
                                  : Colors.black45,
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
              color: _CaravanChatDetailPageState.kMine,
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