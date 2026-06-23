import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/utils/money_utils.dart';
import '../../data/models/wallet_topup_model.dart';
import '../cubit/wallet_cubit.dart';

/// Màn nạp tiền vào ví: hiện QR PayOS, poll trạng thái tới khi BE xác nhận đã cộng ví.
class WalletTopupScreen extends StatefulWidget {
  final WalletTopupModel topup;
  final WalletCubit walletCubit;

  const WalletTopupScreen({
    super.key,
    required this.topup,
    required this.walletCubit,
  });

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  Timer? _pollTimer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_done) return;
    final status = await widget.walletCubit.pollTopupStatus(widget.topup.topupId);
    if (status == 'CREDITED' && !_done) {
      _done = true;
      _pollTimer?.cancel();
      await widget.walletCubit.load(); // làm mới số dư
      if (mounted) _showSuccess();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
        title: const Text('Nạp tiền vào ví'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          children: [
            _notice(),
            const SizedBox(height: 20),
            _qr(),
            const SizedBox(height: 20),
            _details(),
            const SizedBox(height: 28),
            _polling(),
          ],
        ),
      ),
    );
  }

  Widget _notice() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quét mã để chuyển khoản. Ví được cộng tự động sau khi hệ thống xác nhận giao dịch.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                    height: 1.4),
              ),
            ),
          ],
        ),
      );

  Widget _qr() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            if (widget.topup.qrCode != null)
              QrImageView(
                data: widget.topup.qrCode!,
                version: QrVersions.auto,
                size: 220,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: Color(0xFF1B5E20)),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1B5E20)),
              )
            else
              const SizedBox(
                  height: 220, child: Center(child: Text('Không thể tạo mã QR'))),
            const SizedBox(height: 12),
            const Text('Quét mã để nạp tiền',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );

  Widget _details() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            _row('Tên người nhận', 'Huynh Minh Triet'),
            const Divider(height: 24),
            _row('Số tài khoản', '0888696869'),
            const Divider(height: 24),
            _row('Ngân hàng', 'MB'),
            const Divider(height: 24),
            _row('Số tiền nạp', formatVnd(widget.topup.amount),
                valueColor: const Color(0xFF1B5E20), bold: true),
          ],
        ),
      );

  Widget _row(String label, String value, {Color? valueColor, bool bold = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? Colors.black87)),
        ],
      );

  Widget _polling() => Column(
        children: const [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)),
          ),
          SizedBox(height: 12),
          Text('Đang chờ xác nhận giao dịch...',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      );

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('NẠP TIỀN THÀNH CÔNG',
                style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Đã cộng ${formatVnd(widget.topup.amount)} vào ví của bạn.',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(d); // đóng dialog
                  Navigator.pop(context); // đóng màn nạp
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hoàn tất'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
