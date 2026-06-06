import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Bọc plugin [SpeechToText] cho nhận dạng giọng nói on-device (speech-to-text).
///
/// Dùng chung dạng singleton cho mọi nơi cần voice input — tài nguyên micro
/// native chỉ cho phép một phiên nghe tại một thời điểm. STT chạy ngay trên
/// thiết bị nên không gọi backend; chỉ sinh ra text rồi đẩy vào luồng có sẵn.
class VoiceInputService {
  VoiceInputService._();
  static final VoiceInputService instance = VoiceInputService._();

  final SpeechToText _speech = SpeechToText();

  /// Trạng thái đang nghe, để UI (nút mic) lắng nghe và đổi giao diện.
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);

  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;

  /// Khởi tạo plugin một lần (lần đầu sẽ xin quyền micro của hệ thống).
  /// Trả về true nếu thiết bị có thể nhận dạng giọng nói.
  Future<bool> ensureInit() async {
    if (_initialized) return _available;
    _available = await _speech.initialize(
      onError: (error) {
        debugPrint('[Voice] error: ${error.errorMsg} permanent=${error.permanent}');
        isListening.value = false;
      },
      onStatus: (status) {
        debugPrint('[Voice] status: $status');
        isListening.value = status == SpeechToText.listeningStatus;
      },
    );
    _initialized = true;
    return _available;
  }

  /// Bắt đầu nghe. [onResult] nhận text nhận dạng được kèm cờ [isFinal]
  /// (false = kết quả tạm thời, true = kết quả cuối khi người dùng dừng nói).
  /// Mặc định ưu tiên tiếng Việt; nếu thiết bị không có locale phù hợp thì để
  /// plugin tự dùng locale hệ thống.
  ///
  /// Trả về false nếu không khởi tạo được (vd: bị từ chối quyền micro).
  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
    String preferredLocaleId = 'vi_VN',
  }) async {
    if (!await ensureInit()) return false;
    if (_speech.isListening) await _speech.stop();

    final localeId = await _resolveLocale(preferredLocaleId);
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
    isListening.value = _speech.isListening;
    return true;
  }

  Future<void> stop() async {
    await _speech.stop();
    isListening.value = false;
  }

  /// Chọn locale: ưu tiên đúng [preferred] (vd `vi_VN`), nếu không có thì lấy
  /// bất kỳ locale tiếng Việt nào; nếu vẫn không có trả về null để plugin dùng
  /// locale mặc định của hệ thống.
  Future<String?> _resolveLocale(String preferred) async {
    try {
      final locales = await _speech.locales();
      String norm(String s) => s.replaceAll('-', '_');
      final exact = locales.where((l) => norm(l.localeId) == preferred);
      if (exact.isNotEmpty) return exact.first.localeId;
      final viAny =
          locales.where((l) => norm(l.localeId).toLowerCase().startsWith('vi'));
      if (viAny.isNotEmpty) return viAny.first.localeId;
    } catch (_) {
      // Một số thiết bị không trả về danh sách locale — rơi xuống mặc định.
    }
    return null;
  }
}
