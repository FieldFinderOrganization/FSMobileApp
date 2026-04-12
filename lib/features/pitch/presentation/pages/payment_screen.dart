import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/pitch_entity.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../../data/models/payment_response_model.dart';
import 'booking_history_screen.dart';

class PaymentScreen extends StatefulWidget {
  final PitchEntity pitch;
  final String bookingId;
  final String userId;
  final PaymentResponseModel paymentResponse;
  final BookingCubit bookingCubit;

  const PaymentScreen({
    super.key,
    required this.pitch,
    required this.bookingId,
    required this.userId,
    required this.paymentResponse,
    required this.bookingCubit,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Start polling every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      widget.bookingCubit.checkPaymentStatus(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is BookingConfirmed) {
          _pollingTimer?.cancel();
          _showSuccessAndClose();
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textDark),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingHistoryScreen(userId: widget.userId),
                ),
              );
            },
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
              // ── QR Notice ──────────────────────────────────────────────────
              _buildNotice(),
              const SizedBox(height: 24),

              // ── QR Code ────────────────────────────────────────────────────
              _buildQRCode(),
              const SizedBox(height: 24),

              // ── Transfer Info ──────────────────────────────────────────────
              _buildTransferDetails(),
              const SizedBox(height: 24),

              // ── Booking Summary ────────────────────────────────────────────
              _buildBookingInfo(),
              const SizedBox(height: 32),

              // ── Status Polling Indicator ───────────────────────────────────
              _buildPollingStatus(),
              const SizedBox(height: 40),
            ],
          ),
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
          _buildDetailRow('Tên chủ sân', widget.paymentResponse.ownerName ?? 'Chưa cập nhật'),
          const Divider(height: 24),
          _buildDetailRow('Số tài khoản', widget.paymentResponse.ownerCardNumber ?? 'Chưa cập nhật', isCopyable: true),
          const Divider(height: 24),
          _buildDetailRow('Ngân hàng', widget.paymentResponse.ownerBank ?? 'Chưa cập nhật'),
          const Divider(height: 24),
          _buildDetailRow(
            'Số tiền',
            '${widget.paymentResponse.amount}k đ',
            valueColor: AppColors.primaryRed,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryItem('Sân bóng', widget.pitch.name),
          const SizedBox(height: 8),
          _buildSummaryItem('Ngày đặt', DateFormat('dd/MM/yyyy').format(widget.bookingCubit.date)),
          const SizedBox(height: 8),
          _buildSummaryItem('Trạng thái', 'Đang chờ thanh toán'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCopyable = false, Color? valueColor, bool isBold = false}) {
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
              const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF1B5E20)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
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

  void _showSuccessAndClose() {
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
              'Đơn đặt sân của bạn đã được xác nhận.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingHistoryScreen(userId: widget.userId),
                  ),
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
