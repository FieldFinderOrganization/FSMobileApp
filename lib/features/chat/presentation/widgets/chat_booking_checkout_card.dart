import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../discount/data/datasources/discount_remote_data_source.dart';
import '../../../discount/domain/entities/user_discount_entity.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../../pitch/presentation/pages/booking_screen.dart';
import '../../../pitch/presentation/widgets/booking_discount_picker.dart';
import '../cubit/chat_cubit.dart';

/// Card xác nhận đặt sân inline trong AI chat — chỉ render khi AI đã chốt
/// đủ sân + ngày + khung giờ. Trạng thái đặt persist trong aiData.
class ChatBookingCheckoutCard extends StatefulWidget {
  final String messageId;
  final Map<String, dynamic> aiData;

  const ChatBookingCheckoutCard({
    super.key,
    required this.messageId,
    required this.aiData,
  });

  /// Card chỉ dùng được khi đủ thông tin sân + ngày + slot.
  static bool canRender(Map<String, dynamic> aiData) {
    final slotList = aiData['slotList'] as List<dynamic>?;
    return aiData['suggestedPitch'] != null &&
        aiData['bookingDate'] is String &&
        slotList != null &&
        slotList.isNotEmpty;
  }

  @override
  State<ChatBookingCheckoutCard> createState() =>
      _ChatBookingCheckoutCardState();
}

class _ChatBookingCheckoutCardState extends State<ChatBookingCheckoutCard> {
  String _paymentMethod = 'CASH'; // 'CASH' | 'BANK_TRANSFER'
  List<UserDiscountEntity> _selectedVouchers = [];

  PitchEntity get _pitch {
    final raw =
        (widget.aiData['suggestedPitch'] as Map?)?.cast<String, dynamic>() ??
            {};
    return PitchEntity(
      pitchId: (raw['pitchId'] ?? raw['id'] ?? '').toString(),
      name: raw['name'] as String? ?? '',
      type: raw['type'] as String? ?? 'FIVE_A_SIDE',
      environment: raw['environment'] as String? ?? 'OUTDOOR',
      price: (raw['price'] as num?)?.toDouble() ?? 0,
      description: raw['description'] as String? ?? '',
      imageUrls: (raw['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      address: raw['address'] as String? ?? '',
    );
  }

  String get _bookingDate => widget.aiData['bookingDate'] as String? ?? '';

  List<int> get _slotList =>
      (widget.aiData['slotList'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [];

  String? get _status => widget.aiData['checkoutStatus'] as String?;
  bool get _isProcessing => _status == 'processing';
  bool get _isDone => _status == 'done';

  double get _subtotal => _slotList.length * _pitch.price;

  /// Giảm giá tuần tự theo thứ tự mã (giống BookingCubit._computeDiscount).
  double get _discountAmount {
    var remaining = _subtotal;
    var totalCut = 0.0;
    for (final v in _selectedVouchers) {
      double cut;
      if (v.isRefundCredit) {
        final bal = v.remainingValue ?? v.value;
        cut = bal.clamp(0.0, remaining);
      } else if (v.isPercentage) {
        cut = remaining * v.value / 100;
        if (v.maxDiscountAmount != null && cut > v.maxDiscountAmount!) {
          cut = v.maxDiscountAmount!;
        }
      } else {
        cut = v.value.clamp(0.0, remaining);
      }
      totalCut += cut;
      remaining -= cut;
      if (remaining <= 0) break;
    }
    return totalCut;
  }

  double get _total =>
      (_subtotal - _discountAmount).clamp(0.0, double.infinity);

  String get _typeLabel {
    switch (_pitch.type) {
      case 'FIVE_A_SIDE':
        return 'Sân 5';
      case 'SEVEN_A_SIDE':
        return 'Sân 7';
      case 'ELEVEN_A_SIDE':
        return 'Sân 11';
      default:
        return _pitch.type;
    }
  }

  String get _dateLabel {
    try {
      final d = DateTime.parse(_bookingDate);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return _bookingDate;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _openVoucherPicker() async {
    final userId = context.read<AuthCubit>().state.currentUser?.userId;
    if (userId == null) return;
    final ds = DiscountRemoteDataSource(context.read<DioClient>().dio);
    final picked = await BookingDiscountPicker.show(
      context,
      userId: userId,
      dataSource: ds,
      initiallySelected:
          _selectedVouchers.map((v) => v.discountCode).toList(),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedVouchers = picked);
  }

  void _confirm() {
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt sân.')),
      );
      return;
    }

    context.read<ChatCubit>().placeBookingFromChat(
          messageId: widget.messageId,
          userId: user.userId,
          paymentMethod: _paymentMethod,
          pitchId: _pitch.pitchId,
          pitchName: _pitch.name,
          bookingDate: _bookingDate,
          slotList: _slotList,
          pitchPrice: _pitch.price,
          discountCodes:
              _selectedVouchers.map((v) => v.discountCode).toList(),
          total: _total,
        );
  }

  void _openBookingScreen() {
    DateTime? date;
    try {
      date = DateTime.parse(_bookingDate);
    } catch (_) {}
    if (date == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          pitch: _pitch,
          selectedDate: date!,
          initialSlotList: _slotList,
        ),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!ChatBookingCheckoutCard.canRender(widget.aiData)) {
      return const SizedBox.shrink();
    }
    final pitch = _pitch;

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
          _buildHeader(),
          const SizedBox(height: 12),
          Text(
            pitch.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          _infoRow(Icons.location_on_outlined, pitch.address),
          const SizedBox(height: 4),
          _infoRow(Icons.sports_soccer_outlined, _typeLabel),
          const SizedBox(height: 4),
          _infoRow(Icons.calendar_today_outlined, 'Ngày $_dateLabel'),
          const SizedBox(height: 4),
          _infoRow(
            Icons.schedule_outlined,
            '${ChatCubit.slotRangeLabel(_slotList)} (${_slotList.length} giờ)',
          ),
          const Divider(height: 22),
          _buildVoucherRow(),
          const SizedBox(height: 10),
          _buildPriceSummary(),
          if (!_isDone) ...[
            const SizedBox(height: 12),
            _buildPaymentSelector(),
            const SizedBox(height: 12),
            _buildConfirmButton(),
          ],
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _isProcessing ? null : _openBookingScreen,
              child: Text(
                'Mở trang đặt sân',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.sports_soccer, size: 18, color: AppColors.primaryRed),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Xác nhận đặt sân',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (_isDone)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Đã đặt',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherRow() {
    final label = _selectedVouchers.isEmpty
        ? 'Áp mã khuyến mãi'
        : _selectedVouchers.map((v) => v.discountCode).join(', ');
    return InkWell(
      onTap: _isDone || _isProcessing ? null : _openVoucherPicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 16, color: AppColors.primaryRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: _selectedVouchers.isEmpty
                      ? FontWeight.w500
                      : FontWeight.w700,
                  color: _selectedVouchers.isEmpty
                      ? AppColors.textGrey
                      : AppColors.textDark,
                ),
              ),
            ),
            if (!_isDone)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Column(
      children: [
        _summaryRow(
          'Giá sân (${_slotList.length} giờ × ${formatVnd(_pitch.price)})',
          formatVnd(_subtotal),
        ),
        if (_discountAmount > 0) ...[
          const SizedBox(height: 6),
          _summaryRow(
            'Giảm giá',
            '- ${formatVnd(_discountAmount)}',
            valueColor: Colors.green.shade700,
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng cộng',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            Text(
              formatVnd(_total),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelector() {
    return Row(
      children: [
        Expanded(
          child: _paymentTile('CASH', Icons.payments_outlined, 'Tiền mặt'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _paymentTile(
              'BANK_TRANSFER', Icons.account_balance_outlined, 'Chuyển khoản'),
        ),
      ],
    );
  }

  Widget _paymentTile(String value, IconData icon, String label) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryRed.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryRed : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color:
                    selected ? AppColors.primaryRed : AppColors.textGrey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? AppColors.primaryRed : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _confirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          disabledBackgroundColor: Colors.grey.shade300,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Đặt sân · ${formatVnd(_total)}',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
