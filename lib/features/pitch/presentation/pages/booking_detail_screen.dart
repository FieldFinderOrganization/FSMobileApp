import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../shared/widgets/cancel_reason_sheet.dart';
import '../../../../shared/widgets/no_bank_warning_dialog.dart';
import '../../../../shared/widgets/refund_code_dialog.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../discount/presentation/pages/my_wallet_screen.dart';
import '../../../refund/data/datasources/refund_remote_data_source.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/models/booking_response_model.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingResponseModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingResponseModel _booking;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  bool get _isPaid => _booking.paymentStatus.toUpperCase() == 'PAID';
  bool get _isPending =>
      _booking.status.toUpperCase() == 'PENDING';
  bool get _isCanceled => _booking.status.toUpperCase() == 'CANCELED';

  /// Parse "HH:mm - HH:mm" → DateTime tại bookingDate.
  DateTime? get _earliestSlotStart {
    if (_booking.slotsName.isEmpty) return null;
    DateTime? earliest;
    for (final name in _booking.slotsName) {
      final parts = name.split(' - ');
      if (parts.isEmpty) continue;
      final start = parts[0].trim();
      final hm = start.split(':');
      if (hm.length < 2) continue;
      final h = int.tryParse(hm[0]);
      final m = int.tryParse(hm[1]);
      if (h == null || m == null) continue;
      try {
        final date = DateTime.parse(_booking.bookingDate);
        final dt = DateTime(date.year, date.month, date.day, h, m);
        if (earliest == null || dt.isBefore(earliest)) earliest = dt;
      } catch (_) {}
    }
    return earliest;
  }

  bool get _willRefund {
    if (!_isPaid || _isCanceled) return false;
    final earliest = _earliestSlotStart;
    if (earliest == null) return false;
    return DateTime.now()
        .add(const Duration(minutes: 10))
        .isBefore(earliest);
  }

  bool get _canCancel => (_isPending && !_isCanceled) || _willRefund;

  Future<void> _handleCancel() async {
    final isBankPayment = _booking.paymentMethod.toUpperCase() == 'BANK';

    // Hủy có hoàn tiền BANK nhưng chưa có TK ngân hàng → nhắc: chỉ nhận mã đền bù
    // (BE hoàn tiền mặt nếu có TK, áp dụng mọi mốc hủy).
    if (_willRefund && isBankPayment) {
      final ok = await confirmCancelWithBankCheck(context);
      if (!ok || !mounted) return;
    }

    final reason = await CancelReasonSheet.show(
      context,
      title: (_willRefund && isBankPayment)
          ? 'Lý do hủy & nhận hoàn tiền'
          : 'Lý do hủy đặt sân',
      options: CancelReasonSheet.bookingReasons,
      willIssueRefund: _willRefund && isBankPayment,
      paymentMethod: _booking.paymentMethod,
    );
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final dioClient = context.read<DioClient>();
      final bookingDs = BookingRemoteDataSource(dioClient: dioClient);
      final refundDs = RefundRemoteDataSource(dioClient: dioClient);

      await bookingDs.cancelBooking(_booking.bookingId, reason: reason.encode());

      final refund = await refundDs.getBySource(
        type: 'BOOKING',
        sourceId: _booking.bookingId,
      );

      if (!mounted) return;

      setState(() {
        _booking = BookingResponseModel(
          userId: _booking.userId,
          userName: _booking.userName,
          providerUserId: _booking.providerUserId,
          bookingId: _booking.bookingId,
          bookingDate: _booking.bookingDate,
          status: 'CANCELED',
          paymentStatus: refund != null ? 'REFUNDED' : _booking.paymentStatus,
          totalPrice: _booking.totalPrice,
          providerId: _booking.providerId,
          paymentMethod: _booking.paymentMethod,
          providerName: _booking.providerName,
          pitchName: _booking.pitchName,
          pitchImageUrl: _booking.pitchImageUrl,
          pitchId: _booking.pitchId,
          slots: _booking.slots,
          slotsName: _booking.slotsName,
          createdAt: _booking.createdAt,
          paidAt: _booking.paidAt,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refund?.refundCode != null
                ? 'Đã hủy + cấp mã ${refund!.refundCode}'
                : 'Đã hủy đặt sân',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (refund != null && refund.refundCode != null) {
        final action = await RefundCodeDialog.show(context, refund: refund);
        if (action == 'wallet' && mounted) {
          final userId = context.read<AuthCubit>().state.currentUser?.userId;
          if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyWalletScreen(userId: userId),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hủy thất bại: $e',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildMainInfoCard(),
            const SizedBox(height: 20),
            _buildInvoiceTable(),
            const SizedBox(height: 20),
            _buildTimeTracking(context),
            const SizedBox(height: 20),
            if (_isCanceled) ...[
              _buildCancelInfoCard(),
              const SizedBox(height: 20),
            ],
            if (_canCancel) _buildCancelSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelInfoCard() {
    final who = switch (_booking.cancelledBy?.toUpperCase()) {
      'USER' => 'Bạn (khách hàng)',
      'PROVIDER' => 'Chủ sân',
      'SYSTEM' => 'Hệ thống',
      _ => 'Không xác định',
    };
    final reason = (_booking.cancelReason?.trim().isNotEmpty ?? false)
        ? _booking.cancelReason!.trim()
        : 'Không có lý do';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C6CB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_rounded,
                  size: 18, color: Color(0xFFC0392B)),
              const SizedBox(width: 8),
              Text('Thông tin hủy',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: const Color(0xFFC0392B))),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.person_outline_rounded, 'Người hủy', who),
          if (_booking.cancelledAt != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(Icons.schedule_rounded, 'Thời gian hủy',
                _formatDateTime(_booking.cancelledAt!)),
          ],
          const SizedBox(height: 10),
          _buildInfoRow(Icons.notes_rounded, 'Lý do', reason),
        ],
      ),
    );
  }

  /// Hủy sát giờ = còn <60 phút trước giờ đá (mốc phạt lũy tiến).
  bool get _isLateCancel {
    final start = _earliestSlotStart;
    return start != null &&
        start.difference(DateTime.now()).inMinutes < 60;
  }

  /// Thông báo kết quả hoàn tiền theo thời điểm hủy (rõ ràng, không jargon).
  Widget _buildRefundNotice() {
    final start = _earliestSlotStart;
    final late = _isLateCancel;
    final cutoff = start?.subtract(const Duration(minutes: 60));
    final cutoffStr = cutoff != null
        ? '${cutoff.hour.toString().padLeft(2, '0')}:${cutoff.minute.toString().padLeft(2, '0')}'
        : null;

    final color = late ? const Color(0xFFC0392B) : const Color(0xFF166534);
    final bg = late ? const Color(0xFFFDECEA) : const Color(0xFFE8F5E9);
    final icon = late ? Icons.warning_amber_rounded : Icons.verified_rounded;
    final text = late
        ? 'Hủy sát giờ: chỉ hoàn 70–0% số tiền và mất voucher khuyến mãi đã dùng.'
        : (cutoffStr != null
            ? 'Hủy trước $cutoffStr (60 phút trước giờ đá) để được hoàn 100%.'
            : 'Hủy trước 60 phút so với giờ đá để được hoàn 100%.');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_willRefund && _booking.paymentMethod.toUpperCase() == 'BANK') ...[
            _buildRefundNotice(),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _cancelling ? null : _handleCancel,
              icon: _cancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cancel_rounded, color: Colors.white),
              label: Text(
                (_willRefund &&
                        _booking.paymentMethod.toUpperCase() == 'BANK' &&
                        _isLateCancel)
                    ? 'Vẫn hủy đặt sân'
                    : 'Hủy đặt sân',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_rounded;
    String statusText = 'Chờ TT';

    if (_isCanceled) {
      statusColor = AppColors.primaryRed;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Đã hủy đơn';
    } else if (_isPaid) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Thanh toán thành công';
    } else if (_booking.status == 'CONFIRMED') {
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
            child: Icon(statusIcon, color: statusColor, size: 32),
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
            'Mã đặt sân: #${_booking.bookingId.substring(0, 8).toUpperCase()}',
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
                    _booking.pitchImageUrl != null &&
                        _booking.pitchImageUrl!.isNotEmpty
                    ? Image.network(
                        _booking.pitchImageUrl!,
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
                      _booking.pitchName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Loại sân: ${_booking.slots.length} slots',
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
            _booking.providerName,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Ngày đặt',
            _booking.bookingDate,
          ),
          const SizedBox(height: 12),
          _buildSlotsRow(),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.payment_rounded,
            'Phương thức',
            _booking.paymentMethod,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return _buildInfoRowWidget(
      icon,
      label,
      Text(
        value,
        textAlign: TextAlign.end,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  /// Hàng Slots: gộp slot liên tiếp thành 1 khoảng (16:00 - 19:00). Nếu có nhiều
  /// khoảng rời nhau → hiện khoảng đầu + "…" + badge, nhấn xem popup tất cả.
  Widget _buildSlotsRow() {
    final ranges = _slotRanges();
    if (ranges.isEmpty) {
      final fallback = _booking.slotsName.isNotEmpty
          ? _booking.slotsName.join(', ')
          : _booking.slots.join(', ');
      return _buildInfoRow(Icons.access_time_rounded, 'Slots', fallback);
    }
    if (ranges.length == 1) {
      return _buildInfoRow(Icons.access_time_rounded, 'Slots', ranges.first);
    }
    return _buildInfoRowWidget(
      Icons.access_time_rounded,
      'Slots',
      GestureDetector(
        onTap: () => _showAllSlots(ranges),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                ranges.first,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('+${ranges.length - 1} …',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed)),
            ),
          ],
        ),
      ),
    );
  }

  /// Gộp slot id liên tiếp thành khoảng "HH:00 - HH:00" (slot N → bắt đầu (5+N):00).
  List<String> _slotRanges() {
    final ids = [..._booking.slots]..sort();
    if (ids.isEmpty) return [];
    String label(int s, int e) =>
        '${(5 + s).toString().padLeft(2, '0')}:00 - ${(6 + e).toString().padLeft(2, '0')}:00';
    final ranges = <String>[];
    int start = ids.first, prev = ids.first;
    for (int k = 1; k < ids.length; k++) {
      if (ids[k] == prev + 1) {
        prev = ids[k];
      } else {
        ranges.add(label(start, prev));
        start = ids[k];
        prev = ids[k];
      }
    }
    ranges.add(label(start, prev));
    return ranges;
  }

  void _showAllSlots(List<String> ranges) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Khung giờ đã đặt',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: ranges
              .map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 15, color: AppColors.primaryRed),
                        const SizedBox(width: 8),
                        Text(r,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng',
                style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  /// Hàng thông tin: nhãn trái, giá trị căn phải chiếm hết phần còn lại
  /// (giá trị nằm 1 hàng, chỉ xuống dòng khi quá dài).
  Widget _buildInfoRowWidget(IconData icon, String label, Widget valueWidget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        const SizedBox(width: 12),
        Expanded(child: Align(alignment: Alignment.centerRight, child: valueWidget)),
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
          _invoiceRow(
              'Tiền sân', formatVnd(_booking.totalPrice)),
          _invoiceRow('Phí dịch vụ', formatVnd(0)),
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
                formatVnd(_booking.totalPrice),
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
          if (_booking.createdAt != null)
            _timeRow('Thời gian tạo:', _formatDateTime(_booking.createdAt!)),
          if (_booking.paidAt != null) ...[
            const SizedBox(height: 8),
            _timeRow(
                'Thời gian thanh toán:', _formatDateTime(_booking.paidAt!)),
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
