import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/voice_call_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final String requestId;
  final String calleeId;
  final String? incomingSessionId;
  const VoiceCallScreen({super.key, required this.requestId, required this.calleeId, this.incomingSessionId});
  @override State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final _rtc = AgoraVoiceController();
  VoiceCallSession? _session;
  String _state = 'connecting';
  String? _error;
  bool _ending = false;

  @override void initState() { super.initState(); _start(); }
  Future<void> _start() async {
    try {
      final session = widget.incomingSessionId == null
          ? await VoiceCallService.create(requestId: widget.requestId, calleeId: widget.calleeId)
          : await VoiceCallService.token(widget.incomingSessionId!);
      _session = session;
      if (widget.incomingSessionId != null && session.status == 'ringing') await VoiceCallService.update(session.sessionId, 'accepted');
      await _rtc.join(session, onState: (value) { if (mounted) setState(() => _state = value); });
      if (mounted) setState(() => _state = 'connected');
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
  }
  Future<void> _end() async {
    if (_ending) return; _ending = true;
    try { if (_session != null) await VoiceCallService.update(_session!.sessionId, 'ended'); } catch (_) {}
    await _rtc.leave();
    if (mounted) Navigator.pop(context);
  }
  @override void dispose() { _rtc.leave(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(appBar: AppBar(title: Text(l.callInApp)), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(_error == null ? Icons.phone_in_talk : Icons.error_outline, size: 72),
      const SizedBox(height: 20),
      Text(_error ?? (_state == 'connected' ? l.callInApp : l.callConnecting), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: _ending ? null : _end, icon: const Icon(Icons.call_end), label: Text(l.endCall)),
    ]))));
  }
}
