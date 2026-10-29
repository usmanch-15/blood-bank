import '../../../utils/feedback.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/workflow_service.dart';

String _a(BuildContext c, String en, String ur) =>
    AppLocalizations.of(c).locale.languageCode == 'ur' ? ur : en;

class AdminEmergencyReviewScreen extends StatefulWidget {
  const AdminEmergencyReviewScreen({super.key});
  @override
  State<AdminEmergencyReviewScreen> createState() =>
      _AdminEmergencyReviewScreenState();
}

class _AdminEmergencyReviewScreenState
    extends State<AdminEmergencyReviewScreen> {
  final _items = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  DocumentSnapshot? _cursor;
  bool _loading = false, _done = false, _reviewed = false;
  String? _error;
  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _cursor = null;
        _done = false;
      }
    });
    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('blood_requests')
          .orderBy('createdAt', descending: true)
          .limit(20);
      q =
          _reviewed
              ? q.where(
                'reviewStatus',
                whereIn: ['approved', 'rejected', 'flagged', 'clarification'],
              )
              : q.where('reviewStatus', isEqualTo: 'pending_review');
      if (_cursor != null) {
        q = q.startAfterDocument(_cursor!);
      }
      final page = await q.get();
      final seen = _items.map((e) => e.id).toSet();
      _items.addAll(page.docs.where((e) => !seen.contains(e.id)));
      if (page.docs.length < 20) {
        _done = true;
      } else {
        _cursor = page.docs.last;
      }
    } catch (e) {
      _error = AppFeedback.message(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _decide(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final note = TextEditingController();
    var decision = 'approved';
    var busy = false;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, set) => AlertDialog(
                  scrollable: true,
                  title: Text(
                    _a(
                      ctx,
                      'Review emergency request',
                      'ہنگامی درخواست کا جائزہ',
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: decision,
                        items:
                            ['approved', 'rejected', 'flagged', 'clarification']
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            busy
                                ? null
                                : (v) => set(() => decision = v ?? decision),
                      ),
                      TextField(
                        controller: note,
                        maxLength: 2000,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: _a(ctx, 'Required note', 'ضروری نوٹ'),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: busy ? null : () => Navigator.pop(ctx, false),
                      child: Text(_a(ctx, 'Cancel', 'منسوخ')),
                    ),
                    FilledButton(
                      onPressed:
                          busy || note.text.trim().isEmpty
                              ? null
                              : () async {
                                set(() => busy = true);
                                try {
                                  await WorkflowService.call(
                                    'reviewEmergencyRequest',
                                    {
                                      'id': doc.id,
                                      'decision': decision,
                                      'note': note.text.trim(),
                                      'sos': false,
                                    },
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx, true);
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _a(
                                            ctx,
                                            'Review failed. Please try again.',
                                            'جائزہ ناکام ہوگیا۔ دوبارہ کوشش کریں۔',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  set(() => busy = false);
                                }
                              },
                      child: Text(_a(ctx, 'Submit', 'جمع کریں')),
                    ),
                  ],
                ),
          ),
    );
    note.dispose();
    if (ok == true) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              _a(context, 'Emergency review', 'ہنگامی جائزہ'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ToggleButtons(
            isSelected: [_reviewed == false, _reviewed],
            onPressed: (i) {
              setState(() => _reviewed = i == 1);
              _load(reset: true);
            },
            children: [
              Text(_a(context, 'Pending', 'زیر التوا')),
              Text(_a(context, 'Reviewed', 'جائزہ شدہ')),
            ],
          ),
        ],
      ),
      if (_error != null)
        Row(
          children: [
            Expanded(
              child: Text(
                _a(
                  context,
                  'Unable to load records.',
                  'ریکارڈ لوڈ نہیں ہو سکے۔',
                ),
              ),
            ),
            TextButton(
              onPressed: () => _load(reset: true),
              child: Text(_a(context, 'Retry', 'دوبارہ کوشش')),
            ),
          ],
        ),
      Expanded(
        child:
            _items.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (c, i) {
                    final d = _items[i], v = d.data();
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${v['bloodGroup'] ?? ''} • ${v['urgency'] ?? ''}',
                        ),
                        subtitle: Text(
                          '${v['hospitalName'] ?? ''}\n${v['reason'] ?? ''}\nReviewer: ${v['reviewerId'] ?? '—'}  ${v['reviewedAt'] ?? ''}\n${v['reviewNote'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing:
                            !_reviewed
                                ? FilledButton(
                                  onPressed: () => _decide(d),
                                  child: Text(_a(c, 'Review', 'جائزہ')),
                                )
                                : null,
                      ),
                    );
                  },
                ),
      ),
      if (!_done)
        TextButton(
          onPressed: _loading ? null : () => _load(),
          child: Text(
            _loading
                ? _a(context, 'Loading…', 'لوڈ ہو رہا ہے…')
                : _a(context, 'Load more', 'مزید لوڈ کریں'),
          ),
        ),
    ],
  );
}

class AdminVerificationReviewScreen extends StatefulWidget {
  const AdminVerificationReviewScreen({super.key});
  @override
  State<AdminVerificationReviewScreen> createState() =>
      _AdminVerificationReviewScreenState();
}

class _AdminVerificationReviewScreenState
    extends State<AdminVerificationReviewScreen> {
  final _items = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  DocumentSnapshot? _cursor;
  bool _loading = false, _done = false, _reviewed = false;
  String? _error;
  Future<void> _load({bool reset = false}) async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _cursor = null;
        _done = false;
      }
    });
    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('verification_requests')
          .orderBy('submittedAt', descending: true)
          .limit(20);
      q =
          _reviewed
              ? q.where(
                'status',
                whereIn: [
                  'approved',
                  'rejected',
                  'more_info_needed',
                  'revoked',
                ],
              )
              : q.where('status', isEqualTo: 'pending');
      if (_cursor != null) {
        q = q.startAfterDocument(_cursor!);
      }
      final p = await q.get();
      final seen = _items.map((e) => e.id).toSet();
      _items.addAll(p.docs.where((e) => !seen.contains(e.id)));
      if (p.docs.length < 20) {
        _done = true;
      } else {
        _cursor = p.docs.last;
      }
    } catch (e) {
      _error = AppFeedback.message(e);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _open(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final v = doc.data();
    final note = TextEditingController();
    var busy = false;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, set) => AlertDialog(
                  scrollable: true,
                  title: Text(_a(ctx, 'Verification review', 'تصدیق کا جائزہ')),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        FutureBuilder<String>(
                          future:
                              FirebaseStorage.instance
                                  .ref(v['evidencePath']?.toString() ?? '')
                                  .getDownloadURL(),
                          builder:
                              (c, s) =>
                                  s.hasError
                                      ? Text(
                                        _a(
                                          c,
                                          'Evidence could not be loaded.',
                                          'ثبوت لوڈ نہیں ہو سکا۔',
                                        ),
                                      )
                                      : s.hasData
                                      ? Image.network(
                                        s.data!,
                                        height: 180,
                                        errorBuilder:
                                            (_, __, ___) => Text(
                                              _a(
                                                c,
                                                'Evidence could not be loaded.',
                                                'ثبوت لوڈ نہیں ہو سکا۔',
                                              ),
                                            ),
                                      )
                                      : const CircularProgressIndicator(),
                        ),
                        Text(
                          'Reviewer: ${v['reviewerId'] ?? '—'}\n${v['reviewNote'] ?? ''}\n${v['reviewedAt'] ?? ''}',
                        ),
                        TextField(
                          controller: note,
                          maxLength: 2000,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: _a(
                              ctx,
                              'Required reason/note',
                              'ضروری وجہ/نوٹ',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: busy ? null : () => Navigator.pop(ctx, false),
                      child: Text(_a(ctx, 'Cancel', 'منسوخ')),
                    ),
                    if (v['status'] == 'approved')
                      TextButton(
                        onPressed:
                            busy || note.text.trim().isEmpty
                                ? null
                                : () async {
                                  set(() => busy = true);
                                  try {
                                    await WorkflowService.call(
                                      'revokeVerification',
                                      {
                                        'userId': doc.id,
                                        'reason': note.text.trim(),
                                      },
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx, true);
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _a(
                                              ctx,
                                              'Revoke failed.',
                                              'منسوخی ناکام ہوگئی۔',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    set(() => busy = false);
                                  }
                                },
                        child: Text(_a(ctx, 'Revoke', 'منسوخ کریں')),
                      ),
                    if (v['status'] != 'approved')
                      FilledButton(
                        onPressed:
                            busy || note.text.trim().isEmpty
                                ? null
                                : () async {
                                  set(() => busy = true);
                                  try {
                                    await WorkflowService.call(
                                      'reviewVerification',
                                      {
                                        'userId': doc.id,
                                        'decision': 'approved',
                                        'note': note.text.trim(),
                                      },
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx, true);
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _a(
                                              ctx,
                                              'Review failed.',
                                              'جائزہ ناکام ہوگیا۔',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    set(() => busy = false);
                                  }
                                },
                        child: Text(_a(ctx, 'Approve', 'منظور')),
                      ),
                  ],
                ),
          ),
    );
    note.dispose();
    if (ok == true) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              _a(context, 'Verification review', 'تصدیق کا جائزہ'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ToggleButtons(
            isSelected: [!_reviewed, _reviewed],
            onPressed: (i) {
              setState(() => _reviewed = i == 1);
              _load(reset: true);
            },
            children: [
              Text(_a(context, 'Pending', 'زیر التوا')),
              Text(_a(context, 'Reviewed', 'جائزہ شدہ')),
            ],
          ),
        ],
      ),
      if (_error != null)
        TextButton(
          onPressed: () => _load(reset: true),
          child: Text(_a(context, 'Retry', 'دوبارہ کوشش')),
        ),
      Expanded(
        child:
            _items.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (c, i) {
                    final d = _items[i], v = d.data();
                    return Card(
                      child: ListTile(
                        title: Text(d.id),
                        subtitle: Text(
                          '${v['submittedAt'] ?? ''}\n${v['reviewerId'] ?? '—'} ${v['reviewedAt'] ?? ''}\n${v['reviewNote'] ?? ''}',
                        ),
                        onTap: () => _open(d),
                      ),
                    );
                  },
                ),
      ),
      if (!_done)
        TextButton(
          onPressed: _loading ? null : () => _load(),
          child: Text(_a(context, 'Load more', 'مزید لوڈ کریں')),
        ),
    ],
  );
}
