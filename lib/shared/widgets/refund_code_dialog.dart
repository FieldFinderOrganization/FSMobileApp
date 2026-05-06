import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../features/refund/data/models/refund_request_model.dart';

/// Dialog hiển thị mã hoàn tiền vừa được phát hành.
/// Trả về 'wallet' nếu user bấm "Xem trong ví", ngược lại null.
class RefundCodeDialog extends StatelessWidget {
  final RefundRequestModel refund;

  const RefundCodeDialog({super.key, required this.refund});

  static Future<String?> show(
    BuildContext context, {
    required RefundRequestModel refund,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RefundCodeDialog(refund: refund),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currFmt =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hủy thành công · Đã hoàn tiền',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mã hoàn tiền đã được thêm vào ví của bạn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 18),
          // Code box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFC107)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã hoàn tiền',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF7B5800),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        refund.refundCode ?? '—',
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7B5800),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép',
                  icon: const Icon(Icons.copy_rounded,
                      color: Color(0xFFFF8F00), size: 20),
                  onPressed: refund.refundCode == null
                      ? null
                      : () async {
                          await Clipboard.setData(
                              ClipboardData(text: refund.refundCode!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã sao chép mã ${refund.refundCode}',
                                  style: GoogleFonts.inter(),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _kv('Giá trị', currFmt.format(refund.amount)),
          if (refund.expiryDate != null)
            _kv('Hết hạn', dateFmt.format(refund.expiryDate!)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, 'wallet'),
                  child: Text(
                    'Xem trong ví',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textGrey)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }
}
