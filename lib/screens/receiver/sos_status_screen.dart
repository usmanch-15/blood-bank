import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workflow_service.dart';
import '../requests/request_tracking_screen.dart';

/// Receiver-owned SOS status view. It uses the existing authorized callables
/// and linked request instead of introducing a second SOS data model.
class SosStatusScreen extends StatefulWidget {
  final String sosId;
  final String requestId;
  const SosStatusScreen({
    super.key,
    required this.sosId,
    required this.requestId,
  });

  @override
  State<SosStatusScreen> createState() => _SosStatusScreenState();
}

class _SosStatusScreenState extends State<SosStatusScreen> {
  late Future<_SosSnapshot> _future;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _future = _load());
    });
  }

  Future<_SosSnapshot> _load() async {
    final sos = await WorkflowService.call('getSos', {'sosId': widget.sosId});
    final request = await WorkflowService.request(widget.requestId);
    return _SosSnapshot(sos: sos, request: request);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cancel() async {
    try {
      await WorkflowService.call('resolveSos', {
        'sosId': widget.sosId,
        'cancel': true,
      });
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.sosAlert)),
      body: FutureBuilder<_SosSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(l.retry, () => setState(() => _future = _load()));
          }
          final value = snapshot.data!;
          final sosStatus = '${value.sos['status'] ?? 'unknown'}';
          final requestStatus = '${value.request['status'] ?? 'unknown'}';
          final closed =
              value.sos['isResolved'] == true ||
              {'cancelled', 'expired', 'fulfilled'}.contains(requestStatus);
          final commitments =
              (value.request['commitments'] as Map?) ?? const {};
          final active =
              commitments.entries.where((entry) {
                final status = (entry.value as Map?)?['status'];
                return {
                  'accepted',
                  'agreed',
                  'awaiting_confirmation',
                  'completed',
                }.contains(status);
              }).toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _statusCard(
                'SOS status',
                sosStatus,
                value.sos['isResolved'] == true,
              ),
              _statusCard(
                'Linked request',
                requestStatus,
                requestStatus == 'fulfilled',
              ),
              const SizedBox(height: 12),
              Text(
                'Emergency response timeline',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.emergency),
                title: const Text('SOS submitted'),
                subtitle: Text(sosStatus),
              ),
              ListTile(
                leading: const Icon(Icons.people_alt_outlined),
                title: const Text('Donor responses'),
                subtitle: Text('${active.length} active donor response(s)'),
              ),
              ListTile(
                leading: const Icon(Icons.bloodtype),
                title: const Text('Fulfillment progress'),
                subtitle: Text(
                  '${value.request['donatedUnits'] ?? 0} of ${value.request['quantity'] ?? 1} unit(s) confirmed',
                ),
              ),
              if (active.isEmpty && !closed)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No eligible donor has responded yet. The SOS remains active.',
                    ),
                  ),
                ),
              if (closed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'This SOS is ${value.sos['isResolved'] == true ? 'resolved' : requestStatus}.',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RequestTrackingScreen(
                              requestId: widget.requestId,
                            ),
                      ),
                    ),
                icon: const Icon(Icons.timeline),
                label: const Text('Open linked request'),
              ),
              if (!closed)
                FilledButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel SOS'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(String title, String status, bool complete) => Card(
    child: ListTile(
      leading: Icon(complete ? Icons.check_circle : Icons.pending_actions),
      title: Text(title),
      subtitle: Text(status),
    ),
  );

  Widget _message(String retry, VoidCallback onRetry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Unable to load SOS status.'),
        TextButton(onPressed: onRetry, child: Text(retry)),
      ],
    ),
  );
}

class _SosSnapshot {
  final Map<String, dynamic> sos;
  final Map<String, dynamic> request;
  const _SosSnapshot({required this.sos, required this.request});
}
