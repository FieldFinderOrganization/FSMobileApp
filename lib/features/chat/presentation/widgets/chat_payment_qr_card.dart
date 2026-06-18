import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_utils.dart';
import '../cubit/chat_cubit.dart';

/// Card QR thanh toán trong AI chat (action == 'payment_qr').
/// Tự poll trạng thái mỗi 5s đến khi PAID — trạng thái persist trong aiData
/// nên mở lại app vẫn tiếp tục check.
class ChatPaymentQrCard extends StatefulWidget {
  final String messageId;
  final Map<String, dynamic> aiData;

  const ChatPaymentQrCard({
    super.key,
    required this.messageId,
    required this.aiData,
  });

  @override
  State<ChatPaymentQrCard> createState() => _ChatPaymentQrCardState();
}

class _ChatPaymentQrCardState extends State<ChatPaymentQrCard> {
  Timer? _pollingTimer;

  bool get _isPaid => widget.aiData['paymentStatus'] == 'PAID';

  @override
  void initState() {
    super.initState();
    if (!_isPaid) {
      // Check ngay khi render (mở lại app giữa chừng) rồi poll định kỳ.
      context.read<ChatCubit>().checkChatPaymentStatus(widget.messageId);
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_isPaid) {
          _pollingTimer?.cancel();
          return;
        }
        context.read<ChatCubit>().checkChatPaymentStatus(widget.messageId);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ChatPaymentQrCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isPaid) _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String get _amountLabel {
    final amount = (widget.aiData['amount'] as num?)?.toDouble() ?? 0;
    return formatVnd(amount);
  }

  @override
  Widget build(BuildContext context) {
    final qrCode = widget.aiData['qrCode'] as String?;

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 60, top: 6, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isPaid ? Icons.verified_rounded : Icons.qr_code_2_rounded,
                size: 18,
                color: _isPaid ? Colors.green : AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isPaid
                      ? 'Đã thanh toán'
                      : 'Quét QR để chuyển khoản',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isPaid ? Colors.green.shade700 : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          if (_isPaid) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 36),
                  const SizedBox(height: 6),
                  Text(
                    'Đã nhận $_amountLabel',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            if (qrCode != null && qrCode.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: QrImageView(
                    data: qrCode,
                    version: QrVersions.auto,
                    size: 180,
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  'Không tạo được mã QR. Vui lòng thử lại.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textGrey),
                ),
              ),
            const SizedBox(height: 12),
            _detailRow('Số tiền', _amountLabel, bold: true),
            const SizedBox(height: 6),
            _detailRow('Người nhận',
                widget.aiData['ownerName'] as String? ?? 'Chưa cập nhật'),
            const SizedBox(height: 6),
            _detailRow('Số tài khoản',
                widget.aiData['ownerCardNumber'] as String? ?? 'Chưa cập nhật'),
            const SizedBox(height: 6),
            _detailRow('Ngân hàng',
                widget.aiData['ownerBank'] as String? ?? 'Chưa cập nhật'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang chờ thanh toán — tự động xác nhận',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textGrey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primaryRed : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
