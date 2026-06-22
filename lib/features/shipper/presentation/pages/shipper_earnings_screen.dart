import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/shipper_remote_data_source.dart';

enum _Period { today, week, month }

/// Tab "Thu nhập": tổng phí ship GỐC các đơn DELIVERED, theo kỳ.
/// Số tiền tính SERVER-SIDE (GET /orders/shipper/me/earnings) — khách được freeship
/// vẫn tính cho shipper. Danh sách đơn (/orders/shipper/me) chỉ dùng cho tỉ lệ thành công.
class ShipperEarningsScreen extends StatefulWidget {
  final UserEntity user;
  const ShipperEarningsScreen({super.key, required this.user});

  @override
  State<ShipperEarningsScreen> createState() => _ShipperEarningsScreenState();
}

class _ShipperEarningsScreenState extends State<ShipperEarningsScreen> {
  late final ShipperRemoteDataSource _ds;
  final _currency = NumberFormat('#,###', 'vi_VN');

  List<OrderModel> _mine = [];
  Map<String, dynamic> _earnings = const {}; // số tiền theo kỳ từ server
  bool _loading = true;
  String? _error;
  _Period _period = _Period.today;

  @override
  void initState() {
    super.initState();
    _ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_ds.getMyOrders(), _ds.getMyEarnings()]);
      if (!mounted) return;
      setState(() {
        _mine = results[0] as List<OrderModel>;
        _earnings = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = messageFromError(e);
        _loading = false;
      });
    }
  }

  double _num(String k) => (_earnings[k] as num?)?.toDouble() ?? 0;
  int _int(String k) => (_earnings[k] as num?)?.toInt() ?? 0;

  ({double total, int count}) get _periodEarning {
    switch (_period) {
      case _Period.today:
        return (total: _num('today'), count: _int('todayCount'));
      case _Period.week:
        return (total: _num('week'), count: _int('weekCount'));
      case _Period.month:
        return (total: _num('month'), count: _int('monthCount'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivered =
        _mine.where((o) => o.status.toUpperCase() == 'DELIVERED').toList();
    final periodEarning = _periodEarning;
    final totalEarning = periodEarning.total;

    // Tỉ lệ thành công toàn thời gian (giao / (giao + huỷ)).
    final canceledAll =
        _mine.where((o) => o.status.toUpperCase() == 'CANCELED').length;
    final deliveredAll = delivered.length;
    final denom = deliveredAll + canceledAll;
    final successRate = denom == 0 ? null : deliveredAll * 100 / denom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        title: Text('Thu nhập',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Lỗi: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _periodToggle(),
                      const SizedBox(height: 16),
                      _totalCard(totalEarning, periodEarning.count),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _statCard(
                                Icons.check_circle_outline,
                                'Đã giao (tất cả)',
                                '$deliveredAll'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                                Icons.trending_up_rounded,
                                'Tỉ lệ thành công',
                                successRate == null
                                    ? '—'
                                    : '${successRate.toStringAsFixed(0)}%'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _periodToggle() {
    return SegmentedButton<_Period>(
      segments: const [
        ButtonSegment(value: _Period.today, label: Text('Hôm nay')),
        ButtonSegment(value: _Period.week, label: Text('Tuần')),
        ButtonSegment(value: _Period.month, label: Text('Tháng')),
      ],
      selected: {_period},
      onSelectionChanged: (s) => setState(() => _period = s.first),
      showSelectedIcon: false,
    );
  }

  Widget _totalCard(double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng thu nhập',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('${_currency.format(total)}đ',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('$count đơn hoàn thành',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
