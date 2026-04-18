import 'dart:io';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../../../pitch/data/repositories/booking_repository_impl.dart';

enum RevenueTimeRange { thisWeek, thisMonth, allTime }

class RevenueStats extends Equatable {
  final double totalRevenue;
  final String mostBookedPitch;
  final int mostBookedPitchCount;
  final String topCustomer;
  final int topCustomerCount;
  final String highestRevenuePitch;
  final double highestRevenuePitchAmount;
  final int totalBookings;

  const RevenueStats({
    required this.totalRevenue,
    required this.mostBookedPitch,
    required this.mostBookedPitchCount,
    required this.topCustomer,
    required this.topCustomerCount,
    required this.highestRevenuePitch,
    required this.highestRevenuePitchAmount,
    required this.totalBookings,
  });

  @override
  List<Object?> get props => [
        totalRevenue,
        mostBookedPitch,
        topCustomer,
        highestRevenuePitch,
      ];
}

abstract class ProviderRevenueState extends Equatable {
  const ProviderRevenueState();
  @override
  List<Object?> get props => [];
}

class ProviderRevenueInitial extends ProviderRevenueState {}

class ProviderRevenueLoading extends ProviderRevenueState {}

class ProviderRevenueLoaded extends ProviderRevenueState {
  final List<BookingResponseModel> allBookings;
  final List<BookingResponseModel> filteredBookings;
  final RevenueStats stats;
  final RevenueTimeRange selectedRange;
  final bool isExporting;

  const ProviderRevenueLoaded({
    required this.allBookings,
    required this.filteredBookings,
    required this.stats,
    required this.selectedRange,
    this.isExporting = false,
  });

  ProviderRevenueLoaded copyWith({
    List<BookingResponseModel>? filteredBookings,
    RevenueStats? stats,
    RevenueTimeRange? selectedRange,
    bool? isExporting,
  }) {
    return ProviderRevenueLoaded(
      allBookings: allBookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      stats: stats ?? this.stats,
      selectedRange: selectedRange ?? this.selectedRange,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  @override
  List<Object?> get props => [allBookings, filteredBookings, stats, selectedRange, isExporting];
}

class ProviderRevenueError extends ProviderRevenueState {
  final String message;
  const ProviderRevenueError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProviderRevenueCubit extends Cubit<ProviderRevenueState> {
  final BookingRepository repository;
  final String providerId;

  ProviderRevenueCubit({
    required this.repository,
    required this.providerId,
  }) : super(ProviderRevenueInitial());

  Future<void> loadRevenue() async {
    emit(ProviderRevenueLoading());
    try {
      final bookings = await repository.getBookingsByProvider(providerId);
      final filtered = _filterByRange(bookings, RevenueTimeRange.allTime);
      final stats = _computeStats(filtered);
      emit(ProviderRevenueLoaded(
        allBookings: bookings,
        filteredBookings: filtered,
        stats: stats,
        selectedRange: RevenueTimeRange.allTime,
      ));
    } on DioException catch (e) {
      emit(ProviderRevenueError(e.response?.data?['message'] ?? e.message ?? 'Lỗi tải dữ liệu'));
    } catch (e) {
      emit(ProviderRevenueError(e.toString()));
    }
  }

  void changeTimeRange(RevenueTimeRange range) {
    if (state is! ProviderRevenueLoaded) return;
    final s = state as ProviderRevenueLoaded;
    final filtered = _filterByRange(s.allBookings, range);
    final stats = _computeStats(filtered);
    emit(s.copyWith(filteredBookings: filtered, stats: stats, selectedRange: range));
  }

  Future<void> exportPdf(BuildContext context) async {
    if (state is! ProviderRevenueLoaded) return;
    final s = state as ProviderRevenueLoaded;
    if (s.isExporting) return;

    emit(s.copyWith(isExporting: true));

    try {
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();

      final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
      final dateFmt = DateFormat('dd/MM/yyyy');
      final now = DateTime.now();

      final pdf = pw.Document();
      final rangeLabel = _rangeLabel(s.selectedRange);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (pw.Context ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Báo cáo Doanh thu',
                style: pw.TextStyle(font: boldFont, fontSize: 22),
              ),
            ),
            pw.Text('Xuất ngày: ${dateFmt.format(now)}', style: pw.TextStyle(font: font)),
            pw.Text('Khoảng thời gian: $rangeLabel', style: pw.TextStyle(font: font)),
            pw.Text('Số bản ghi xuất: ${s.filteredBookings.length}', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: 'Tổng quan'),
            pw.Bullet(
              text: 'Tổng doanh thu: ${currencyFmt.format(s.stats.totalRevenue)}',
              style: pw.TextStyle(font: font),
            ),
            pw.Bullet(
              text: 'Tổng số đơn: ${s.stats.totalBookings}',
              style: pw.TextStyle(font: font),
            ),
            pw.Bullet(
              text: 'Sân được đặt nhiều nhất: ${s.stats.mostBookedPitch} (${s.stats.mostBookedPitchCount} lần)',
              style: pw.TextStyle(font: font),
            ),
            pw.Bullet(
              text: 'Khách hàng hàng đầu: ${s.stats.topCustomer} (${s.stats.topCustomerCount} đơn)',
              style: pw.TextStyle(font: font),
            ),
            pw.Bullet(
              text: 'Sân doanh thu cao nhất: ${s.stats.highestRevenuePitch} (${currencyFmt.format(s.stats.highestRevenuePitchAmount)})',
              style: pw.TextStyle(font: font),
            ),
            pw.SizedBox(height: 16),
            if (s.filteredBookings.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Chi tiết đặt sân'),
              pw.Table.fromTextArray(
                headers: ['Sân', 'Khách hàng', 'Ngày', 'Giá', 'Trạng thái'],
                data: s.filteredBookings.map((b) => [
                  b.pitchName,
                  b.userName,
                  b.bookingDate,
                  currencyFmt.format(b.totalPrice),
                  _statusLabel(b.status),
                ]).toList(),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              ),
            ],
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName = 'doanh_thu_${DateFormat('yyyyMMdd').format(now)}.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: fileName,
        );
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (!isClosed) {
        final currentState = state;
        if (currentState is ProviderRevenueLoaded) {
          emit(currentState.copyWith(isExporting: false));
        }
      }
    }
  }

  RevenueStats _computeStats(List<BookingResponseModel> bookings) {
    if (bookings.isEmpty) {
      return const RevenueStats(
        totalRevenue: 0,
        mostBookedPitch: '-',
        mostBookedPitchCount: 0,
        topCustomer: '-',
        topCustomerCount: 0,
        highestRevenuePitch: '-',
        highestRevenuePitchAmount: 0,
        totalBookings: 0,
      );
    }

    final paid = bookings.where((b) =>
        b.status.toUpperCase() == 'CONFIRMED' &&
        b.paymentStatus.toUpperCase() == 'PAID');

    final totalRevenue = paid.fold(0.0, (sum, b) => sum + b.totalPrice);

    final pitchCount = <String, int>{};
    for (final b in bookings) {
      pitchCount[b.pitchName] = (pitchCount[b.pitchName] ?? 0) + 1;
    }
    final topPitchEntry = pitchCount.entries.reduce((a, b) => a.value >= b.value ? a : b);

    final customerCount = <String, int>{};
    for (final b in bookings) {
      customerCount[b.userName] = (customerCount[b.userName] ?? 0) + 1;
    }
    final topCustomerEntry = customerCount.entries.reduce((a, b) => a.value >= b.value ? a : b);

    final pitchRevenue = <String, double>{};
    for (final b in paid) {
      pitchRevenue[b.pitchName] = (pitchRevenue[b.pitchName] ?? 0) + b.totalPrice;
    }
    final topRevenuePitch = pitchRevenue.isNotEmpty
        ? pitchRevenue.entries.reduce((a, b) => a.value >= b.value ? a : b)
        : MapEntry('-', 0.0);

    return RevenueStats(
      totalRevenue: totalRevenue,
      mostBookedPitch: topPitchEntry.key,
      mostBookedPitchCount: topPitchEntry.value,
      topCustomer: topCustomerEntry.key,
      topCustomerCount: topCustomerEntry.value,
      highestRevenuePitch: topRevenuePitch.key,
      highestRevenuePitchAmount: topRevenuePitch.value,
      totalBookings: bookings.length,
    );
  }

  List<BookingResponseModel> _filterByRange(
    List<BookingResponseModel> all,
    RevenueTimeRange range,
  ) {
    if (range == RevenueTimeRange.allTime) return all;
    final now = DateTime.now();
    return all.where((b) {
      final date = DateTime.tryParse(b.bookingDate);
      if (date == null) return false;
      if (range == RevenueTimeRange.thisWeek) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return !date.isBefore(start);
      } else {
        return date.year == now.year && date.month == now.month;
      }
    }).toList();
  }

  String _rangeLabel(RevenueTimeRange range) {
    switch (range) {
      case RevenueTimeRange.thisWeek:
        return 'Tuần này';
      case RevenueTimeRange.thisMonth:
        return 'Tháng này';
      case RevenueTimeRange.allTime:
        return 'Tất cả';
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'CANCELED':
        return 'Đã hủy';
      default:
        return 'Chờ xử lý';
    }
  }
}
