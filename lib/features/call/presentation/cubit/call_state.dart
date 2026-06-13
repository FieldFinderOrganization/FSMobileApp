import 'package:equatable/equatable.dart';

enum CallPhase { idle, outgoing, incoming, connecting, connected, ended }

class CallState extends Equatable {
  final CallPhase phase;
  final String? callId;
  final String? peerId; // userId đầu bên kia
  final String? peerName;
  final bool isCaller;
  final bool isVideo; // cuộc gọi video (true) hay thoại (false)
  final bool micMuted;
  final bool cameraOff; // camera của mình đang tắt
  final bool speakerOn;
  final bool remoteVideoReady; // đã nhận stream remote → hiển thị video remote
  final int durationSec; // chỉ tăng khi đã connected
  final String? endReason; // hangup | rejected | busy | canceled | missed | failed

  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.peerId,
    this.peerName,
    this.isCaller = false,
    this.isVideo = false,
    this.micMuted = false,
    this.cameraOff = false,
    this.speakerOn = false,
    this.remoteVideoReady = false,
    this.durationSec = 0,
    this.endReason,
  });

  bool get isActive => phase != CallPhase.idle && phase != CallPhase.ended;

  CallState copyWith({
    CallPhase? phase,
    String? callId,
    String? peerId,
    String? peerName,
    bool? isCaller,
    bool? isVideo,
    bool? micMuted,
    bool? cameraOff,
    bool? speakerOn,
    bool? remoteVideoReady,
    int? durationSec,
    String? endReason,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId ?? this.callId,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      isCaller: isCaller ?? this.isCaller,
      isVideo: isVideo ?? this.isVideo,
      micMuted: micMuted ?? this.micMuted,
      cameraOff: cameraOff ?? this.cameraOff,
      speakerOn: speakerOn ?? this.speakerOn,
      remoteVideoReady: remoteVideoReady ?? this.remoteVideoReady,
      durationSec: durationSec ?? this.durationSec,
      endReason: endReason ?? this.endReason,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        callId,
        peerId,
        peerName,
        isCaller,
        isVideo,
        micMuted,
        cameraOff,
        speakerOn,
        remoteVideoReady,
        durationSec,
        endReason,
      ];
}
