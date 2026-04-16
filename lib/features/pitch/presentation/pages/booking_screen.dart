import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../auth/login/presentation/bloc/auth_state.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/booking_slot_entity.dart';
import '../../domain/entities/pitch_entity.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'booking_history_screen.dart';
import 'payment_screen.dart';

class BookingScreen extends StatelessWidget {
  final PitchEntity pitch;
  final DateTime selectedDate;

  const BookingScreen({
    super.key,
    required this.pitch,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final dioClient = context.read<DioClient>();
        return BookingCubit(
          repository: BookingRepositoryImpl(
            remoteDataSource: BookingRemoteDataSource(
              dioClient: dioClient,
            ),
          ),
          paymentRepository: PaymentRepositoryImpl(
            remoteDataSource: PaymentRemoteDataSource(
              dioClient: dioClient,
            ),
          ),
          pitch: pitch,
          date: selectedDate,
        );
      },
      child: const _BookingView(),
    );
  }
}

class _BookingView extends StatelessWidget {
  const _BookingView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is BookingConfirmed) {
          _showSuccessDialog(context);
        } else if (state is BookingPaymentRequired) {
          final authState = context.read<AuthCubit>().state;
          final userId = authState.currentUser?.userId ?? '';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (innerContext) => BlocProvider.value(
                value: context.read<BookingCubit>(),
                child: PaymentScreen(
                  pitch: context.read<BookingCubit>().pitch,
                  bookingId: state.bookingId,
                  userId: userId,
                  paymentResponse: state.paymentResponse,
                  bookingCubit: context.read<BookingCubit>(),
                  deadline: context.read<BookingCubit>().paymentDeadline,
                ),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'THÔNG TIN ĐẶT SÂN',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(
                0xFF1B5E20,
              ), // Dark green as requested in image
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          shape: const Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        body: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }
            if (state is BookingError) {
              return _buildErrorView(context, state.message);
            }
            if (state is! BookingSuccess) return const SizedBox();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Pitch Card ─────────────────────────────────────────────────
                  _buildPitchSummary(context, state),
                  const SizedBox(height: 24),

                  // ── Slot Selection ─────────────────────────────────────────────
                  _buildSlotSelection(context, state),
                  const SizedBox(height: 24),

                  // ── Checkout Section ───────────────────────────────────────────
                  _buildCheckoutSection(context, state),
                  const SizedBox(height: 32),

                  // ── Confirm Button ─────────────────────────────────────────────
                  _buildConfirmButton(context, state),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPitchSummary(BuildContext context, BookingSuccess state) {
    final cubit = context.read<BookingCubit>();
    final DateFormat formatter = DateFormat('EEEE, dd/MM/yyyy', 'vi');
    final formattedDate = formatter.format(cubit.date);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Sân bóng:', cubit.pitch.name, isTitle: true),
          const SizedBox(height: 12),
          _buildSummaryRow('Loại sân:', cubit.pitch.displayType),
          const Divider(height: 32, color: Color(0xFFEEEEEE)),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Color(0xFF1B5E20),
              ),
              const SizedBox(width: 12),
              Text(
                'Ngày đặt:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTitle = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: isTitle ? 15 : 14,
              fontWeight: isTitle ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotSelection(BuildContext context, BookingSuccess state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chọn khung giờ',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Đã chọn: ${state.selectedSlotIds.length}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lưu ý: Bạn cần đặt trước ít nhất 30 phút so với giờ bắt đầu.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: state.slots.length,
          itemBuilder: (context, index) {
            final slot = state.slots[index];
            return _buildSlotItem(context, slot);
          },
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem(const Color(0xFFEEEEEE), 'Đã đặt'),
            _buildLegendItem(Colors.orange.shade50, 'Quá hạn', hasBorder: true),
            _buildLegendItem(const Color(0xFF2E7D32), 'Đang chọn'),
            _buildLegendItem(Colors.white, 'Trống', hasBorder: true),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotItem(BuildContext context, BookingSlotEntity slot) {
    Color bgColor;
    Color textColor;
    Border? border;

    switch (slot.status) {
      case SlotStatus.booked:
      case SlotStatus.past:
        bgColor = const Color(0xFFEEEEEE);
        textColor = const Color(0xFFBDBDBD);
        break;
      case SlotStatus.tooLate:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        border = Border.all(color: Colors.orange.shade200);
        break;
      case SlotStatus.selected:
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        border = Border.all(color: const Color(0xFF2E7D32), width: 1.5);
        break;
      case SlotStatus.available:
        // default:
        bgColor = Colors.white;
        textColor = AppColors.textDark;
        border = Border.all(color: const Color(0xFFEEEEEE));
        break;
    }

    return GestureDetector(
      onTap:
          (slot.status == SlotStatus.available ||
              slot.status == SlotStatus.selected)
          ? () {
              HapticFeedback.lightImpact();
              context.read<BookingCubit>().toggleSlotSelection(slot.slotId);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Center(
          child: Text(
            slot.timeRange,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: slot.status == SlotStatus.selected
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: hasBorder
                ? Border.all(color: const Color(0xFFDDDDDD))
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutSection(BuildContext context, BookingSuccess state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THANH TOÁN',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        // Promotion Card
        _buildActionCard(
          icon: Icons.card_giftcard_rounded,
          title: 'Mã ưu đãi',
          subtitle: 'Chưa áp dụng mã nào',
          actionLabel: 'Chọn mã',
          onTap: () => _showComingSoon(context, 'Khuyến mãi'),
        ),
        const SizedBox(height: 20),
        // User Info Card
        _buildUserInfo(context),
        const SizedBox(height: 24),
        // Payment Method
        Text(
          'Hình thức thanh toán',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethod(
                context,
                'Tiền mặt',
                Icons.payments_outlined,
                state.paymentMethod == 'CASH',
                () => context.read<BookingCubit>().setPaymentMethod('CASH'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethod(
                context,
                'Chuyển khoản',
                Icons.account_balance_outlined,
                state.paymentMethod == 'BANK_TRANSFER',
                () => context.read<BookingCubit>().setPaymentMethod('BANK_TRANSFER'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Total Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildPriceRow(
                'Đơn giá:',
                '${context.read<BookingCubit>().pitch.price.toStringAsFixed(0)}k đ/h',
              ),
              const SizedBox(height: 8),
              _buildPriceRow(
                'Số giờ chọn:',
                '${state.selectedSlotIds.length} giờ',
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng thanh toán:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${state.totalAmount.toStringAsFixed(0)}k đ',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState.currentUser;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Người đặt:', user?.name ?? 'Khách hàng'),
              const SizedBox(height: 8),
              _buildSummaryRow('Số điện thoại:', user?.phone ?? 'N/A'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryRed),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryRed : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : icon,
              size: 18,
              color: isSelected ? AppColors.primaryRed : AppColors.textGrey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryRed : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context, BookingSuccess state) {
    return GestureDetector(
      onTap: state.selectedSlotIds.isEmpty
          ? null
          : () {
              final authState = context.read<AuthCubit>().state;
              final user = authState.currentUser;
              if (user != null) {
                context.read<BookingCubit>().confirmBooking(user.userId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng đăng nhập để đặt sân'),
                  ),
                );
              }
            },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: state.selectedSlotIds.isEmpty
                ? [Colors.grey, Colors.grey.shade400]
                : [const Color(0xFFFF3D00), const Color(0xFFDD2C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: state.selectedSlotIds.isEmpty
              ? []
              : [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            'XÁC NHẬN ĐẶT SÂN',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng $feature đang được phát triển'),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.primaryRed,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã có lỗi xảy ra',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message.contains('404')
                  ? 'Không tìm thấy thông tin khung giờ cho sân này. Vui lòng kiểm tra lại.'
                  : 'Không thể tải thông tin khung giờ. Vui lòng kiểm tra kết nối mạng và thử lại.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () => context.read<BookingCubit>().loadSlots(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20), // Dark green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'ĐẶT SÂN THÀNH CÔNG',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đơn đặt sân của bạn đang được xử lý. Bạn có thể xem lại trong lịch sử đặt sân.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                final authState = context.read<AuthCubit>().state;
                final userId = (authState is AuthSuccess)
                    ? authState.authToken.user.userId
                    : (authState is AuthOtpVerified)
                    ? authState.authToken.user.userId
                    : '';
                
                Navigator.pop(context); // close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingHistoryScreen(userId: userId),
                  ),
                );
              },
            child: Text(
              'Xong',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
