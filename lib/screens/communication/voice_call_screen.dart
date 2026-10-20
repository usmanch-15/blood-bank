import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/voice_call_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/premium_states.dart';
import 'dart:async';

class VoiceCallScreen extends StatefulWidget {
  final String requestId;
  final String calleeId;
  final String? incomingSessionId;
  const VoiceCallScreen({
    super.key,
    this.requestId = '',
    this.calleeId = '',
    this.incomingSessionId,
  });
  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with WidgetsBindingObserver {
  final _rtc = AgoraVoiceController();
  VoiceCallSession? _session;
  String _state = 'connecting';
  String? _error;
  bool _ending = false;
  bool _answered = false;
  bool _answering = false;
  bool _muted = false, _speaker = false;
  Timer? _ringTimer;
  bool get _incoming => widget.incomingSessionId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    try {
      if (!_incoming && !await _microphone()) return;
      final session =
          widget.incomingSessionId == null
              ? await VoiceCallService.create(
                requestId: widget.requestId,
                calleeId: widget.calleeId,
              )
              : await VoiceCallService.token(widget.incomingSessionId!);
      _session = session;
      if (!mounted) return;
      if (_incoming && session.status == 'ringing') {
        if (mounted) setState(() => _state = 'ringing');
        _ringTimer = Timer(const Duration(seconds: 45), () { _end(); });
        return;
      }
      await _join(session);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _join(VoiceCallSession session) async {
    if (_incoming && !await _microphone()) return;
    if (_incoming && session.status == 'ringing') {
      await VoiceCallService.update(session.sessionId, 'accepted');
      _answered = true;
    }
    if (!mounted) return;
    await _rtc.join(
      session,
        onState: (value) {
        if (mounted) setState(() => _state = value == 'connected' ? 'connected' : (value.contains('failed') || value.contains('disconnected') || value.contains('reconnecting')) ? 'failed' : value);
      },
      onTokenExpiring: () async {
        final current = _session;
        if (current == null) return;
        try {
          final refreshed = await VoiceCallService.token(current.sessionId);
          await _rtc.renewToken(refreshed.token);
          _session = refreshed;
        } catch (_) {
          if (mounted) setState(() => _error = AppLocalizations.of(context).callConnectionLost);
        }
      },
    );
    // Joining the local channel is not evidence that the peer answered.
  }

  Future<bool> _microphone() async {
    final permission = await Permission.microphone.request();
    if (!mounted) return false;
    if (!permission.isGranted) {
      setState(() => _error = AppLocalizations.of(context).microphoneRequired);
      showPermissionDeniedSheet(context, 'Microphone');
      return false;
    }
    return true;
  }

  Future<void> _answer() async {
    final session = _session;
    if (session == null || _ending || _answering) return;
    setState(() => _answering = true);
    try {
      await _join(session);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _answering = false);
    }
  }

  Future<void> _end() async {
    if (_ending) return;
    _ending = true;
    _ringTimer?.cancel();
    final session = _session;
    if (session != null) {
      final status =
          session.status == 'ringing' && !_answered && _state != 'connected'
              ? (_incoming ? 'rejected' : 'missed')
              : 'ended';
      try {
        await VoiceCallService.update(session.sessionId, status);
      } catch (_) {}
    }
    await _rtc.leave();
    if (mounted) Navigator.pop(context, _state == 'connected');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ringTimer?.cancel();
    _rtc.leave();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && !_ending) _end();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.callInApp)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error == null ? Icons.phone_in_talk : Icons.error_outline,
                size: 72,
              ),
              const SizedBox(height: 20),
              Text(
                _error ?? (_state == 'failed' ? l.callConnectionLost :
                    (_state == 'ringing'
                        ? l.callRinging
                        : _state == 'connected'
                        ? l.callInApp
                        : l.callConnecting)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_incoming && _state == 'ringing') ...[
                FilledButton.icon(
                  onPressed: _ending || _answering ? null : _answer,
                  icon: const Icon(Icons.call),
                  label: Text(l.answerCall),
                ),
                const SizedBox(height: 12),
              ],
              if (_state == 'connected') Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: _ending ? null : () async { setState(() => _muted = !_muted); await _rtc.setMuted(_muted); }, icon: Icon(_muted ? Icons.mic_off : Icons.mic), tooltip: _muted ? l.unmuteCall : l.muteCall),
                IconButton(onPressed: _ending ? null : () async { setState(() => _speaker = !_speaker); await _rtc.setSpeaker(_speaker); }, icon: Icon(_speaker ? Icons.volume_up : Icons.volume_down), tooltip: _speaker ? l.speakerOff : l.speakerOn),
              ]),
              FilledButton.icon(
                onPressed: _ending ? null : _end,
                icon: const Icon(Icons.call_end),
                label: Text(
                  _incoming && _state == 'ringing' ? l.rejectCall : l.endCall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
