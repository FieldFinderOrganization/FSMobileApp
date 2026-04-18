import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../chat/presentation/pages/user_chat_screen.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../../../pitch/data/repositories/booking_repository_impl.dart';
import '../cubit/provider_booking_cubit.dart';
import '../cubit/provider_cubit.dart';

class ProviderBookingTab extends StatelessWidget {
  final UserEntity user;
  const ProviderBookingTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderCubit, ProviderState>(
      builder: (context, providerState) {
        if (providerState is! ProviderLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        return BlocProvider(
          create: (_) => ProviderBookingCubit(
            repository: context.read<BookingRepository>(),
            providerId: providerState.provider.providerId,
          )..loadBookings(),
          child: _ProviderBookingBody(providerUserId: user.userId),
        );
      },
    );
  }
}

class _ProviderBookingBody extends StatelessWidget {
  final String providerUserId;
  const _ProviderBookingBody({required this.providerUserId});

  static const _statuses = ['Tất cả', 'PENDING', 'CONFIRMED', 'CANCELED'];
  static const _statusLabels = {
    'Tất cả': 'Tất cả',
    'PENDING': 'Chờ thanh toán',
    'CONFIRMED': 'Đã xác nhận',
    'CANCELED': 'Đã hủy',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(context),
        Expanded(child: _buildList(context)),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return BlocBuilder<ProviderBookingCubit, ProviderBookingState>(
      builder: (context, state) {
        final selected = state is ProviderBookingLoaded
            ? (state.selectedStatus ?? 'Tất cả')
            : 'Tất cả';
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _statuses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = _statuses[i];
              final isSelected = s == selected;
              return Center(
                child: FilterChip(
                  label: Text(
                    _statusLabels[s] ?? s,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primaryRed,
                  backgroundColor: const Color(0xFFF5F5F5),
                  checkmarkColor: Colors.white,
                  onSelected: (_) {
                    context.read<ProviderBookingCubit>().filterByStatus(s == 'Tất cả' ? null : s);
                  },
                  showCheckmark: false,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context) {
    return BlocBuilder<ProviderBookingCubit, ProviderBookingState>(
      builder: (context, state) {
        if (state is ProviderBookingLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        if (state is ProviderBookingError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.textGrey, size: 40),
                const SizedBox(height: 8),
                Text(state.message, style: GoogleFonts.inter(color: AppColors.textGrey)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<ProviderBookingCubit>().loadBookings(),
                  child: const Text('Thử lại', style: TextStyle(color: AppColors.primaryRed)),
                ),
              ],
            ),
          );
        }
        if (state is ProviderBookingLoaded) {
          if (state.filteredBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, color: AppColors.textGrey.withValues(alpha: 0.5), size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có đơn đặt sân',
                    style: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryRed,
            onRefresh: () => context.read<ProviderBookingCubit>().loadBookings(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.filteredBookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _BookingCard(
                booking: state.filteredBookings[i],
                providerUserId: providerUserId,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingResponseModel booking;
  final String providerUserId;

  const _BookingCard({required this.booking, required this.providerUserId});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final slots = booking.slots.map(_slotToTime).join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking.pitchImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                booking.pitchImageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 120,
                  color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.sports_soccer, color: AppColors.textGrey, size: 40),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.pitchName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    _StatusBadge(status: booking.status),
                  ],
                ),
                const SizedBox(height: 6),
                _InfoRow(icon: Icons.person_outline, text: booking.userName),
                _InfoRow(icon: Icons.calendar_today_outlined, text: booking.bookingDate),
                if (slots.isNotEmpty) _InfoRow(icon: Icons.access_time_outlined, text: slots),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  text: currencyFmt.format(booking.totalPrice),
                  bold: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.primaryRed),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text('Chat', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserChatScreen(
                            currentUserId: providerUserId,
                            otherUserId: booking.userId,
                            otherUserName: booking.userName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _slotToTime(int slot) {
    final start = 6 + (slot - 1);
    final end = start + 1;
    final startStr = start.toString().padLeft(2, '0');
    final endStr = end.toString().padLeft(2, '0');
    return '$startStr:00–$endStr:00';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        color = Colors.green;
        label = 'Đã xác nhận';
        break;
      case 'CANCELED':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.orange;
        label = 'Chờ thanh toán';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  const _InfoRow({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: bold ? AppColors.textDark : AppColors.textGrey,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
