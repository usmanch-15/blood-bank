import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/awareness_banner.dart';
import '../services/workflow_service.dart';
import 'awareness_banner_card.dart';
import 'dashboard_components.dart';

class DonorAwareness extends StatefulWidget {
  final ValueChanged<String> onAction;
  const DonorAwareness({super.key, required this.onAction});
  @override
  State<DonorAwareness> createState() => _DonorAwarenessState();
}

class _DonorAwarenessState extends State<DonorAwareness> {
  final _cardKey = GlobalKey();
  final _viewed = <String>{};
  final _dismissed = <String>{};
  List<AwarenessBanner> _items = [];
  int _index = 0;
  Timer? _visibility;
  bool _loading = false;
  int _ticks = 0;
  String get _prefKey =>
      'dismissed_banners_${FirebaseAuth.instance.currentUser?.uid}';
  @override
  void initState() {
    super.initState();
    _load();
    _visibility = Timer.periodic(const Duration(seconds: 1), (_) {
      _expire();
      _recordVisible();
      if (++_ticks % 30 == 0 && ModalRoute.of(context)?.isCurrent == true) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _visibility?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    _loading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getStringList(_prefKey) ?? [];
      _dismissed.addAll(dismissed);
      final page = await WorkflowService.call('donorAwarenessBanners');
      if (!mounted) return;
      setState(
        () =>
            _items =
                (page['items'] as List)
                    .map(
                      (d) =>
                          AwarenessBanner.fromMap(Map<String, dynamic>.from(d)),
                    )
                    .where(
                      (b) =>
                          !_dismissed.contains(b.dismissalKey) &&
                          b.visibleAt(DateTime.now()),
                    )
                    .toList(),
      );
      if (_index >= _items.length) _index = 0;
    } catch (_) {
      /* Optional campaigns never block requests. */
    } finally {
      _loading = false;
    }
  }

  void _expire() {
    if (!mounted || !_items.any((b) => !b.visibleAt(DateTime.now()))) return;
    setState(() {
      _items.removeWhere((b) => !b.visibleAt(DateTime.now()));
      _index = 0;
    });
  }

  Future<void> _event(AwarenessBanner b, String event) async {
    try {
      await WorkflowService.call('recordBannerEvent', {
        'id': b.id,
        'revision': b.revision,
        'event': event,
      });
    } catch (_) {
      /* Best-effort analytics. */
    }
  }

  void _recordVisible() {
    if (!mounted ||
        _items.isEmpty ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final b = _items[_index];
    if (_viewed.contains(b.dismissalKey)) return;
    final box = _cardKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final screen = Offset.zero & MediaQuery.sizeOf(context);
    if (rect.intersect(screen).height < rect.height * .5) return;
    _viewed.add(b.dismissalKey);
    _event(b, 'view');
  }

  Future<void> _dismiss(AwarenessBanner b) async {
    setState(() {
      _dismissed.add(b.dismissalKey);
      _items.remove(b);
      _index = 0;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey) ?? [];
      await prefs.setStringList(_prefKey, {...saved, b.dismissalKey}.toList());
    } catch (_) {
      // The current-session dismissal remains effective if local storage fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final b = _items[_index];
    return Column(
      children: [
        AwarenessBannerCard(
          key: _cardKey,
          banner: b,
          onDismiss: () => _dismiss(b),
          onAction: () {
            if (!b.visibleAt(DateTime.now())) {
              _expire();
              return;
            }
            _event(b, 'click');
            widget.onAction(b.action);
          },
        ),
        if (_items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${_index + 1} / ${_items.length}'),
              TextButton(
                onPressed:
                    () => setState(() => _index = (_index + 1) % _items.length),
                child: Text(dashboardText(context, 'Next tip', 'اگلا پیغام')),
              ),
            ],
          ),
      ],
    );
  }
}
