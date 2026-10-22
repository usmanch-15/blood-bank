import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/workflow_service.dart';
import '../../utils/feedback.dart';
import '../../widgets/dashboard_components.dart';
import '../../widgets/paged_records.dart';
import '../../widgets/premium_states.dart';
import 'request_tracking_screen.dart';
import '../maps/blood_requests_map_screen.dart';
import '../receiver/sos_status_screen.dart';

class RequestListScreen extends StatefulWidget {
  final String mode;
  final bool embedded;
  const RequestListScreen({
    super.key,
    this.mode = 'mine',
    this.embedded = false,
  });
  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final _items = <Map<String, dynamic>>[];
  String? _cursor, _error;
  bool _loading = false, _more = true;
  double _radius = 5;
  String? _urgency;
  bool get _remote => ['discover', 'invitations'].contains(widget.mode);
  @override
  void initState() {
    super.initState();
    if (_remote) _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _cursor = null;
        _items.clear();
        _more = true;
      }
    });
    try {
      final page = await WorkflowService.call(
        widget.mode == 'invitations' ? 'donorInvitations' : 'discoverRequests',
        {'cursor': _cursor, 'radiusKm': _radius},
      );
      if (!mounted) return;
      setState(() {
        for (final item in (page['items'] as List? ?? [])) {
          final d = Map<String, dynamic>.from(item);
          if (!_items.any((e) => e['id'] == d['id'])) _items.add(d);
        }
        _cursor = page['cursor'] as String?;
        _more = _cursor != null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = AppFeedback.message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map<String, dynamic> d, String id, {String? sosId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                sosId != null
                    ? SosStatusScreen(sosId: sosId, requestId: id)
                    : RequestTrackingScreen(requestId: id),
      ),
    );
    if (mounted && _remote) await _load(refresh: true);
  }

  Widget _card(Map<String, dynamic> d, String id, {String? sosId}) =>
      OpportunityCard(
        data: d,
        onTap: () => _open(d, id, sosId: sosId),
        action: dashboardText(
          context,
          'View details & next step',
          'تفصیل اور اگلا قدم',
        ),
      );
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final discover = widget.mode == 'discover';
    final visible =
        _items
            .where((d) => _urgency == null || d['urgency'] == _urgency)
            .toList();
    Widget body;
    if (uid == null) {
      body = Center(
        child: Text(
          dashboardText(context, 'Please sign in.', 'براہ کرم سائن ان کریں۔'),
        ),
      );
    } else if (_remote) {
      body = RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (discover) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dashboardText(
                        context,
                        'Find a request near you',
                        'اپنے قریب درخواست تلاش کریں',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: dashboardText(context, 'Map view', 'نقشہ'),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BloodRequestsMapScreen(),
                          ),
                        ),
                    icon: const Icon(Icons.map_outlined),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in [
                    5.0,
                    10.0,
                    25.0,
                    50.0,
                    100.0,
                    250.0,
                    500.0,
                    1000.0,
                  ])
                    ChoiceChip(
                      label: Text('${r.round()} km'),
                      selected: _radius == r,
                      onSelected:
                          _loading
                              ? null
                              : (_) {
                                setState(() => _radius = r);
                                _load(refresh: true);
                              },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _urgency ?? 'all',
                decoration: InputDecoration(
                  labelText: dashboardText(context, 'Urgency', 'ضرورت کی شدت'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(
                      dashboardText(context, 'All requests', 'تمام درخواستیں'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'critical',
                    child: Text(
                      dashboardText(context, 'Critical', 'انتہائی فوری'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'urgent',
                    child: Text(dashboardText(context, 'Urgent', 'فوری')),
                  ),
                  DropdownMenuItem(
                    value: 'normal',
                    child: Text(dashboardText(context, 'Normal', 'معمول')),
                  ),
                ],
                onChanged:
                    (v) => setState(() => _urgency = v == 'all' ? null : v),
              ),
              const SizedBox(height: 16),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  dashboardText(
                    context,
                    'Requests sent directly to you. Review the details before committing.',
                    'آپ کو براہ راست بھیجی گئی دعوتیں۔ قبول کرنے سے پہلے تفصیل دیکھیں۔',
                  ),
                ),
              ),
            ...visible.map((d) => _card(d, d['id'] as String)),
            if (_error != null)
              PremiumErrorState(onRetry: () => _load(), message: _error),
            if (visible.isEmpty && !_loading && _error == null)
              PremiumEmptyState(
                title: dashboardText(
                  context,
                  discover
                      ? 'No matching requests in this view. Check your availability and saved location, or broaden the search.'
                      : 'No pending invitations. New invitations will appear here.',
                  discover
                      ? 'کوئی موزوں درخواست نہیں۔ دستیابی اور محفوظ مقام دیکھیں یا تلاش کا دائرہ بڑھائیں۔'
                      : 'ابھی کوئی دعوت نہیں۔ نئی دعوتیں یہاں نظر آئیں گی۔',
                ),
                onAction:
                    discover && _radius < 1000
                        ? () {
                          setState(
                            () =>
                                _radius = [
                                  10.0,
                                  25.0,
                                  50.0,
                                  100.0,
                                  250.0,
                                  500.0,
                                  1000.0,
                                ].firstWhere((r) => r > _radius),
                          );
                          _load(refresh: true);
                        }
                        : null,
                actionLabel: dashboardText(
                  context,
                  'Expand search radius',
                  'تلاش کا دائرہ بڑھائیں',
                ),
              ),
            if (_loading) const PremiumLoading(rows: 2),
            if (!_loading && _more && _error == null)
              TextButton(
                onPressed: _load,
                child: Text(dashboardText(context, 'Load more', 'مزید دیکھیں')),
              ),
          ],
        ),
      );
    } else {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection(
        'blood_requests',
      );
      if (widget.mode == 'active') {
        q = q
            .where('acceptedDonorIds', arrayContains: uid)
            .where(
              'status',
              whereIn: ['pending', 'accepted', 'partially_fulfilled'],
            );
      } else if (widget.mode == 'responses') {
        q = q.where('participantIds', arrayContains: uid);
      } else if (widget.mode == 'sos') {
        q = FirebaseFirestore.instance
            .collection('sosRequests')
            .where('receiverId', isEqualTo: uid);
      } else {
        q = q.where('requesterId', isEqualTo: uid);
      }
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: PagedRecords(
          query: q.orderBy(FieldPath.documentId),
          emptyMessage: dashboardText(
            context,
            'Nothing here yet. Your request activity will appear here.',
            'ابھی کوئی ریکارڈ نہیں۔ آپ کی درخواستوں کی سرگرمی یہاں نظر آئے گی۔',
          ),
          itemBuilder:
              (context, doc) => _card(
                {
                  ...doc.data(),
                  if (widget.mode == 'responses')
                    'responseStatus':
                        (doc.data()['commitments'] as Map?)?[uid]?['status'],
                },
                widget.mode == 'sos'
                    ? (doc.data()['requestId'] ?? doc.id) as String
                    : doc.id,
                sosId: widget.mode == 'sos' ? doc.id : null,
              ),
        ),
      );
    }
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          dashboardText(
            context,
            widget.mode == 'sos'
                ? 'SOS & history'
                : widget.mode == 'mine'
                ? 'My requests'
                : 'Blood requests',
            widget.mode == 'sos' ? 'ایس او ایس اور تاریخ' : 'خون کی درخواستیں',
          ),
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}
