import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../call/presentation/cubit/call_cubit.dart';
import '../../../chat/presentation/pages/user_chat_screen.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/shipper_remote_data_source.dart';
import 'shipper_delivery_screen.dart';

/// Tab "Đơn" của shipper: 3 nhóm — Khả dụng / Đang giao / Lịch sử.
/// [online] = trạng thái sẵn sàng; offline thì ẩn danh sách Khả dụng.
class ShipperOrdersTab extends StatefulWidget {
  final UserEntity user;
  final bool online;
  const ShipperOrdersTab({super.key, required this.user, this.online = true});

  @override
  State<ShipperOrdersTab> createState() => _ShipperOrdersTabState();
}

class _ShipperOrdersTabState extends State<ShipperOrdersTab> {
  late final ShipperRemoteDataSource _ds;
  final _currency = NumberFormat('#,###', 'vi_VN');

  List<OrderModel> _available = [];
  List<OrderModel> _active = []; // của tôi, đang giao
  List<OrderModel> _history = []; // của tôi, đã xong
  bool _loading = true;
  String? _error;

  static const _activeStatuses = {'CONFIRMED', 'SHIPPING'};

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
      final mine = results[1];
      setState(() {
        _available = results[0];
        _active = mine
            .where((o) => _activeStatuses.contains(o.status.toUpperCase()))
            .toList();
        _history = mine
            .where((o) => !_activeStatuses.contains(o.status.toUpperCase()))
            .toList();
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
      length: 3,
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
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primaryRed,
            tabs: [
              Tab(text: 'Khả dụng (${_available.length})'),
              Tab(text: 'Đang giao (${_active.length})'),
              Tab(text: 'Lịch sử (${_history.length})'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Lỗi: $_error'))
                : TabBarView(
                    children: [
                      _buildAvailable(),
                      _buildList(_active, kind: _CardKind.active),
                      _buildList(_history, kind: _CardKind.history),
                    ],
                  ),
      ),
    );
  }

  Widget _buildAvailable() {
    if (!widget.online) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.toggle_off_rounded,
                      size: 48, color: AppColors.textGrey),
                  const SizedBox(height: 8),
                  Text('Bạn đang offline',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text('Bật Online trong Hồ sơ để nhận đơn',
                      style: GoogleFonts.inter(color: AppColors.textGrey)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _buildList(_available, kind: _CardKind.available);
  }

  Widget _buildList(List<OrderModel> orders, {required _CardKind kind}) {
    if (orders.isEmpty) {
      final msg = switch (kind) {
        _CardKind.available => 'Chưa có đơn khả dụng',
        _CardKind.active => 'Bạn chưa nhận đơn nào',
        _CardKind.history => 'Chưa có đơn đã hoàn tất',
      };
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(msg,
                  style: GoogleFonts.inter(color: AppColors.textGrey)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
            12, 12, 12, 12 + MediaQuery.of(context).padding.bottom),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(orders[i], kind),
      ),
    );
  }

  Widget _buildCard(OrderModel o, _CardKind kind) {
    final status = o.status.toUpperCase();
    final isCash = o.paymentMethod.toUpperCase() == 'CASH';
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
              style:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey)),
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
          if (isCash) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 15, color: Color(0xFFE65100)),
                  const SizedBox(width: 4),
                  Text('Thu hộ COD: ${_currency.format(o.totalAmount)}đ',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE65100))),
                ],
              ),
            ),
          ],
          if (kind != _CardKind.available && o.customerId != null) ...[
            const SizedBox(height: 10),
            _contactButtons(o, readOnly: kind == _CardKind.history),
          ],
          const SizedBox(height: 10),
          _buildAction(o, kind, status),
        ],
      ),
    );
  }

  /// Liên hệ khách: chat (luôn) + gọi (chỉ khi đơn đang giao). Sau khi giao xong
  /// → chat read-only, ẩn nút gọi.
  Widget _contactButtons(OrderModel o, {required bool readOnly}) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserChatScreen(
                currentUserId: widget.user.userId,
                otherUserId: o.customerId!,
                otherUserName: o.userName,
                readOnly: readOnly,
                headerSubtitle: 'Đơn #${o.orderId}',
              ),
            ),
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
          label: const Text('Nhắn khách'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textDark),
        ),
        const SizedBox(width: 8),
        if (!readOnly)
          OutlinedButton.icon(
            onPressed: () => context
                .read<CallCubit>()
                .startCall(o.customerId!, o.userName),
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Gọi'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryRed),
          ),
      ],
    );
  }

  Widget _buildAction(OrderModel o, _CardKind kind, String status) {
    if (kind == _CardKind.available) {
      return SizedBox(
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
      );
    }
    if (kind == _CardKind.history) {
      final delivered = status == 'DELIVERED';
      return Row(
        children: [
          Icon(delivered ? Icons.check_circle : Icons.cancel,
              color: delivered ? Colors.green : AppColors.textGrey, size: 18),
          const SizedBox(width: 6),
          Text(delivered ? 'Đã giao' : 'Đã huỷ',
              style: GoogleFonts.inter(
                  color: delivered ? Colors.green : AppColors.textGrey,
                  fontWeight: FontWeight.w700)),
        ],
      );
    }
    // active
    return SizedBox(
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
    );
  }
}

enum _CardKind { available, active, history }
