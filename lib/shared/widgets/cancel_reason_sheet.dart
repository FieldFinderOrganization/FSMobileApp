import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class CancelReasonOption {
  final String key;
  final String label;
  const CancelReasonOption(this.key, this.label);
}

class CancelReasonResult {
  final String key;
  final String? freeText;
  const CancelReasonResult(this.key, this.freeText);

  /// Đóng gói cho field `reason` ở BE: "KEY" hoặc "KEY:freeText".
  String encode() =>
      (freeText == null || freeText!.trim().isEmpty)
          ? key
          : '$key:${freeText!.trim()}';
}

/// Bottom sheet chọn lý do hủy (Shopee/TikTok style).
/// Order/Booking dùng list khác nhau qua `options`.
class CancelReasonSheet extends StatefulWidget {
  final String title;
  final List<CancelReasonOption> options;
  final String confirmLabel;
  final bool willIssueRefund;
  final String? paymentMethod;

  const CancelReasonSheet({
    super.key,
    required this.title,
    required this.options,
    this.confirmLabel = 'Xác nhận hủy',
    this.willIssueRefund = false,
    this.paymentMethod,
  });

  static Future<CancelReasonResult?> show(
    BuildContext context, {
    required String title,
    required List<CancelReasonOption> options,
    String confirmLabel = 'Xác nhận hủy',
    bool willIssueRefund = false,
    String? paymentMethod,
  }) {
    return showModalBottomSheet<CancelReasonResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CancelReasonSheet(
        title: title,
        options: options,
        confirmLabel: confirmLabel,
        willIssueRefund: willIssueRefund,
        paymentMethod: paymentMethod,
      ),
    );
  }

  /// Lý do mặc định cho hủy đơn sản phẩm.
  static const List<CancelReasonOption> orderReasons = [
    CancelReasonOption('CHANGED_MIND', 'Đổi ý không muốn mua nữa'),
    CancelReasonOption('WRONG_ITEM', 'Đặt nhầm sản phẩm / kích cỡ'),
    CancelReasonOption('FOUND_BETTER_PRICE', 'Tìm được giá tốt hơn ở nơi khác'),
    CancelReasonOption('DELIVERY_TOO_SLOW', 'Thời gian giao hàng quá lâu'),
    CancelReasonOption('OTHER', 'Lý do khác'),
  ];

  /// Lý do cho provider hủy đơn đặt sân của khách.
  static const List<CancelReasonOption> providerBookingReasons = [
    CancelReasonOption('PITCH_MAINTENANCE', 'Sân bảo trì / gặp sự cố'),
    CancelReasonOption('WEATHER', 'Thời tiết xấu'),
    CancelReasonOption('CANNOT_SERVE', 'Không thể phục vụ khung giờ này'),
    CancelReasonOption('OTHER', 'Lý do khác'),
  ];

  /// Lý do mặc định cho hủy đặt sân.
  static const List<CancelReasonOption> bookingReasons = [
    CancelReasonOption('SCHEDULE_CONFLICT', 'Bận đột xuất, không sắp xếp được'),
    CancelReasonOption('WRONG_TIME_PITCH', 'Đặt nhầm sân / khung giờ'),
    CancelReasonOption('WEATHER', 'Thời tiết xấu'),
    CancelReasonOption('FOUND_BETTER_PITCH', 'Tìm được sân khác phù hợp hơn'),
    CancelReasonOption('OTHER', 'Lý do khác'),
  ];

  /// Bảng tra KEY → nhãn tiếng Việt, gộp từ mọi nhóm lý do (1 nguồn, không lệch).
  static final Map<String, String> _reasonLabels = {
    for (final o in [...orderReasons, ...providerBookingReasons, ...bookingReasons])
      o.key: o.label,
  };

  /// Đổi chuỗi `reason` của BE (dạng "KEY" hoặc "KEY:freeText") sang tiếng Việt
  /// để hiển thị. Dùng ở mọi nơi show lý do hủy.
  /// - KEY đã biết  → nhãn tiếng Việt.
  /// - "OTHER:text" → chính nội dung người dùng nhập.
  /// - Không khớp KEY (vd lý do hệ thống tự sinh "Sân tạm ngưng...") → giữ nguyên.
  static String decodeReason(String? raw, {String fallback = 'Không có lý do'}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return fallback;
    final idx = value.indexOf(':');
    final key = idx >= 0 ? value.substring(0, idx) : value;
    final rest = idx >= 0 ? value.substring(idx + 1).trim() : '';
    final label = _reasonLabels[key];
    if (label == null) return value; // text tiếng Việt sẵn / không xác định
    if (key == 'OTHER') return rest.isNotEmpty ? rest : label;
    return rest.isNotEmpty ? '$label ($rest)' : label;
  }

  @override
  State<CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<CancelReasonSheet> {
  String? _selectedKey;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  bool get _isOther => _selectedKey == 'OTHER';

  bool get _canConfirm =>
      _selectedKey != null &&
      (!_isOther || _otherCtrl.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (widget.willIssueRefund &&
                widget.paymentMethod?.toUpperCase() == 'BANK') ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.savings_rounded,
                          color: Color(0xFF16A34A), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn sẽ nhận được hoàn 100% tiền về tài khoản trong '
                        'vòng 24h, sau thời gian đó nếu tài khoản không nhận '
                        'được thanh toán, bạn sẽ nhận được voucher đền bù, '
                        'nếu không muốn nhận voucher, vui lòng liên hệ admin '
                        'để chúng mình hoàn tiền nhé!',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF166534),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFF57F17), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nếu bạn chưa thêm tài khoản ngân hàng, bạn sẽ chỉ '
                        'nhận được mã hoàn tiền và không thể khiếu nại. '
                        'Vui lòng thêm tài khoản ngân hàng trong phần Cài đặt.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.options.length,
                itemBuilder: (_, i) {
                  final opt = widget.options[i];
                  final selected = _selectedKey == opt.key;
                  return RadioListTile<String>(
                    value: opt.key,
                    groupValue: _selectedKey,
                    activeColor: AppColors.primaryRed,
                    onChanged: (v) => setState(() => _selectedKey = v),
                    title: Text(
                      opt.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isOther)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  controller: _otherCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Nhập lý do của bạn...',
                    hintStyle:
                        GoogleFonts.inter(color: AppColors.textGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canConfirm
                      ? () => Navigator.pop(
                            context,
                            CancelReasonResult(
                              _selectedKey!,
                              _isOther ? _otherCtrl.text : null,
                            ),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.confirmLabel,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
