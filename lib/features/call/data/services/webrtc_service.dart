import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Bọc [RTCPeerConnection] cho cuộc gọi thoại/video (audio + video, Phase 1-2).
///
/// Cubit điều phối signaling; service này lo media + ICE. Candidate đến trước khi
/// có remote description sẽ được buffer rồi flush sau, tránh mất ICE.
class WebRtcService {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  bool _video = false;

  bool _remoteDescSet = false;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  void Function(RTCIceCandidate candidate)? onLocalCandidate;
  void Function()? onConnected;
  void Function()? onClosed;
  void Function(MediaStream stream)? onRemoteStream;

  bool get isReady => _pc != null;
  MediaStream? get localStream => _localStream;

  /// Tạo peer connection + lấy mic (và camera nếu [video]). Gọi 1 lần khi bắt
  /// đầu (caller) hoặc khi accept (callee).
  Future<void> init(List<Map<String, dynamic>> iceServers,
      {bool video = false}) async {
    _video = video;
    final config = <String, dynamic>{
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
    };
    _pc = await createPeerConnection(config);

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': 640,
              'height': 480,
              'frameRate': 24,
            }
          : false,
    });
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) onLocalCandidate?.call(candidate);
    };
    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onConnected?.call();
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        onClosed?.call();
      }
    };
    // Audio tự phát qua loa/tai nghe; video cần stream để gắn vào RTCVideoRenderer.
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) onRemoteStream?.call(event.streams.first);
    };
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await _pc!.createOffer(
        {'offerToReceiveAudio': true, 'offerToReceiveVideo': _video});
    await _pc!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await _pc!.createAnswer(
        {'offerToReceiveAudio': true, 'offerToReceiveVideo': _video});
    await _pc!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription desc) async {
    await _pc!.setRemoteDescription(desc);
    _remoteDescSet = true;
    for (final c in _pendingRemoteCandidates) {
      await _pc!.addCandidate(c);
    }
    _pendingRemoteCandidates.clear();
  }

  Future<void> addRemoteCandidate(RTCIceCandidate candidate) async {
    if (_pc == null) return;
    if (_remoteDescSet) {
      await _pc!.addCandidate(candidate);
    } else {
      _pendingRemoteCandidates.add(candidate);
    }
  }

  void setMicEnabled(bool enabled) {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = enabled);
  }

  void setCameraEnabled(bool enabled) {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = enabled);
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      try {
        await Helper.switchCamera(tracks.first);
      } catch (_) {}
    }
  }

  Future<void> setSpeakerphone(bool on) async {
    try {
      await Helper.setSpeakerphoneOn(on);
    } catch (_) {}
  }

  Future<void> dispose() async {
    _remoteDescSet = false;
    _pendingRemoteCandidates.clear();
    try {
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    _localStream = null;
    _pc = null;
  }
}
