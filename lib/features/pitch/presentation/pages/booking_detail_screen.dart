import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/booking_response_model.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingResponseModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final bool isPaid = booking.paymentStatus == 'PAID';
    final bool isConfirmed = booking.status == 'CONFIRMED';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Chi tiết đặt sân',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(isPaid, isConfirmed),
            const SizedBox(height: 20),

            // Main Info Card (Pitch & Provider)
            _buildMainInfoCard(),
            const SizedBox(height: 20),

            // Invoice Details Table
            _buildInvoiceTable(),
            const SizedBox(height: 20),

            // Time Tracking Section
            _buildTimeTracking(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isPaid, bool isConfirmed) {
    final bool isCanceled = booking.status == 'CANCELED';
    
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_rounded;
    String statusText = 'Chờ thanh toán';

    if (isPaid) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Thanh toán thành công';
    } else if (isCanceled) {
      statusColor = AppColors.primaryRed;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Đã hủy đơn';
    } else if (isConfirmed) {
      statusColor = Colors.green;
      statusIcon = Icons.verified_rounded;
      statusText = 'Đã xác nhận';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã đặt sân: #${booking.bookingId.substring(0, 8).toUpperCase()}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    booking.pitchImageUrl != null &&
                        booking.pitchImageUrl!.isNotEmpty
                    ? Image.network(
                        booking.pitchImageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.pitchName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loại sân: ${booking.slots.length} slots', // Placeholder for actual pitch info
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildInfoRow(
            Icons.person_pin_rounded,
            'Chủ sân',
            booking.providerName,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Ngày đặt',
            booking.bookingDate,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Slots',
            booking.slots.join(', '),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.payment_rounded,
            'Phương thức',
            booking.paymentMethod,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hóa đơn thanh toán',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.textGrey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _invoiceRow('Tiền sân', '${booking.totalPrice.toStringAsFixed(0)}k'),
          _invoiceRow('Phí dịch vụ', '0k'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${booking.totalPrice.toStringAsFixed(0)}k',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTracking(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (booking.createdAt != null)
            _timeRow('Thời gian tạo:', _formatDateTime(booking.createdAt!)),
          if (booking.paidAt != null) ...[
            const SizedBox(height: 8),
            _timeRow('Thời gian thanh toán:', _formatDateTime(booking.paidAt!)),
          ],
        ],
      ),
    );
  }

  Widget _timeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
    } catch (e) {
      return iso;
    }
  }

  Widget _placeholder() => Container(
    width: 60,
    height: 60,
    color: const Color(0xFFF5F5F5),
    child: const Icon(Icons.sports_soccer, color: Colors.grey, size: 24),
  );
}
