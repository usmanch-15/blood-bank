import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../models/awareness_banner.dart';
import '../../../services/workflow_service.dart';
import '../../../utils/feedback.dart';
import '../../../widgets/awareness_banner_card.dart';
import '../../../widgets/premium_states.dart';

class AdminAwarenessBanners extends StatefulWidget {
  const AdminAwarenessBanners({super.key});
  @override
  State<AdminAwarenessBanners> createState() => _AdminAwarenessBannersState();
}

class _AdminAwarenessBannersState extends State<AdminAwarenessBanners> {
  void _edit(BuildContext context, [Map<String, dynamic>? data]) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  InheritedTheme.captureAll(context, _BannerEditor(data: data)),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Awareness banners'),
      actions: [
        TextButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Create banner'),
        ),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('awareness_banners')
              .orderBy('updatedAt', descending: true)
              .limit(100)
              .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return PremiumErrorState(
            message: AppFeedback.message(snap.error!),
            onRetry: () => setState(() {}),
          );
        }
        if (!snap.hasData) return const PremiumLoading();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Donor mode only • English + Urdu • Scheduled campaigns',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Views and clicks count each signed-in donor once per banner revision. A view is recorded when at least half the banner is visible. Optional analytics may undercount when offline. Latest 100 campaigns are shown.',
            ),
            const SizedBox(height: 20),
            if (snap.data!.docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No banners yet. Create a campaign, preview both languages, then activate it.',
                ),
              ),
            for (final doc in snap.data!.docs)
              Builder(
                builder: (context) {
                  final d = doc.data();
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final state =
                      d['active'] != true
                          ? 'Inactive'
                          : (d['startAt'] as num) > now
                          ? 'Scheduled'
                          : (d['endAt'] as num) <= now
                          ? 'Ended'
                          : 'Live';
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.campaign_outlined),
                      title: Text(
                        (d['en'] as Map?)?['title']?.toString() ?? 'Banner',
                      ),
                      subtitle: Text(
                        '$state · Priority ${d['priority']}\n${d['views'] ?? 0} unique views · ${d['clicks'] ?? 0} unique clicks',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _edit(context, {...d, 'id': doc.id}),
                    ),
                  );
                },
              ),
          ],
        );
      },
    ),
  );
}

class _BannerEditor extends StatefulWidget {
  final Map<String, dynamic>? data;
  const _BannerEditor({this.data});
  @override
  State<_BannerEditor> createState() => _BannerEditorState();
}

class _BannerEditorState extends State<_BannerEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _enTitle,
      _enDescription,
      _enButton,
      _urTitle,
      _urDescription,
      _urButton,
      _image,
      _priority;
  late DateTime _start, _end;
  bool _active = false, _busy = false, _urdu = false;
  String _action = 'requests';
  @override
  void initState() {
    super.initState();
    final d = widget.data;
    final en = d?['en'] as Map? ?? {}, ur = d?['ur'] as Map? ?? {};
    _enTitle = TextEditingController(
      text: en['title'] ?? 'Someone nearby may need your help',
    );
    _enDescription = TextEditingController(
      text:
          en['description'] ??
          'Keep your availability up to date and explore blood requests near you.',
    );
    _enButton = TextEditingController(text: en['button'] ?? 'Explore requests');
    _urTitle = TextEditingController(
      text: ur['title'] ?? 'آپ کے قریب کسی کو مدد کی ضرورت ہو سکتی ہے',
    );
    _urDescription = TextEditingController(
      text:
          ur['description'] ??
          'اپنی دستیابی تازہ رکھیں اور اپنے قریب خون کی درخواستیں دیکھیں۔',
    );
    _urButton = TextEditingController(text: ur['button'] ?? 'درخواستیں دیکھیں');
    _image = TextEditingController(text: d?['imageUrl'] ?? '');
    _priority = TextEditingController(text: '${d?['priority'] ?? 10}');
    _start =
        d?['startAt'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
              (d!['startAt'] as num).toInt(),
            )
            : DateTime.now();
    _end =
        d?['endAt'] is num
            ? DateTime.fromMillisecondsSinceEpoch((d!['endAt'] as num).toInt())
            : DateTime.now().add(const Duration(days: 30));
    _action = d?['action'] ?? 'requests';
    _active = d?['active'] == true;
  }

  @override
  void dispose() {
    for (final c in [
      _enTitle,
      _enDescription,
      _enButton,
      _urTitle,
      _urDescription,
      _urButton,
      _image,
      _priority,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get _data => {
    if (widget.data?['id'] != null) 'id': widget.data!['id'],
    'en': {
      'title': _enTitle.text.trim(),
      'description': _enDescription.text.trim(),
      'button': _enButton.text.trim(),
    },
    'ur': {
      'title': _urTitle.text.trim(),
      'description': _urDescription.text.trim(),
      'button': _urButton.text.trim(),
    },
    'imageUrl': _image.text.trim(),
    'action': _action,
    'priority': int.tryParse(_priority.text) ?? -1,
    'active': _active,
    'startAt': _start.millisecondsSinceEpoch,
    'endAt': _end.millisecondsSinceEpoch,
    'audience': 'donor',
  };
  Future<void> _date(bool start) async {
    final day = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start ? _start : _end),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _upload() async {
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length >= 3 * 1024 * 1024) {
        throw StateError('Choose an image smaller than 3 MB.');
      }
      final ext = file.name.split('.').last.toLowerCase();
      final mime =
          {
            'jpg': 'image/jpeg',
            'jpeg': 'image/jpeg',
            'png': 'image/png',
            'webp': 'image/webp',
          }[ext];
      if (mime == null) throw StateError('Choose a JPG, PNG or WebP image.');
      final ref = FirebaseStorage.instance.ref(
        'awareness_banners/${DateTime.now().microsecondsSinceEpoch}.$ext',
      );
      await ref.putData(bytes, SettableMetadata(contentType: mime));
      final url = await ref.getDownloadURL();
      if (mounted) setState(() => _image.text = url);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      AppFeedback.error(
        context,
        StateError('End date must be after the start date.'),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await WorkflowService.call('manageAwarenessBanner', _data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppFeedback.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label,
    int max, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c,
      maxLength: max,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      onChanged: (_) => setState(() {}),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.data == null
            ? 'Create awareness banner'
            : 'Edit awareness banner',
      ),
    ),
    body: SafeArea(
      child: AbsorbPointer(
        absorbing: _busy,
        child: Form(
          key: _form,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal:
                  MediaQuery.sizeOf(context).width > 948
                      ? (MediaQuery.sizeOf(context).width - 900) / 2
                      : 24,
              vertical: 24,
            ),
            children: [
              const Text(
                'Audience: donor mode only. Educational health claims should be medically reviewed before publication.',
              ),
              const SizedBox(height: 20),
              _field(_enTitle, 'English heading', 80),
              _field(_enDescription, 'English description', 240, lines: 3),
              _field(_enButton, 'English button', 40),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    _field(_urTitle, 'اردو عنوان', 80),
                    _field(_urDescription, 'اردو تفصیل', 240, lines: 3),
                    _field(_urButton, 'اردو بٹن', 40),
                  ],
                ),
              ),
              TextFormField(
                controller: _image,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional HTTPS)',
                ),
                validator:
                    (v) =>
                        v != null &&
                                v.trim().isNotEmpty &&
                                !(Uri.tryParse(v.trim())?.isScheme('https') ??
                                    false)
                            ? 'Use an HTTPS URL'
                            : null,
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _upload,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Upload image · max 3 MB'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _action,
                decoration: const InputDecoration(
                  labelText: 'Button destination',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'requests',
                    child: Text('Blood requests'),
                  ),
                  DropdownMenuItem(
                    value: 'profile',
                    child: Text('Donor profile'),
                  ),
                  DropdownMenuItem(
                    value: 'history',
                    child: Text('Donation history'),
                  ),
                ],
                onChanged: (v) => setState(() => _action = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priority,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Priority (0–100, highest first)',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 0 || n > 100
                      ? 'Enter 0 to 100'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _date(true),
                    icon: const Icon(Icons.event),
                    label: Text(
                      'Start: ${DateFormat('d MMM yyyy, HH:mm').format(_start)}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _date(false),
                    icon: const Icon(Icons.event_available),
                    label: Text(
                      'End: ${DateFormat('d MMM yyyy, HH:mm').format(_end)}',
                    ),
                  ),
                ],
              ),
              const Text(
                'Dates use this device’s local time and are saved as absolute timestamps.',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Shown only during the scheduled period.'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const Divider(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Preview in Urdu'),
                value: _urdu,
                onChanged: (v) => setState(() => _urdu = v),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AwarenessBannerCard(
                    banner: AwarenessBanner.fromMap({
                      ..._data,
                      'id': widget.data?['id'] ?? 'preview',
                    }),
                    urdu: _urdu,
                    onAction:
                        () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opens: $_action')),
                        ),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _save,
                icon:
                    _busy
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check),
                label: Text(_busy ? 'Saving…' : 'Save banner'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
