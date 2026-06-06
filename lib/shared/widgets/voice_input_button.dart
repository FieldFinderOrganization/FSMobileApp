import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/voice/voice_input_service.dart';

/// Nút micro tái dùng cho nhập liệu bằng giọng nói (speech-to-text on-device).
///
/// Chạm để bắt đầu nghe, chạm lại để dừng. Trong lúc nghe, icon chuyển đỏ và
/// nhấp nháy nhẹ. Kết quả cuối được trả qua [onResult]; nếu cần xem trước theo
/// thời gian thực thì truyền thêm [onPartial].
class VoiceInputButton extends StatefulWidget {
  /// Gọi khi có text cuối cùng (người dùng dừng nói).
  final void Function(String text) onResult;

  /// Tuỳ chọn: gọi liên tục với kết quả tạm thời để hiển thị xem trước.
  final void Function(String partial)? onPartial;

  /// Cho phép bấm hay không (vd: khoá khi AI đang trả lời).
  final bool enabled;

  /// Màu icon khi không nghe.
  final Color idleColor;

  /// Kích thước icon.
  final double size;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onPartial,
    this.enabled = true,
    this.idleColor = AppColors.textGrey,
    this.size = 22,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _service = VoiceInputService.instance;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _service.isListening.addListener(_syncPulse);
  }

  void _syncPulse() {
    if (!mounted) return;
    if (_service.isListening.value) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  Future<void> _toggle() async {
    if (_service.isListening.value) {
      await _service.stop();
      return;
    }
    final ok = await _service.start(
      onResult: (text, isFinal) {
        if (text.isEmpty) return;
        if (isFinal) {
          widget.onResult(text);
        } else {
          widget.onPartial?.call(text);
        }
      },
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Cần cấp quyền micro để dùng tìm kiếm bằng giọng nói'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _service.isListening.removeListener(_syncPulse);
    // Dừng nghe nếu widget bị huỷ khi đang nghe (vd: rời màn hình).
    if (_service.isListening.value) _service.stop();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _service.isListening,
      builder: (context, listening, _) {
        return IconButton(
          onPressed: widget.enabled ? _toggle : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          tooltip:
              listening ? 'Đang nghe… chạm để dừng' : 'Tìm bằng giọng nói',
          icon: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.25).animate(
              CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            ),
            child: Icon(
              listening ? Icons.mic : Icons.mic_none_rounded,
              color: widget.enabled
                  ? (listening ? AppColors.primaryRed : widget.idleColor)
                  : Colors.grey,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}
