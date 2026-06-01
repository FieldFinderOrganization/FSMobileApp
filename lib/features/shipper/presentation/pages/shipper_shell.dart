import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/shipper_remote_data_source.dart';
import 'shipper_delivery_screen.dart';

/// Màn chính của shipper: tab Đơn khả dụng + Đơn của tôi.
class ShipperShell extends StatefulWidget {
  final UserEntity user;
  const ShipperShell({super.key, required this.user});

  @override
  State<ShipperShell> createState() => _ShipperShellState();
}

class _ShipperShellState extends State<ShipperShell> {
  late final ShipperRemoteDataSource _ds;
  final _currency = NumberFormat('#,###', 'vi_VN');

  List<OrderModel> _available = [];
  List<OrderModel> _mine = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _ds.getAvailableOrders(),
        _ds.getMyOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _available = results[0];
        _mine = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _claim(OrderModel o) async {
    try {
      await _ds.claimOrder(o.orderId);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã nhận đơn')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nhận đơn thất bại: $e')),
        );
      }
    }
  }

  Future<void> _openDelivery(OrderModel o) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ShipperDeliveryScreen(order: o)),
    );
    if (done == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 1,
          title: Text('Shipper · ${widget.user.name}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primaryRed,
            tabs: [
              Tab(text: 'Khả dụng (${_available.length})'),
              Tab(text: 'Của tôi (${_mine.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Lỗi: $_error'))
                : TabBarView(
                    children: [
                      _buildList(_available, available: true),
                      _buildList(_mine, available: false),
                    ],
                  ),
      ),
    );
  }

  Widget _buildList(List<OrderModel> orders, {required bool available}) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(
                available ? 'Chưa có đơn khả dụng' : 'Bạn chưa nhận đơn nào',
                style: GoogleFonts.inter(color: AppColors.textGrey),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(orders[i], available: available),
      ),
    );
  }

  Widget _buildCard(OrderModel o, {required bool available}) {
    final status = o.status.toUpperCase();
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
          Row(
            children: [
              Text('Đơn #${o.orderId}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${_currency.format(o.totalAmount)}đ',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryRed)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Khách: ${o.userName}',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
          if (o.deliveryAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.textGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(o.deliveryAddress!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (available)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _claim(o),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Nhận đơn',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            )
          else if (status == 'DELIVERED')
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 6),
                Text('Đã giao',
                    style: GoogleFonts.inter(
                        color: Colors.green, fontWeight: FontWeight.w700)),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDelivery(o),
                icon: const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 18),
                label: Text(
                  status == 'SHIPPING' ? 'Tiếp tục giao' : 'Bắt đầu giao',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
