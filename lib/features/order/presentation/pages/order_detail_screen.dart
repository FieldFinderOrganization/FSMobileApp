import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/cancel_reason_sheet.dart';
import '../../../../shared/widgets/cancel_window_countdown.dart';
import '../../../../shared/widgets/refund_code_dialog.dart';
import '../../../discount/presentation/pages/my_wallet_screen.dart';
import '../../../refund/data/datasources/refund_remote_data_source.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _order;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  bool get _isPending => _order.status.toUpperCase() == 'PENDING';
  bool get _willRefund {
    if (_order.paymentTime == null) return false;
    final s = _order.status.toUpperCase();
    if (s != 'PAID' && s != 'CONFIRMED') return false;
    return DateTime.now()
        .isBefore(_order.paymentTime!.add(const Duration(hours: 24)));
  }

  bool get _canCancel => _isPending || _willRefund;
  DateTime? get _refundDeadline =>
      _order.paymentTime?.add(const Duration(hours: 24));

  Future<void> _handleCancel() async {
    final reason = await CancelReasonSheet.show(
      context,
      title: _willRefund ? 'Lý do hủy & nhận hoàn tiền' : 'Lý do hủy đơn',
      options: CancelReasonSheet.orderReasons,
      willIssueRefund: _willRefund,
    );
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final dioClient = context.read<DioClient>();
      final orderDs = OrderRemoteDataSource(dioClient: dioClient);
      final refundDs = RefundRemoteDataSource(dioClient: dioClient);

      await orderDs.cancelOrder(_order.orderId, reason: reason.encode());

      // Pull refund nếu có
      final refund = await refundDs.getBySource(
        type: 'ORDER',
        sourceId: _order.orderId.toString(),
      );

      if (!mounted) return;
      // Update local order status
      setState(() {
        _order = OrderModel(
          orderId: _order.orderId,
          userName: _order.userName,
          totalAmount: _order.totalAmount,
          status: 'CANCELED',
          paymentMethod: _order.paymentMethod,
          createdAt: _order.createdAt,
          paymentTime: _order.paymentTime,
          items: _order.items,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refund?.refundCode != null
                ? 'Đã hủy + cấp mã ${refund!.refundCode}'
                : 'Đã hủy đơn hàng',
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
          content: Text(
            'Hủy thất bại: ${_extractErrorMessage(e)}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  String _extractErrorMessage(Object error) {
    final msg = error.toString();
    if (msg.length > 200) return '${msg.substring(0, 200)}...';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Chi tiết đơn hàng',
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
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildOrderInfoCard(),
            const SizedBox(height: 20),
            _buildProductListCard(),
            const SizedBox(height: 20),
            _buildBillingCard(),
            const SizedBox(height: 20),
            if (_canCancel) _buildCancelSection(),
            const SizedBox(height: 30),
          ],
        ),
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
          if (_willRefund && _refundDeadline != null) ...[
            Row(
              children: [
                const Icon(Icons.savings_rounded,
                    color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đơn còn trong cửa sổ 24h hoàn tiền',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CancelWindowCountdown(
              deadline: _refundDeadline!,
              tickInterval: const Duration(seconds: 30),
            ),
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
                _willRefund ? 'Hủy đơn & nhận mã hoàn tiền' : 'Hủy đơn hàng',
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
    final status = _order.status.toUpperCase();
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_rounded;
    String statusText = 'Chờ TT';

    if (status == 'PAID') {
      statusColor = Colors.green;
      statusIcon = Icons.payments_rounded;
      statusText = 'Đã thanh toán';
    } else if (status == 'CONFIRMED') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Đã xác nhận';
    } else if (status == 'CANCELED') {
      statusColor = AppColors.primaryRed;
      statusIcon = Icons.cancel_rounded;
      statusText = 'Đã hủy đơn';
    } else if (status == 'DELIVERED') {
      statusColor = const Color(0xFF1565C0);
      statusIcon = Icons.local_shipping_rounded;
      statusText = 'Đã giao';
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
            'Mã đơn hàng: #${_order.orderId}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
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
          _buildInfoRow(
            Icons.person_outline_rounded,
            'Người đặt',
            _order.userName,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Ngày đặt',
            dateFmt.format(_order.createdAt),
          ),
          const SizedBox(height: 12),
          if (_order.paymentTime != null) ...[
            _buildInfoRow(
              Icons.payment_rounded,
              'Ngày thanh toán',
              dateFmt.format(_order.paymentTime!),
            ),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            Icons.account_balance_wallet_outlined,
            'PT Thanh toán',
            _order.paymentMethod == 'BANK' ? 'Chuyển khoản' : 'Tiền mặt',
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

  Widget _buildProductListCard() {
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
          Text(
            'Danh sách sản phẩm',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ..._order.items.map((item) => _buildProductItem(item)),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderItemModel item) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.size}  ×${item.quantity}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currencyFmt.format(item.price),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard() {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _billingRow('Tạm tính', currencyFmt.format(_order.totalAmount)),
          _billingRow('Phí vận chuyển', '0đ'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                currencyFmt.format(_order.totalAmount),
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

  Widget _billingRow(String label, String value) {
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
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.shopping_bag_outlined,
      color: Colors.grey,
      size: 20,
    ),
  );
}
