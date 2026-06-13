import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/datasources/call_remote_datasource.dart';
import '../../data/datasources/call_signaling_service.dart';
import '../../data/services/webrtc_service.dart';
import 'call_state.dart';

/// Các loại tín hiệu cuộc gọi trao đổi qua [CallSignalingService].
class CallSignalType {
  static const invite = 'CALL_INVITE';
  static const answer = 'CALL_ANSWER';
  static const ice = 'CALL_ICE';
  static const reject = 'CALL_REJECT';
  static const hangup = 'CALL_HANGUP';
  static const cancel = 'CALL_CANCEL';
  static const busy = 'CALL_BUSY';
}

/// Máy trạng thái cuộc gọi thoại 1-1 (Phase 1). Sống toàn cục như NotificationCubit:
/// signaling always-on để đổ chuông ở mọi màn; chỉ caller ghi CallLog (tránh trùng).
class CallCubit extends Cubit<CallState> {
  final CallSignalingService signaling;
  final CallRemoteDatasource remote;

  String _currentUserId = '';
  String _currentUserName = 'Người dùng';

  WebRtcService? _rtc;
  RTCSessionDescription? _pendingOffer; // offer của cuộc gọi đến, chờ accept
  Timer? _ringTimeout;
  Timer? _durationTimer;
  bool _connectedOnce = false;

  // Renderers cho video — giữ ngoài state (không Equatable). UI đọc qua getter,
  // state.remoteVideoReady trigger rebuild khi stream remote về.
  RTCVideoRenderer? localRenderer;
  RTCVideoRenderer? remoteRenderer;

  static const _ringTimeoutSec = 45;

  CallCubit({required this.signaling, required this.remote})
      : super(const CallState());

  /// Gọi sau login (MainShell) — mở socket signaling.
  Future<void> start(String userId, String userName) async {
    _currentUserId = userId;
    _currentUserName = userName.isEmpty ? 'Người dùng' : userName;
    await signaling.connect(userId: userId, onSignal: _onSignal);
  }

  // ---------------------- Bắt đầu / nhận cuộc gọi ----------------------

  Future<void> startCall(String peerId, String peerName,
      {bool video = false}) async {
    if (state.isActive) return;
    if (!await _ensurePermissions(video)) return;

    final callId = '${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    _connectedOnce = false;
    emit(CallState(
      phase: CallPhase.outgoing,
      callId: callId,
      peerId: peerId,
      peerName: peerName,
      isCaller: true,
      isVideo: video,
      speakerOn: video, // video mặc định bật loa ngoài
    ));

    final ice = await remote.fetchIceServers(_currentUserId);
    _rtc = _buildRtc(peerId, callId);
    await _rtc!.init(ice, video: video);
    await _setupRenderers(video);
    if (video) await _rtc!.setSpeakerphone(true);
    final offer = await _rtc!.createOffer();

    signaling.send({
      'type': CallSignalType.invite,
      'callId': callId,
      'fromId': _currentUserId,
      'fromName': _currentUserName,
      'toId': peerId,
      'media': video ? 'VIDEO' : 'AUDIO',
      'sdp': offer.toMap(),
    });

    _ringTimeout = Timer(const Duration(seconds: _ringTimeoutSec), () {
      if (state.phase == CallPhase.outgoing) {
        signaling.send({
          'type': CallSignalType.cancel,
          'callId': callId,
          'toId': peerId,
        });
        _logResult('MISSED');
        _endLocal('missed');
      }
    });
  }

  Future<void> accept() async {
    if (state.phase != CallPhase.incoming || _pendingOffer == null) return;
    final video = state.isVideo;
    if (!await _ensurePermissions(video)) {
      reject();
      return;
    }
    _ringTimeout?.cancel();
    final peerId = state.peerId!;
    final callId = state.callId!;
    emit(state.copyWith(phase: CallPhase.connecting, speakerOn: video));

    final ice = await remote.fetchIceServers(_currentUserId);
    _rtc = _buildRtc(peerId, callId);
    await _rtc!.init(ice, video: video);
    await _setupRenderers(video);
    if (video) await _rtc!.setSpeakerphone(true);
    await _rtc!.setRemoteDescription(_pendingOffer!);
    final answer = await _rtc!.createAnswer();
    _pendingOffer = null;

    signaling.send({
      'type': CallSignalType.answer,
      'callId': callId,
      'fromId': _currentUserId,
      'toId': peerId,
      'sdp': answer.toMap(),
    });
  }

  void reject() {
    if (state.peerId != null) {
      signaling.send({
        'type': CallSignalType.reject,
        'callId': state.callId,
        'toId': state.peerId,
      });
    }
    // Callee từ chối — caller sẽ ghi REJECTED khi nhận tín hiệu.
    _endLocal('rejected');
  }

  void hangup() {
    final peerId = state.peerId;
    if (peerId != null) {
      signaling.send({
        'type': CallSignalType.hangup,
        'callId': state.callId,
        'toId': peerId,
      });
    }
    if (state.isCaller) {
      _logResult(_connectedOnce ? 'ANSWERED' : 'CANCELED');
    }
    _endLocal('hangup');
  }

  // ---------------------- Xử lý tín hiệu đến ----------------------

  void _onSignal(Map<String, dynamic> s) {
    final type = s['type'] as String?;
    switch (type) {
      case CallSignalType.invite:
        _onInvite(s);
        break;
      case CallSignalType.answer:
        _onAnswer(s);
        break;
      case CallSignalType.ice:
        _onRemoteIce(s);
        break;
      case CallSignalType.reject:
        _endLocal('rejected');
        if (state.isCaller) _logResult('REJECTED');
        break;
      case CallSignalType.busy:
        _endLocal('busy');
        if (state.isCaller) _logResult('MISSED');
        break;
      case CallSignalType.cancel:
        _endLocal('canceled');
        break;
      case CallSignalType.hangup:
        final wasConnected = _connectedOnce;
        if (state.isCaller) _logResult(wasConnected ? 'ANSWERED' : 'CANCELED');
        _endLocal('hangup');
        break;
    }
  }

  void _onInvite(Map<String, dynamic> s) {
    final fromId = s['fromId'] as String?;
    if (fromId == null) return;
    // Đang bận cuộc khác → báo BUSY, không làm gián đoạn cuộc hiện tại.
    if (state.isActive) {
      signaling.send({
        'type': CallSignalType.busy,
        'callId': s['callId'],
        'toId': fromId,
      });
      return;
    }
    final sdp = s['sdp'] as Map<String, dynamic>?;
    if (sdp == null) return;
    _pendingOffer = RTCSessionDescription(
        sdp['sdp'] as String?, sdp['type'] as String?);
    _connectedOnce = false;
    final isVideo = (s['media'] as String?) == 'VIDEO';
    emit(CallState(
      phase: CallPhase.incoming,
      callId: s['callId'] as String?,
      peerId: fromId,
      peerName: (s['fromName'] as String?) ?? 'Người dùng',
      isCaller: false,
      isVideo: isVideo,
    ));
    _ringTimeout = Timer(const Duration(seconds: _ringTimeoutSec + 5), () {
      if (state.phase == CallPhase.incoming) _endLocal('missed');
    });
  }

  Future<void> _onAnswer(Map<String, dynamic> s) async {
    if (state.phase != CallPhase.outgoing &&
        state.phase != CallPhase.connecting) {
      return;
    }
    final sdp = s['sdp'] as Map<String, dynamic>?;
    if (sdp == null || _rtc == null) return;
    await _rtc!.setRemoteDescription(
        RTCSessionDescription(sdp['sdp'] as String?, sdp['type'] as String?));
    emit(state.copyWith(phase: CallPhase.connecting));
  }

  Future<void> _onRemoteIce(Map<String, dynamic> s) async {
    final c = s['candidate'] as Map<String, dynamic>?;
    if (c == null || _rtc == null) return;
    await _rtc!.addRemoteCandidate(RTCIceCandidate(
      c['candidate'] as String?,
      c['sdpMid'] as String?,
      (c['sdpMLineIndex'] as num?)?.toInt(),
    ));
  }

  // ---------------------- Điều khiển trong cuộc ----------------------

  void toggleMute() {
    final next = !state.micMuted;
    _rtc?.setMicEnabled(!next);
    emit(state.copyWith(micMuted: next));
  }

  void toggleSpeaker() {
    final next = !state.speakerOn;
    _rtc?.setSpeakerphone(next);
    emit(state.copyWith(speakerOn: next));
  }

  void toggleCamera() {
    if (!state.isVideo) return;
    final off = !state.cameraOff;
    _rtc?.setCameraEnabled(!off);
    emit(state.copyWith(cameraOff: off));
  }

  void switchCamera() {
    if (!state.isVideo) return;
    _rtc?.switchCamera();
  }

  // ---------------------- Nội bộ ----------------------

  WebRtcService _buildRtc(String peerId, String callId) {
    final rtc = WebRtcService();
    rtc.onLocalCandidate = (cand) {
      signaling.send({
        'type': CallSignalType.ice,
        'callId': callId,
        'toId': peerId,
        'candidate': cand.toMap(),
      });
    };
    rtc.onRemoteStream = (stream) {
      remoteRenderer?.srcObject = stream;
      if (!state.remoteVideoReady) {
        emit(state.copyWith(remoteVideoReady: true));
      }
    };
    rtc.onConnected = () {
      _connectedOnce = true;
      if (state.phase != CallPhase.connected) {
        emit(state.copyWith(phase: CallPhase.connected, durationSec: 0));
        _startDurationTimer();
      }
    };
    rtc.onClosed = () {
      if (state.isActive) {
        if (state.isCaller) _logResult(_connectedOnce ? 'ANSWERED' : 'CANCELED');
        _endLocal('failed');
      }
    };
    return rtc;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase == CallPhase.connected) {
        emit(state.copyWith(durationSec: state.durationSec + 1));
      }
    });
  }

  /// Khởi tạo renderer cho video call + gắn local stream. Audio call bỏ qua.
  Future<void> _setupRenderers(bool video) async {
    if (!video) return;
    localRenderer = RTCVideoRenderer();
    remoteRenderer = RTCVideoRenderer();
    await localRenderer!.initialize();
    await remoteRenderer!.initialize();
    localRenderer!.srcObject = _rtc!.localStream;
  }

  Future<void> _disposeRenderers() async {
    try {
      localRenderer?.srcObject = null;
      remoteRenderer?.srcObject = null;
      await localRenderer?.dispose();
      await remoteRenderer?.dispose();
    } catch (_) {}
    localRenderer = null;
    remoteRenderer = null;
  }

  Future<bool> _ensurePermissions(bool video) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return false;
    }
    return true;
  }

  void _logResult(String status) {
    final peerId = state.peerId;
    if (peerId == null || _currentUserId.isEmpty) return;
    // Caller là sender; callee là receiver (X gọi cho Y).
    remote
        .logCall(
          senderId: _currentUserId,
          receiverId: peerId,
          status: status,
          durationSec: status == 'ANSWERED' ? state.durationSec : 0,
          media: state.isVideo ? 'VIDEO' : 'AUDIO',
        )
        .catchError((_) {});
  }

  void _endLocal(String reason) {
    _ringTimeout?.cancel();
    _durationTimer?.cancel();
    final rtc = _rtc;
    _rtc = null;
    _pendingOffer = null;
    rtc?.dispose();
    _disposeRenderers();
    emit(state.copyWith(phase: CallPhase.ended, endReason: reason));
    // Reset về idle để global listener pop màn hình và sẵn sàng cuộc mới.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (state.phase == CallPhase.ended) emit(const CallState());
    });
  }

  void stop() {
    signaling.disconnect();
    _ringTimeout?.cancel();
    _durationTimer?.cancel();
    _rtc?.dispose();
    _rtc = null;
    _disposeRenderers();
    emit(const CallState());
  }

  @override
  Future<void> close() {
    signaling.disconnect();
    _ringTimeout?.cancel();
    _durationTimer?.cancel();
    _rtc?.dispose();
    _disposeRenderers();
    return super.close();
  }
}
