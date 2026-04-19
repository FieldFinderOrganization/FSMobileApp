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
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../../../core/network/dio_client.dart';
import 'booking_history_screen.dart';

class PaymentScreen extends StatefulWidget {
  final PitchEntity pitch;
  final String bookingId;
  final String userId;
  final PaymentResponseModel paymentResponse;
  final BookingCubit? bookingCubit;
  final DateTime? deadline;
  final String? bookingDate; // ISO date string, used when bookingCubit is null

  const PaymentScreen({
    super.key,
    required this.pitch,
    required this.bookingId,
    required this.userId,
    required this.paymentResponse,
    this.bookingCubit,
    this.deadline,
    this.bookingDate,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _isSuccessTriggered = false;

  @override
  void initState() {
    super.initState();
    if (widget.deadline != null) {
      _updateRemaining();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _updateRemaining();
      });
    }

    // Start polling every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.bookingCubit != null) {
        widget.bookingCubit!.checkPaymentStatus(widget.bookingId);
      } else {
        _checkPaymentStatusInternally();
      }
    });
  }

  Future<void> _checkPaymentStatusInternally() async {
    if (_isSuccessTriggered) return;
    try {
      final repository = PaymentRepositoryImpl(
        remoteDataSource: PaymentRemoteDataSource(
          dioClient: context.read<DioClient>(),
        ),
      );
      final status = await repository.getPaymentStatusByBookingId(widget.bookingId);
      if (status.isPaid && !_isSuccessTriggered) {
        _isSuccessTriggered = true;
        _pollingTimer?.cancel();
        if (mounted) _showSuccessAndClose();
      }
    } catch (_) {
      // Ignore polling errors
    }
  }

  void _updateRemaining() {
    if (widget.deadline == null) return;
    final diff = widget.deadline!.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Scaffold(
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

            // ── Status Polling Indicator & Countdown ───────────────────────
            if (widget.deadline != null) ...[
              _buildCountdownTimer(),
              const SizedBox(height: 24),
            ],
            _buildPollingStatus(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

    if (widget.bookingCubit != null) {
      return BlocListener<BookingCubit, BookingState>(
        bloc: widget.bookingCubit,
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
        child: body,
      );
    }

    return body;
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
    // Resolve the booking date from either BookingCubit or the explicit bookingDate param
    String dateLabel = '';
    if (widget.bookingCubit != null) {
      dateLabel = DateFormat('dd/MM/yyyy').format(widget.bookingCubit!.date);
    } else if (widget.bookingDate != null) {
      try {
        dateLabel = DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.bookingDate!));
      } catch (_) {
        dateLabel = widget.bookingDate!;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryItem('Sân bóng', widget.pitch.name),
          if (dateLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSummaryItem('Ngày đặt', dateLabel),
          ],
          const SizedBox(height: 8),
          _buildSummaryItem('Trạng thái', 'Đang Chờ TT'),
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

  Widget _buildCountdownTimer() {
    final isUrgent = _remaining.inMinutes < 10;
    
    String formatDuration(Duration d) {
      if (d == Duration.zero) return 'Hết hạn thanh toán';
      final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$m : $s';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            'THỜI GIAN THANH TOÁN CÒN LẠI',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isUrgent ? Colors.red.shade800 : Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatDuration(_remaining),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _remaining == Duration.zero ? Colors.red : (isUrgent ? Colors.red : Colors.orange.shade900),
              letterSpacing: 2,
            ),
          ),
          if (_remaining == Duration.zero) ...[
            const SizedBox(height: 8),
            Text(
              'Đơn đặt sân sẽ bị hủy tự động.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ]
        ],
      ),
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
