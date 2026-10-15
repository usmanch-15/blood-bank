import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _body = TextEditingController();
  bool _sending = false;
  int _streamVersion = 0;
  CollectionReference<Map<String, dynamic>> get _messages => FirebaseFirestore
      .instance
      .collection('conversations/${widget.conversationId}/messages');

  Future<void> _send() async {
    final text = _body.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty || uid == null || _sending) return;
    setState(() => _sending = true);
    try {
      await _messages.add({
        'senderId': uid,
        'body': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _body.clear();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).operationFailed} $e',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(_streamVersion),
              stream: _messages.orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.forum_outlined, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).chatUnavailable,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => setState(() => _streamVersion++),
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocalizations.of(context).retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppLocalizations.of(context).noMessages,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final data = messages[i].data();
                    final mine = data['senderId'] == uid;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color:
                            mine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(data['body'] as String? ?? ''),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _body,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).messageHint,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon:
                        _sending
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
