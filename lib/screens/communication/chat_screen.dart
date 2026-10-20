import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workflow_service.dart';

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
  bool _sending = false, _readOnly = false, _blocked = false;
  CollectionReference<Map<String, dynamic>> get _messages => FirebaseFirestore
      .instance
      .collection('conversations/${widget.conversationId}/messages');
  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await WorkflowService.call(name, {
        'conversationId': widget.conversationId,
        ...data,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).operationFailed)),
        );
      }
    }
  }

  Future<void> _loadState() async {
    final c =
        (await FirebaseFirestore.instance
                .collection('conversations')
                .doc(widget.conversationId)
                .get())
            .data() ??
        {};
    final rid = c['requestId']?.toString();
    if (rid == null) {
      return;
    }
    final r =
        (await FirebaseFirestore.instance
                .collection('blood_requests')
                .doc(rid)
                .get())
            .data() ??
        {};
    if (mounted) {
      setState(() {
        _readOnly =
            ![
              'pending',
              'accepted',
              'partially_fulfilled',
            ].contains(r['status']);
        _blocked = (c['blockedUserIds'] as List? ?? []).contains(
          FirebaseAuth.instance.currentUser?.uid,
        );
      });
    }
    await _call('markConversationRead', {});
  }

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty ||
        text.length > 2000 ||
        uid == null ||
        _sending ||
        _readOnly ||
        _blocked) {
      return;
    }
    setState(() => _sending = true);
    try {
      await _messages.add({
        'senderId': uid,
        'body': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _body.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).operationFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _share() async {
    if (_readOnly || _blocked) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Share my phone number'),
            content: const Text(
              'Your number will be visible to the other person in this chat.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await _call('sharePhoneNumber', {'confirm': true});
    }
  }

  Future<void> _report() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Report chat'),
            content: TextField(
              controller: controller,
              maxLength: 1000,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, controller.text.trim()),
                child: const Text('Report'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (reason != null && reason.isNotEmpty) {
      await _call('reportConversation', {'reason': reason});
    }
  }

  Future<void> _block() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Block this person?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Block'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await _call('blockUser', {});
      if (mounted) {
        setState(() => _blocked = true);
      }
    }
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  String _day(DateTime d) {
    final n = DateTime.now();
    final a = DateTime(n.year, n.month, n.day);
    final b = DateTime(d.year, d.month, d.day);
    if (a == b) return 'Today';
    if (a.subtract(const Duration(days: 1)) == b) return 'Yesterday';
    return '${d.year}-${d.month}-${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'share') {
                _share();
              }
              if (v == 'report') {
                _report();
              }
              if (v == 'block') {
                _block();
              }
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'share',
                    enabled: !_readOnly && !_blocked,
                    child: const Text('Share my phone number'),
                  ),
                  const PopupMenuItem(value: 'block', child: Text('Block')),
                  const PopupMenuItem(value: 'report', child: Text('Report')),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_readOnly)
            const MaterialBanner(
              content: Text(
                'This chat is read-only because the request is closed.',
              ),
              actions: [SizedBox.shrink()],
            ),
          if (_blocked)
            const MaterialBanner(
              content: Text('You blocked this user.'),
              actions: [SizedBox.shrink()],
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _messages.orderBy('createdAt').limitToLast(30).snapshots(),
              builder: (c, s) {
                if (s.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => setState(() {}),
                      child: Text(AppLocalizations.of(context).retry),
                    ),
                  );
                }
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = s.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context).noMessages),
                  );
                }
                _call('markConversationRead', {});
                return ListView(
                  children:
                      docs.map((m) {
                        final d = m.data();
                        final t = (d['createdAt'] as Timestamp?)?.toDate();
                        final mine = d['senderId'] == uid;
                        return Column(
                          children: [
                            if (t != null) Text(_day(t)),
                            Align(
                              alignment:
                                  mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              child: Card(
                                color:
                                    d['type'] == 'phone_share'
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest
                                        : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    '${d['body'] ?? ''}${t == null ? '' : '\n${t.hour}:${t.minute.toString().padLeft(2, '0')}'}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Share your phone number only if you agree.\nصرف رضامندی کی صورت میں فون نمبر شیئر کریں۔',
              textAlign: TextAlign.center,
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _body,
                    enabled: !_readOnly && !_blocked,
                    maxLength: 2000,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
                IconButton(
                  onPressed: _sending || _readOnly || _blocked ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
