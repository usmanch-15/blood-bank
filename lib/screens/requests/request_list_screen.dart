import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/workflow_service.dart';
import '../../widgets/paged_records.dart';
import 'request_tracking_screen.dart';

class RequestListScreen extends StatefulWidget {
  final String mode;
  const RequestListScreen({super.key, this.mode = 'mine'});
  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final _items = <Map<String, dynamic>>[];
  String? _cursor, _error;
  bool _loading = false, _more = true;
  @override
  void initState() {
    super.initState();
    if (widget.mode == 'discover') _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await WorkflowService.call('discoverRequests', {
        'cursor': _cursor,
      });
      if (mounted)
        setState(() {
          _items.addAll(
            (page['items'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
          _cursor = page['cursor'];
          _more = _cursor != null;
        });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _tile(Map<String, dynamic> d, String id) => Card(
    child: ListTile(
      title: Text('${d['bloodGroup']} • ${d['hospitalName'] ?? 'SOS'}'),
      subtitle: Text(
        '${d['status']} • ${d['remainingUnits'] ?? d['quantity'] ?? 1} unit(s) remaining',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestTrackingScreen(requestId: id),
            ),
          ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final mode = widget.mode;
    Query<Map<String, dynamic>> query;
    if (mode == 'active') {
      query = FirebaseFirestore.instance
          .collection('blood_requests')
          .where('acceptedDonorIds', arrayContains: uid)
          .orderBy(FieldPath.documentId);
    } else {
      query = FirebaseFirestore.instance
          .collection('blood_requests')
          .where('requesterId', isEqualTo: uid)
          .orderBy(FieldPath.documentId);
    }
    if (mode == 'sos')
      query = FirebaseFirestore.instance
          .collection('sosRequests')
          .where('receiverId', isEqualTo: uid)
          .orderBy(FieldPath.documentId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          mode == 'active'
              ? 'My Active Donations'
              : mode == 'sos'
              ? 'Active SOS & History'
              : mode == 'discover'
              ? 'Donation Opportunities'
              : 'My Requests & History',
        ),
      ),
      body:
          uid == null
              ? const Center(child: Text('Please sign in.'))
              : mode == 'discover'
              ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ..._items.map((d) => _tile(d, d['id'])),
                  if (_items.isEmpty && !_loading)
                    const Text(
                      'No matches on the pages checked. Continue searching or refresh later.',
                    ),
                  if (_error != null) Text(_error!),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (!_loading && _more)
                    TextButton(
                      onPressed: _load,
                      child: Text(
                        _error == null ? 'Search more requests' : 'Retry',
                      ),
                    ),
                ],
              )
              : PagedRecords(
                query: query,
                itemBuilder: (context, doc) {
                  final d = doc.data();
                  return _tile(
                    d,
                    mode == 'sos' ? d['requestId'] ?? doc.id : doc.id,
                  );
                },
              ),
    );
  }
}
