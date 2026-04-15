import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/checkout_item_entity.dart';
import '../../../pitch/data/datasources/payment_remote_datasource.dart';
import '../../../pitch/data/models/payment_response_model.dart';
import '../../../order/presentation/pages/order_history_screen.dart';

class ShopPaymentScreen extends StatefulWidget {
  final List<CheckoutItemEntity> items;
  final PaymentResponseModel paymentResponse;
  final String userId;
  final String orderId;
  final DioClient dioClient;

  const ShopPaymentScreen({
    super.key,
    required this.items,
    required this.paymentResponse,
    required this.userId,
    required this.orderId,
    required this.dioClient,
  });

  @override
  State<ShopPaymentScreen> createState() => _ShopPaymentScreenState();
}

class _ShopPaymentScreenState extends State<ShopPaymentScreen> {
  Timer? _pollingTimer;
  bool _showAll = false;
  static const int _initialItemCount = 3;

  late final PaymentRemoteDataSource _paymentDataSource;

  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _paymentDataSource = PaymentRemoteDataSource(dioClient: widget.dioClient);
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkPaymentStatus();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final status = await _paymentDataSource.getShopPaymentStatus(widget.orderId);
      if (status.isPaid) {
        _pollingTimer?.cancel();
        if (mounted) _showSuccessDialog();
      }
    } catch (_) {
      // silently ignore polling errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'THANH TOÁN CHUYỂN KHOẢN',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B5E20),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildNotice(),
            const SizedBox(height: 24),
            _buildQRCode(),
            const SizedBox(height: 24),
            _buildTransferDetails(),
            const SizedBox(height: 24),
            _buildProductList(),
            const SizedBox(height: 32),
            _buildPollingStatus(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
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
              'Hệ thống sẽ tự động xác nhận sau khi bạn chuyển khoản thành công.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
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
          if (widget.paymentResponse.qrCode != null)
            QrImageView(
              data: widget.paymentResponse.qrCode!,
              version: QrVersions.auto,
              size: 220.0,
              gapless: false,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1B5E20),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1B5E20),
              ),
            )
          else
            const SizedBox(
              height: 220,
              child: Center(child: Text('Không thể tạo mã QR')),
            ),
          const SizedBox(height: 16),
          Text(
            'Quét mã để thanh toán',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferDetails() {
    // Format amount: the API returns amount as a string (e.g. "120000")
    String formattedAmount;
    try {
      final amountNum = double.parse(widget.paymentResponse.amount);
      formattedAmount = '${_currencyFormat.format(amountNum)} đ';
    } catch (_) {
      formattedAmount = '${widget.paymentResponse.amount} đ';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Tên người nhận', 'Huynh Minh Triet'),
          const Divider(height: 24),
          _buildDetailRow('Số tài khoản', '0888696869', isCopyable: true),
          const Divider(height: 24),
          _buildDetailRow('Ngân hàng', 'MB'),
          const Divider(height: 24),
          _buildDetailRow(
            'Số tiền',
            formattedAmount,
            valueColor: AppColors.primaryRed,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final displayCount = _showAll ? widget.items.length : widget.items.length.clamp(0, _initialItemCount);
    final visibleItems = widget.items.take(displayCount).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sản phẩm đã đặt',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...visibleItems.map((item) => _buildProductItem(item)),
          if (widget.items.length > _initialItemCount) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Center(
                child: Text(
                  _showAll ? 'Ẩn bớt' : 'Xem thêm (${widget.items.length - _initialItemCount} sản phẩm)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductItem(CheckoutItemEntity item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported_outlined, size: 20, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Size: ${item.size} • SL: ${item.quantity}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_currencyFormat.format(item.totalPrice)} đ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isCopyable = false,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? AppColors.textDark,
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép: $value',
                          style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: const Color(0xFF1B5E20),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF1B5E20)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPollingStatus() {
    return Column(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 12),
        Text(
          'Đang chờ xác nhận từ ngân hàng...',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'THANH TOÁN THÀNH CÔNG',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn hàng của bạn đã được xác nhận.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderHistoryScreen(userId: widget.userId),
                  ),
                  (route) => route.isFirst,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      ),
    );
  }
}
