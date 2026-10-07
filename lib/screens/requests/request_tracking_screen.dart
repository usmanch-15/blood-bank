import 'dart:async';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/workflow_service.dart';
import '../../widgets/report_misuse_button.dart';
import '../receiver/donor_matching_screen.dart';

class RequestTrackingScreen extends StatefulWidget {
  final String requestId;
  const RequestTrackingScreen({super.key, required this.requestId});
  @override
  State<RequestTrackingScreen> createState() => _RequestTrackingScreenState();
}

class _RequestTrackingScreenState extends State<RequestTrackingScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  Timer? _timer;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await WorkflowService.request(widget.requestId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
      if (data['canViewPrivate'] == true && _subscription == null) {
        _subscription = FirebaseFirestore.instance
            .doc('blood_requests/${widget.requestId}')
            .snapshots()
            .listen(
              (doc) {
                if (!mounted) return;
                setState(() {
                  _data =
                      doc.exists
                          ? {...doc.data()!, 'canViewPrivate': true}
                          : null;
                  _error = doc.exists ? null : 'This request was removed.';
                });
              },
              onError: (Object e) {
                if (mounted)
                  setState(() {
                    _data = null;
                    _error =
                        'Access changed or connection unavailable. Refresh to continue.';
                  });
              },
            );
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _data = null;
          _error = e.toString();
        });
    }
  }

  Future<void> _action(
    String name,
    Map<String, dynamic> data,
    String prompt,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text(prompt),
            content: const Text('Please confirm this action.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await WorkflowService.call(name, {
        'requestId': widget.requestId,
        ...data,
      });
      await _subscription?.cancel();
      _subscription = null;
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _contact(String donor) async {
    try {
      final d = await WorkflowService.call('getDonorContact', {
        'requestId': widget.requestId,
        'donorId': donor,
      });
      await _phone(d['phoneNumber'] as String?);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _phone(String? number) async {
    if (number == null ||
        number.isEmpty ||
        !await launchUrl(Uri(scheme: 'tel', path: number))) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact number or dialer unavailable.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data,
        owner =
            d?['requesterId'] == _uid ||
            context.watch<AuthController>().isAdmin;
    final deadline = d?['requiredBy'] as Timestamp?;
    final expired =
        deadline != null && deadline.toDate().isBefore(DateTime.now());
    final open =
        d != null &&
        ['pending', 'accepted', 'partially_fulfilled'].contains(d['status']) &&
        !expired;
    final commitments = Map<String, dynamic>.from(
      d?['commitments'] as Map? ?? {},
    );
    if (commitments.isEmpty && d?['acceptedDonorId'] != null)
      commitments[d!['acceptedDonorId']] = {
        'name': 'Assigned donor',
        'status': 'accepted',
      };
    final mine = commitments[_uid] as Map?;
    final assigned = [
      'accepted',
      'awaiting_confirmation',
    ].contains(mine?['status']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Tracking'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
              : d == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${d['bloodGroup']} • ${d['hospitalName']}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Status: ${expired && openStatuses(d['status']) ? 'expired' : d['status']}',
                  ),
                  Text(
                    'Requested: ${d['quantity']} • Donated: ${d['donatedUnits'] ?? 0} • Remaining: ${d['remainingUnits'] ?? d['quantity']}',
                  ),
                  if (deadline != null)
                    Text('Required by: ${deadline.toDate().toLocal()}'),
                  if (d['canViewPrivate'] != true)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Patient details and the meeting location are shared after you accept. Each commitment represents one unit.',
                      ),
                    ),
                  if (d['canViewPrivate'] == true) ...[
                    const Divider(),
                    Text('Hospital address: ${d['hospitalAddress'] ?? ''}'),
                    if ((d['patientName'] ?? '').toString().isNotEmpty)
                      Text('Patient: ${d['patientName']}'),
                    if ((d['reason'] ?? '').toString().isNotEmpty)
                      Text('Notes: ${d['reason']}'),
                    if (!owner)
                      OutlinedButton.icon(
                        onPressed: () => _phone(d['contactNumber'] as String?),
                        icon: const Icon(Icons.call),
                        label: const Text('Call requester'),
                      ),
                    if (d['latitude'] != null && d['longitude'] != null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            if (!await launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/directions?to=${d['latitude']}%2C${d['longitude']}',
                              ),
                              mode: LaunchMode.externalApplication,
                            ))
                              throw StateError('Maps unavailable.');
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions to meeting point'),
                      ),
                  ],
                  if (open &&
                      !owner &&
                      !assigned &&
                      mine?['status'] != 'completed')
                    FilledButton(
                      onPressed:
                          _busy
                              ? null
                              : () => _action(
                                'acceptDonation',
                                {},
                                'Commit to donating one unit?',
                              ),
                      child: const Text('Accept / Respond'),
                    ),
                  if (assigned) ...[
                    if (open)
                      FilledButton(
                        onPressed:
                            _busy
                                ? null
                                : () => _action(
                                  'updateAssignment',
                                  {'action': 'ready'},
                                  'Ask requester to confirm your donation?',
                                ),
                        child: const Text('I donated — request confirmation'),
                      ),
                    OutlinedButton(
                      onPressed:
                          _busy
                              ? null
                              : () => _action('updateAssignment', {
                                'action': 'withdraw',
                              }, 'Withdraw from this assignment?'),
                      child: const Text('Withdraw'),
                    ),
                  ],
                  if (owner) ...[
                    const Divider(),
                    Text(
                      'Donor commitments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (commitments.isEmpty)
                      const Text('No donors have responded yet.'),
                    ...commitments.entries.map((e) {
                      final c = e.value as Map;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${c['name'] ?? 'Donor'} • ${c['status']}'),
                              if ([
                                'accepted',
                                'awaiting_confirmation',
                              ].contains(c['status']))
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () => _contact(e.key),
                                      child: const Text('Contact'),
                                    ),
                                    if (open)
                                      TextButton(
                                        onPressed:
                                            _busy
                                                ? null
                                                : () => _action(
                                                  'confirmDonation',
                                                  {'donorId': e.key},
                                                  'Confirm one unit was donated?',
                                                ),
                                        child: const Text('Confirm donation'),
                                      ),
                                    TextButton(
                                      onPressed:
                                          _busy
                                              ? null
                                              : () => _action(
                                                'updateAssignment',
                                                {
                                                  'donorId': e.key,
                                                  'action': 'release',
                                                },
                                                'Release donor and reopen this unit?',
                                              ),
                                      child: const Text('Release / Reassign'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (open) ...[
                      OutlinedButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => DonorMatchingScreen(
                                      requestId: widget.requestId,
                                      initialBloodGroup: d['bloodGroup'],
                                    ),
                              ),
                            ),
                        child: const Text('Find additional donors'),
                      ),
                      TextButton(
                        onPressed:
                            _busy
                                ? null
                                : () => _action(
                                  'closeRequest',
                                  {},
                                  'Cancel the remaining request?',
                                ),
                        child: const Text('Cancel request'),
                      ),
                    ],
                    if (d['sosId'] != null && open)
                      FilledButton(
                        onPressed:
                            _busy
                                ? null
                                : () => _action('resolveSos', {
                                  'sosId': d['sosId'],
                                }, 'Resolve this SOS?'),
                        child: const Text('Resolve SOS'),
                      ),
                  ],
                  if (_busy) const LinearProgressIndicator(),
                  if (d['canViewPrivate'] == true) ...[
                    const Divider(),
                    Text(
                      'Timeline',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream:
                          FirebaseFirestore.instance
                              .collection(
                                'blood_requests/${widget.requestId}/events',
                              )
                              .orderBy('createdAt')
                              .snapshots(),
                      builder: (context, s) {
                        if (s.hasError)
                          return const Text('Timeline unavailable.');
                        return Column(
                          children:
                              (s.data?.docs ?? [])
                                  .map(
                                    (e) => ListTile(
                                      title: Text(
                                        e
                                            .data()['action']
                                            .toString()
                                            .replaceAll('_', ' '),
                                      ),
                                      subtitle: Text(
                                        (e.data()['createdAt'] as Timestamp?)
                                                ?.toDate()
                                                .toLocal()
                                                .toString() ??
                                            '',
                                      ),
                                    ),
                                  )
                                  .toList(),
                        );
                      },
                    ),
                  ],
                  ReportMisuseButton(targetRequestId: widget.requestId),
                ],
              ),
    );
  }

  bool openStatuses(dynamic status) =>
      ['pending', 'accepted', 'partially_fulfilled'].contains(status);
}
