import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Text countdown rebuild theo Timer cho cửa sổ hủy (24h order / 10p booking).
/// `tickInterval` ngắn → countdown sống (mm:ss). Dài → tiết kiệm rebuild.
class CancelWindowCountdown extends StatefulWidget {
  final DateTime deadline;
  final Duration tickInterval;
  final String prefix;
  final String expiredLabel;
  final TextStyle? style;

  const CancelWindowCountdown({
    super.key,
    required this.deadline,
    this.tickInterval = const Duration(seconds: 30),
    this.prefix = 'Còn ',
    this.expiredLabel = 'Đã quá hạn hủy',
    this.style,
  });

  @override
  State<CancelWindowCountdown> createState() => _CancelWindowCountdownState();
}

class _CancelWindowCountdownState extends State<CancelWindowCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.tickInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration remaining) {
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return widget.expiredLabel;
    }
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;

    if (h > 0) {
      return '${widget.prefix}${h}h ${m}m để được hủy & hoàn tiền';
    }
    if (m > 0) {
      // Hiển thị mm:ss khi <1h
      final ss = s.toString().padLeft(2, '0');
      return '${widget.prefix}${m}p ${ss}s để được hủy & hoàn tiền';
    }
    return '${widget.prefix}${s}s để được hủy & hoàn tiền';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final isExpired = remaining.isNegative || remaining.inSeconds <= 0;
    return Text(
      _format(remaining),
      style: widget.style ??
          GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isExpired ? Colors.grey : AppColors.primaryRed,
          ),
    );
  }
}
