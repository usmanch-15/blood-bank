import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VoiceCallSession {
  final String sessionId;
  final String appId;
  final String channel;
  final String token;
  final int uid;
  final String status;
  const VoiceCallSession({
    required this.sessionId,
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.status,
  });

  factory VoiceCallSession.fromMap(Map<String, dynamic> data) =>
      VoiceCallSession(
        sessionId: data['sessionId'] as String,
        appId: data['appId'] as String,
        channel: data['channel'] as String,
        token: data['token'] as String,
        uid: (data['uid'] as num).toInt(),
        status: data['status'] as String? ?? 'ringing',
      );
}

class VoiceCallService {
  static final _functions = FirebaseFunctions.instance;

  static Future<VoiceCallSession> create({
    required String requestId,
    required String calleeId,
  }) async {
    final result = await _functions
        .httpsCallable('createVoiceCallSession')
        .call({'requestId': requestId, 'calleeId': calleeId});
    return VoiceCallSession.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  static Future<VoiceCallSession> token(String sessionId) async {
    final result = await _functions.httpsCallable('getVoiceCallToken').call({
      'sessionId': sessionId,
    });
    return VoiceCallSession.fromMap(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  static Future<void> update(String sessionId, String status) async {
    await _functions.httpsCallable('updateVoiceCallSession').call({
      'sessionId': sessionId,
      'status': status,
    });
  }
}

class AgoraVoiceController {
  RtcEngine? _engine;
  Future<void> join(
    VoiceCallSession session, {
    required void Function(String) onState,
    void Function()? onTokenExpiring,
  }) async {
    final engine = createAgoraRtcEngine();
    _engine = engine;
    await engine.initialize(
      RtcEngineContext(
        appId: session.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) => onState('connecting'),
        onUserJoined: (_, __, ___) => onState('connected'),
        onUserOffline: (_, __, ___) => onState('ended'),
        onError: (err, _) => onState('error:$err'),
        onConnectionStateChanged: (_, state, __) => onState(state.name),
        onTokenPrivilegeWillExpire:
            (connection, token) => onTokenExpiring?.call(),
      ),
    );
    await engine.enableAudio();
    await engine.joinChannel(
      token: session.token,
      channelId: session.channel,
      uid: session.uid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> leave() async {
    final engine = _engine;
    _engine = null;
    if (engine == null) return;
    await engine.leaveChannel();
    await engine.release();
  }

  Future<void> setMuted(bool muted) async =>
      _engine?.muteLocalAudioStream(muted);
  Future<void> setSpeaker(bool enabled) async =>
      _engine?.setEnableSpeakerphone(enabled);
  Future<void> renewToken(String token) async {
    await _engine?.renewToken(token);
  }
}
