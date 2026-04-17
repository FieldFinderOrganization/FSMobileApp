import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../product/presentation/cubit/product_cubit.dart';
import '../../../pitch/data/datasources/payment_remote_datasource.dart';
import '../../domain/entities/checkout_item_entity.dart';
import '../../../order/presentation/pages/order_history_screen.dart';
import 'shop_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CheckoutItemEntity> items;

  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'cash'; // 'cash' | 'transfer'
  final TextEditingController _promoController = TextEditingController();
  final double _discount = 0.0;
  final TextEditingController _addressController = TextEditingController();

  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void dispose() {
    _promoController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _subtotal => widget.items.fold(0, (sum, i) => sum + i.totalPrice);
  double get _total => _subtotal - _discount;

  void _applyPromo() {
    // Stub — backend chưa có API promo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mã không hợp lệ hoặc đã hết hạn.',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isPlacingOrder = false;

  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập địa chỉ giao hàng.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    final user = authState.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng đăng nhập để đặt hàng.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_paymentMethod == 'transfer') {
      setState(() => _isPlacingOrder = true);
      try {
        final dioClient = context.read<DioClient>();
        final dataSource = PaymentRemoteDataSource(dioClient: dioClient);

        // 1. Create order
        final orderData = await dataSource.createOrder({
          'userId': user.userId,
          'paymentMethod': 'BANK',
          'items': widget.items
              .map(
                (i) => {
                  'productId': i.productId,
                  'size': i.size,
                  'quantity': i.quantity,
                },
              )
              .toList(),
          'discountCodes': <String>[],
        });

        final orderId = orderData['orderId'] as int;

        // 2. Create shop payment (get QR code)
        final paymentResp = await dataSource.createShopPayment({
          'userId': user.userId,
          'amount': _total,
          'paymentMethod': 'BANK',
          'orderCode': orderId,
        });

        if (!mounted) return;

        // Refresh data sau khi tạo order thành công
        context.read<CartCubit>().loadCart();
        context.read<HomeCubit>().refresh();
        context.read<ProductCubit>().loadProducts();

        // 3. Navigate to payment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopPaymentScreen(
              items: widget.items,
              paymentResponse: paymentResp,
              userId: user.userId,
              orderId: orderId.toString(),
              dioClient: dioClient,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        _showOrderError(e);
      } finally {
        if (mounted) setState(() => _isPlacingOrder = false);
      }
    } else {
      setState(() => _isPlacingOrder = true);
      try {
        final dioClient = context.read<DioClient>();
        final dataSource = PaymentRemoteDataSource(dioClient: dioClient);

        await dataSource.createOrder({
          'userId': user.userId,
          'paymentMethod': 'CASH',
          'items': widget.items
              .map(
                (i) => {
                  'productId': i.productId,
                  'size': i.size,
                  'quantity': i.quantity,
                },
              )
              .toList(),
          'discountCodes': <String>[],
        });

        if (!mounted) return;

        // Refresh data sau khi đặt hàng thành công
        context.read<CartCubit>().loadCart();
        context.read<HomeCubit>().refresh();
        context.read<ProductCubit>().loadProducts();

        await _showSuccessDialog();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OrderHistoryScreen(userId: user.userId),
          ),
          (route) => route.isFirst,
        );
      } catch (e) {
        if (!mounted) return;
        _showOrderError(e);
      } finally {
        if (mounted) setState(() => _isPlacingOrder = false);
      }
    }
  }

  /// Extract a user-friendly message from a backend error.
  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        // Spring Boot default error format: { "message": "..." }
        return data['message'] as String? ??
            data['error'] as String? ??
            'Đã xảy ra lỗi không xác định.';
      }
      if (data is String && data.isNotEmpty) return data;
      return error.message ?? 'Lỗi kết nối đến máy chủ.';
    }
    return error.toString();
  }

  /// Show an error dialog when order creation fails (e.g. stock exceeded).
  void _showOrderError(Object error) {
    final message = _extractErrorMessage(error);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.primaryRed,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Đặt hàng thất bại',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Đã hiểu',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Đặt hàng thành công!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Cảm ơn bạn đã tin tưởng lựa chọn sản phẩm của chúng tôi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Xem đơn hàng',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final user = authState.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
          'Xác nhận đơn hàng',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBuyerSection(user),
                  const SizedBox(height: 12),
                  _buildProductsSection(),
                  const SizedBox(height: 12),
                  _buildPromoSection(),
                  const SizedBox(height: 12),
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 12),
                  _buildPriceSummary(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Thông tin người mua ──────────────────────────────────────────────────

  Widget _buildBuyerSection(dynamic user) {
    return _buildCard(
      title: 'Thông tin người mua',
      child: Column(
        children: [
          if (user != null) ...[
            _buildInfoRow(Icons.person_outline_rounded, user.name),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.email_outlined, user.email),
            if (user.phone != null && user.phone!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildInfoRow(Icons.phone_outlined, user.phone!),
            ],
            const Divider(height: 24),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _addressController,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập địa chỉ giao hàng...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Sản phẩm đặt mua ────────────────────────────────────────────────────

  Widget _buildProductsSection() {
    return _buildCard(
      title: 'Sản phẩm đặt mua',
      child: Column(
        children: widget.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (i > 0) const Divider(height: 20),
              _buildProductRow(item),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductRow(CheckoutItemEntity item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrl.isNotEmpty
              ? Image.network(
                  item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade100,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
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
              const SizedBox(height: 4),
              Text(
                '${item.brand} · Size ${item.size}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'x${item.quantity}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_currencyFormat.format(item.unitPrice)}đ',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
              ),
            ),
            if (item.salePercent != null && item.salePercent! > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${_currencyFormat.format(item.originalPrice)}đ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textGrey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Mã khuyến mãi ───────────────────────────────────────────────────────

  Widget _buildPromoSection() {
    return _buildCard(
      title: 'Mã khuyến mãi',
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Nhập mã khuyến mãi',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryRed),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _applyPromo,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Áp dụng',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hình thức thanh toán ─────────────────────────────────────────────────

  Widget _buildPaymentMethodSection() {
    return _buildCard(
      title: 'Hình thức thanh toán',
      child: Column(
        children: [
          _buildPaymentTile(
            value: 'cash',
            icon: Icons.payments_outlined,
            label: 'Tiền mặt khi nhận hàng',
          ),
          const SizedBox(height: 8),
          _buildPaymentTile(
            value: 'transfer',
            icon: Icons.account_balance_outlined,
            label: 'Chuyển khoản ngân hàng',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primaryRed : AppColors.textGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.primaryRed : AppColors.textDark,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? AppColors.primaryRed : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tóm tắt giá ─────────────────────────────────────────────────────────

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Tạm tính', '${_currencyFormat.format(_subtotal)}đ'),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Giảm giá',
            _discount > 0 ? '- ${_currencyFormat.format(_discount)}đ' : '0đ',
            valueColor: _discount > 0 ? Colors.green.shade700 : null,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Phí vận chuyển',
            'Miễn phí',
            valueColor: Colors.green.shade700,
          ),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '${_currencyFormat.format(_total)}đ',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
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
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Đặt hàng · ${_currencyFormat.format(_total)}đ',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Helper: card wrapper ─────────────────────────────────────────────────

  Widget _buildCard({required String title, required Widget child}) {
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
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
