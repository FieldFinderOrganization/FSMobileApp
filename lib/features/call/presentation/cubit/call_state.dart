import 'package:equatable/equatable.dart';

enum CallPhase { idle, outgoing, incoming, connecting, connected, ended }

class CallState extends Equatable {
  final CallPhase phase;
  final String? callId;
  final String? peerId; // userId đầu bên kia
  final String? peerName;
  final bool isCaller;
  final bool micMuted;
  final bool speakerOn;
  final int durationSec; // chỉ tăng khi đã connected
  final String? endReason; // hangup | rejected | busy | canceled | missed | failed

  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.peerId,
    this.peerName,
    this.isCaller = false,
    this.micMuted = false,
    this.speakerOn = false,
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
    bool? micMuted,
    bool? speakerOn,
    int? durationSec,
    String? endReason,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId ?? this.callId,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      isCaller: isCaller ?? this.isCaller,
      micMuted: micMuted ?? this.micMuted,
      speakerOn: speakerOn ?? this.speakerOn,
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
        micMuted,
        speakerOn,
        durationSec,
        endReason,
      ];
}
