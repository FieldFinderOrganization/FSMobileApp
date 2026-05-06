import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/order_model.dart';
import '../cubit/order_history_cubit.dart';
import '../cubit/order_history_state.dart';
import '../../../checkout/presentation/pages/shop_payment_screen.dart';
import '../../../checkout/domain/entities/checkout_item_entity.dart';
import '../../../pitch/data/datasources/payment_remote_datasource.dart';
import '../../../refund/data/datasources/refund_remote_data_source.dart';
import '../../../../shared/widgets/cancel_reason_sheet.dart';
import '../../../../shared/widgets/refund_code_dialog.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  final String userId;

  const OrderHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderHistoryCubit(
        dataSource: OrderRemoteDataSource(dioClient: context.read<DioClient>()),
        refundDataSource:
            RefundRemoteDataSource(dioClient: context.read<DioClient>()),
        userId: userId,
      )..loadOrders(),
      child: const _OrderHistoryBody(),
    );
  }
}

class _OrderHistoryBody extends StatelessWidget {
  const _OrderHistoryBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: BlocListener<OrderHistoryCubit, OrderHistoryState>(
          listener: (context, state) {
            if (state is OrderHistoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
              );
            } else if (state is OrderHistorySuccess && state.message != null) {
              final cubit = context.read<OrderHistoryCubit>();
              final refund = cubit.lastRefund;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!), backgroundColor: Colors.green),
              );
              cubit.clearMessage();
              if (refund != null && refund.refundCode != null) {
                cubit.clearLastRefund();
                Future.microtask(() async {
                  if (!context.mounted) return;
                  await RefundCodeDialog.show(context, refund: refund);
                });
              }
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                _buildFilterBar(context),
                Expanded(
                  child: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
                    builder: (context, state) {
                      if (state is OrderHistoryLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryRed,
                          ),
                        );
                      } else if (state is OrderHistoryError) {
                        return _buildErrorState(context, state.message);
                      } else if (state is OrderHistorySuccess) {
                        if (state.filteredOrders.isEmpty) {
                          return _buildEmptyState();
                        }
                        return RefreshIndicator(
                          onRefresh: () =>
                              context.read<OrderHistoryCubit>().loadOrders(),
                          color: AppColors.primaryRed,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                            physics: const BouncingScrollPhysics(),
                            itemCount: state.filteredOrders.length,
                            itemBuilder: (context, index) {
                              return _OrderItemCard(
                                order: state.filteredOrders[index],
                              );
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
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      buildWhen: (prev, curr) {
        if (prev is! OrderHistorySuccess || curr is! OrderHistorySuccess) return true;
        return prev.sortAscending != curr.sortAscending || prev.sortMode != curr.sortMode;
      },
      builder: (context, state) {
        final sortAscending = state is OrderHistorySuccess ? state.sortAscending : false;
        final sortMode = state is OrderHistorySuccess ? state.sortMode : OrderSortMode.creationTime;

        return Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Lịch sử đặt hàng',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  // Sort toggle button
                  GestureDetector(
                    onTap: () => context.read<OrderHistoryCubit>().toggleSortOrder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: sortAscending
                              ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                              : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (sortAscending ? Colors.green : AppColors.primaryRed)
                                .withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sortAscending
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 15,
                            color: sortAscending
                                ? const Color(0xFF2E7D32)
                                : AppColors.primaryRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sortAscending ? 'Thấp -> Cao' : 'Cao -> Thấp',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sortAscending
                                  ? const Color(0xFF2E7D32)
                                  : AppColors.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              const SizedBox(height: 8),
              // Sort Mode Switcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _sortModeItem(
                      context,
                      'Thời gian tạo',
                      OrderSortMode.creationTime,
                      sortMode == OrderSortMode.creationTime,
                    ),
                    const SizedBox(width: 12),
                    _sortModeItem(
                      context,
                      'Giá tiền',
                      OrderSortMode.price,
                      sortMode == OrderSortMode.price,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sortModeItem(BuildContext context, String title, OrderSortMode mode, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<OrderHistoryCubit>().setSortMode(mode),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryRed : AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryRed : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    const statusList = ['Tất cả', 'CONFIRMED', 'PENDING', 'CANCELED'];

    return Container(
      height: 60,
      color: Colors.white,
      child: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
        builder: (context, state) {
          final selected = state is OrderHistorySuccess
              ? state.selectedStatus ?? 'Tất cả'
              : 'Tất cả';

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: statusList.length,
            itemBuilder: (context, index) {
              final status = statusList[index];
              final isSelected = selected == status;

              return GestureDetector(
                onTap: () => context.read<OrderHistoryCubit>().filterByStatus(
                  status == 'Tất cả' ? null : status,
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryRed
                          : const Color(0xFFEEEEEE),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryRed.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _translateStatus(status),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
      case 'TẤT CẢ':
        return 'Tất cả';
      case 'PENDING':
        return 'Chờ TT';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'CANCELED':
        return 'Đã hủy';
      default:
        return status;
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
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy mua sắm ngay tại cửa hàng nhé!',
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
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: AppColors.primaryRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Đã có lỗi xảy ra',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<OrderHistoryCubit>().loadOrders(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatefulWidget {
  final OrderModel order;

  const _OrderItemCard({required this.order});

  @override
  State<_OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<_OrderItemCard> {
  static const int _previewLimit = 2;
  bool _expanded = false;
  bool _isLoadingPayment = false;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  bool get _isPendingBank =>
      widget.order.status == 'PENDING' && widget.order.paymentMethod == 'BANK';

  @override
  void initState() {
    super.initState();
    if (_isPendingBank) {
      _updateRemaining();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _updateRemaining();
      });
    }
  }

  void _updateRemaining() {
    final deadline = widget.order.createdAt.add(const Duration(hours: 24));
    final diff = deadline.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d == Duration.zero) return 'Hết hạn';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h giờ $m phút $s giây';
    return '$m phút $s giây';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.order.status);
    final statusBg = statusColor.withValues(alpha: 0.1);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    final items = widget.order.items;
    final visibleItems = _expanded ? items : items.take(_previewLimit).toList();
    final hiddenCount = items.length - _previewLimit;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: widget.order),
        ),
      ),
      child: Container(
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
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _translateStatus(widget.order.status),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    '#${widget.order.orderId}',
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

            // Products
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  ...visibleItems.map((item) => _buildItemRow(item)),
                  if (!_expanded && hiddenCount > 0) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Xem thêm +$hiddenCount sản phẩm',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primaryRed,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_expanded && hiddenCount > 0) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Thu gọn',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: AppColors.textGrey,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFmt.format(widget.order.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                      if (widget.order.paymentTime != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.payment_rounded,
                              size: 12,
                              color: AppColors.textGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFmt.format(widget.order.paymentTime!),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Total + action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tổng cộng',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFmt.format(widget.order.totalAmount),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      if (_isPendingBank) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _remaining.inMinutes < 30
                                ? AppColors.primaryRed.withValues(alpha: 0.08)
                                : Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _remaining.inMinutes < 30
                                  ? AppColors.primaryRed.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 13,
                                color: _remaining.inMinutes < 30
                                    ? AppColors.primaryRed
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatRemaining(_remaining),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _remaining.inMinutes < 30
                                      ? AppColors.primaryRed
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton(
                          onPressed:
                              (_isLoadingPayment || _remaining == Duration.zero)
                              ? null
                              : () => _navigateToPayment(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            disabledBackgroundColor: AppColors.primaryRed
                                .withValues(alpha: 0.5),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _isLoadingPayment
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Thanh toán',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                      if (_canCancel(widget.order)) ...[
                        const SizedBox(height: 6),
                        OutlinedButton(
                          onPressed: () => _showCancelSheet(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryRed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: AppColors.primaryRed),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _willRefund(widget.order) ? 'Hủy & hoàn tiền' : 'Hủy đơn',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canCancel(OrderModel order) {
    final s = order.status.toUpperCase();
    if (s == 'PENDING') return true;
    return _willRefund(order);
  }

  /// Đơn đã PAID/CONFIRMED còn trong vòng 24h kể từ paymentTime → có hoàn tiền.
  bool _willRefund(OrderModel order) {
    if (order.paymentTime == null) return false;
    final s = order.status.toUpperCase();
    if (s != 'PAID' && s != 'CONFIRMED') return false;
    return DateTime.now()
        .isBefore(order.paymentTime!.add(const Duration(hours: 24)));
  }

  Future<void> _showCancelSheet(BuildContext outerContext) async {
    final result = await CancelReasonSheet.show(
      outerContext,
      title: _willRefund(widget.order)
          ? 'Lý do hủy & nhận hoàn tiền'
          : 'Lý do hủy đơn',
      options: CancelReasonSheet.orderReasons,
      willIssueRefund: _willRefund(widget.order),
    );
    if (result == null) return;
    if (!outerContext.mounted) return;
    outerContext.read<OrderHistoryCubit>().cancelOrder(
          widget.order.orderId,
          reason: result.encode(),
        );
  }

  Future<void> _navigateToPayment(BuildContext context) async {
    setState(() => _isLoadingPayment = true);
    try {
      final dioClient = context.read<DioClient>();
      final paymentDataSource = PaymentRemoteDataSource(dioClient: dioClient);

      // Fetch payment info (QR code, bank details) for this order
      final paymentRes = await paymentDataSource.getShopPaymentStatus(
        widget.order.orderId.toString(),
      );

      if (!mounted) return;

      // Convert OrderItemModels → CheckoutItemEntities for ShopPaymentScreen
      final checkoutItems = widget.order.items.map((item) {
        return CheckoutItemEntity(
          productId: item.productId,
          productName: item.productName,
          brand: '',
          imageUrl: item.imageUrl ?? '',
          size: item.size,
          unitPrice: item.price,
          originalPrice: item.price,
          quantity: item.quantity,
        );
      }).toList();

      // Get userId from the cubit
      final userId = context.read<OrderHistoryCubit>().userId;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShopPaymentScreen(
            items: checkoutItems,
            paymentResponse: paymentRes,
            userId: userId,
            orderId: widget.order.orderId.toString(),
            dioClient: dioClient,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thông tin thanh toán: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPayment = false);
    }
  }

  Widget _buildItemRow(OrderItemModel item) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    width: 60,
                    height: 60,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
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
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.shopping_bag_outlined,
      color: Colors.grey,
      size: 24,
    ),
  );

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return const Color(0xFF2E7D32);
      case 'CANCELED':
        return AppColors.primaryRed;
      default:
        return AppColors.textGrey;
    }
  }

  String _translateStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ TT';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'CANCELED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
