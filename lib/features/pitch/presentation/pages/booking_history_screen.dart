import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/booking_response_model.dart';
import '../cubit/booking_history_cubit.dart';
import '../cubit/booking_history_state.dart';

import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../auth/login/presentation/bloc/auth_state.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../../../core/network/dio_client.dart';

class BookingHistoryScreen extends StatelessWidget {
  final String userId;
  const BookingHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingHistoryCubit(
        repository: BookingRepositoryImpl(
          remoteDataSource: BookingRemoteDataSource(
            dioClient: context.read<DioClient>(),
          ),
        ),
        userId: userId,
      )..loadBookings(),
      child: const _BookingHistoryBody(),
    );
  }
}

class _BookingHistoryBody extends StatelessWidget {
  const _BookingHistoryBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildFilterBar(context),
              Expanded(
                child: BlocBuilder<BookingHistoryCubit, BookingHistoryState>(
                  builder: (context, state) {
                    if (state is BookingHistoryLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryRed),
                      );
                    } else if (state is BookingHistoryError) {
                      return _buildErrorState(context, state.message);
                    } else if (state is BookingHistorySuccess) {
                      if (state.filteredBookings.isEmpty) {
                        return _buildEmptyState();
                      }
                      return RefreshIndicator(
                        onRefresh: () => context.read<BookingHistoryCubit>().loadBookings(),
                        color: AppColors.primaryRed,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.filteredBookings.length,
                          itemBuilder: (context, index) {
                            return _BookingItemCard(booking: state.filteredBookings[index]);
                          },
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Lịch sử đặt sân',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final statusList = ['Tất cả', 'PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'];
    
    return Container(
      height: 60,
      color: Colors.white,
      child: BlocBuilder<BookingHistoryCubit, BookingHistoryState>(
        builder: (context, state) {
          final selectedStatus = state is BookingHistorySuccess ? state.selectedStatus ?? 'Tất cả' : 'Tất cả';
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: statusList.length,
            itemBuilder: (context, index) {
              final status = statusList[index];
              final isSelected = selectedStatus == status;
              
              return GestureDetector(
                onTap: () => context.read<BookingHistoryCubit>().filterByStatus(status == 'Tất cả' ? null : status),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryRed : const Color(0xFFEEEEEE),
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _translateStatus(status),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toUpperCase()) {
      case 'TẤT CẢ': return 'Tất cả';
      case 'PENDING': return 'Chờ xác nhận';
      case 'CONFIRMED': return 'Đã xác nhận';
      case 'CANCELLED': return 'Đã hủy';
      case 'COMPLETED': return 'Hoàn thành';
      default: return status;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy đơn đặt sân nào',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy đặt sân ngay để trải nghiệm nhé!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textGrey.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 50, color: AppColors.primaryRed),
            const SizedBox(height: 16),
            Text(
              'Đã có lỗi xảy ra',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<BookingHistoryCubit>().loadBookings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingItemCard extends StatelessWidget {
  final BookingResponseModel booking;

  const _BookingItemCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final statusBg = statusColor.withValues(alpha: 0.1);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Status & ID
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _translateStatus(booking.status),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  '#${booking.bookingId.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          
          // Main Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pitch Thumbnail Placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_soccer_rounded, color: AppColors.primaryRed),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.pitchName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textGrey),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(booking.bookingDate),
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatSlots(booking.slots),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textGrey,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          
          // Footer: Total & Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng thanh toán',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(booking.totalPrice),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
                if (booking.status == 'PENDING')
                  ElevatedButton(
                    onPressed: () {}, // Redirect to payment or details
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Thanh toán', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  )
                else
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    child: const Text('Chi tiết', style: TextStyle(color: AppColors.textDark, fontSize: 13)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return const Color(0xFF2E7D32);
      case 'CANCELLED': return AppColors.primaryRed;
      case 'COMPLETED': return Colors.blue;
      default: return AppColors.textGrey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatSlots(List<int> slots) {
    if (slots.isEmpty) return 'N/A';
    
    // Simple slot mapping based on index if exact times aren't provided in JSON
    // Mapping: Slot 1 -> 06:00, Slot 18 -> 23:00
    final List<String> timeStrings = slots.map((s) {
      int startHour = 5 + s; // Slot 1 -> 6:00
      return '${startHour.toString().padLeft(2, '0')}:00';
    }).toList();
    
    return timeStrings.join(', ');
  }

  String _translateStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'Chờ xác nhận';
      case 'CONFIRMED': return 'Đã xác nhận';
      case 'CANCELLED': return 'Đã hủy';
      case 'COMPLETED': return 'Hoàn thành';
      default: return status;
    }
  }
}
