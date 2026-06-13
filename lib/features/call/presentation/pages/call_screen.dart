import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../cubit/call_cubit.dart';
import '../cubit/call_state.dart';

/// Màn cuộc gọi thoại — 1 màn cho mọi pha (gọi đi / gọi đến / đang gọi).
/// Được push/pop tự động bởi BlocListener toàn cục trong MyApp.
class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  String _statusText(CallState s) {
    switch (s.phase) {
      case CallPhase.outgoing:
        return 'Đang gọi…';
      case CallPhase.incoming:
        return 'Cuộc gọi thoại đến';
      case CallPhase.connecting:
        return 'Đang kết nối…';
      case CallPhase.connected:
        return _fmtDuration(s.durationSec);
      case CallPhase.ended:
        return _endText(s.endReason);
      case CallPhase.idle:
        return '';
    }
  }

  String _endText(String? reason) {
    switch (reason) {
      case 'rejected':
        return 'Cuộc gọi bị từ chối';
      case 'busy':
        return 'Máy bận';
      case 'canceled':
        return 'Đã hủy';
      case 'missed':
        return 'Không trả lời';
      case 'failed':
        return 'Mất kết nối';
      default:
        return 'Đã kết thúc';
    }
  }

  static String _fmtDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CallCubit>();
    return BlocBuilder<CallCubit, CallState>(
      builder: (context, state) {
        final name = state.peerName ?? 'Người dùng';
        final initial =
            name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && state.isActive) cubit.hangup();
          },
          child: Scaffold(
            backgroundColor: AppColors.midnightDeep,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.midnightMid, AppColors.midnightDeep],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.champagne.withValues(alpha: 0.2),
                      child: Text(
                        initial,
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: AppColors.champagne,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmIvory,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _statusText(state),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.warmIvory.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    _buildControls(context, cubit, state),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(
      BuildContext context, CallCubit cubit, CallState state) {
    if (state.phase == CallPhase.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            icon: Icons.call_end_rounded,
            color: AppColors.primaryRed,
            label: 'Từ chối',
            onTap: cubit.reject,
          ),
          _circleButton(
            icon: Icons.call_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Trả lời',
            onTap: cubit.accept,
          ),
        ],
      );
    }

    if (state.phase == CallPhase.ended) {
      return const SizedBox(height: 72);
    }

    // outgoing / connecting / connected
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleButton(
              icon: state.micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: state.micMuted
                  ? AppColors.warmIvory.withValues(alpha: 0.3)
                  : AppColors.midnightMid,
              label: state.micMuted ? 'Đã tắt mic' : 'Mic',
              onTap: cubit.toggleMute,
            ),
            const SizedBox(width: 28),
            _circleButton(
              icon: state.speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_down_rounded,
              color: state.speakerOn
                  ? AppColors.champagne.withValues(alpha: 0.3)
                  : AppColors.midnightMid,
              label: 'Loa ngoài',
              onTap: cubit.toggleSpeaker,
            ),
          ],
        ),
        const SizedBox(height: 36),
        _circleButton(
          icon: Icons.call_end_rounded,
          color: AppColors.primaryRed,
          label: 'Kết thúc',
          onTap: cubit.hangup,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: AppColors.warmIvory, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.warmIvory.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
