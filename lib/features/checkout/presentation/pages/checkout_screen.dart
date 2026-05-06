import 'dart:math';

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
import '../../../discount/data/datasources/discount_remote_data_source.dart';
import '../../../discount/domain/entities/user_discount_entity.dart';
import 'shop_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CheckoutItemEntity> items;

  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'cash'; // 'cash' | 'transfer'
  final TextEditingController _addressController = TextEditingController();
  List<UserDiscountEntity> _walletVouchers = [];
  final List<UserDiscountEntity> _selectedVouchers = [];
  bool _walletLoading = false;
  bool _autoApplied = false;

  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    // Auto-load wallet để có thể auto-tick mã pre-applied
    final userId = context.read<AuthCubit>().state.currentUser?.userId;
    if (userId != null) {
      _loadWallet(userId).then((_) => _autoApplyPreCodes());
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  /// Subtotal theo GIÁ GỐC — base để tính lại discount ở checkout.
  /// Tránh double-discount: cart đã hiển thị unitPrice giảm rồi,
  /// checkout phải tính từ originalPrice và áp lại theo voucher đã chọn.
  double get _subtotal =>
      widget.items.fold(0, (sum, i) => sum + i.originalTotalPrice);

  bool _matchesItem(UserDiscountEntity v, CheckoutItemEntity item) {
    if (v.scope == 'SPECIFIC_PRODUCT') {
      return v.applicableProductIds.contains(item.productId);
    }
    if (v.scope == 'CATEGORY') {
      return item.categoryId != null &&
          v.applicableCategoryIds.contains(item.categoryId!);
    }
    return false;
  }

  bool _meetsMin(UserDiscountEntity v, double amount) =>
      v.minOrderValue == null ||
      v.minOrderValue! <= 0 ||
      amount >= v.minOrderValue!;

  bool _hasEligibleItem(UserDiscountEntity v) {
    if (v.scope == 'GLOBAL') return true;
    return widget.items.any(
      (it) => _matchesItem(v, it) && _meetsMin(v, it.originalTotalPrice),
    );
  }

  double _subAfterSpecificFor(List<UserDiscountEntity> vouchers) {
    double result = 0;
    for (final it in widget.items) {
      final base = it.originalTotalPrice;
      double itemDiscount = 0;
      for (final v in vouchers) {
        if (v.scope != 'GLOBAL' &&
            _matchesItem(v, it) &&
            _meetsMin(v, base)) {
          itemDiscount = max(itemDiscount, _calcSingle(v, base));
        }
      }
      result += (base - itemDiscount).clamp(0, base);
    }
    return result;
  }

  bool _isVoucherSelectable(UserDiscountEntity v) {
    if (!v.isAvailable) return false;

    final hasRefundSelected =
        _selectedVouchers.any((s) => s.isRefundCredit);
    final hasPromoSelected =
        _selectedVouchers.any((s) => !s.isRefundCredit);

    // No-stack rule: REFUND_CREDIT không dùng chung promo và ngược lại.
    if (v.isRefundCredit && hasPromoSelected) return false;
    if (!v.isRefundCredit && hasRefundSelected) return false;

    // REFUND_CREDIT chỉ cần còn balance > 0 (validate residual).
    if (v.isRefundCredit) {
      return v.effectiveValue > 0;
    }

    if (v.scope == 'GLOBAL') {
      final selectedSpecific = _selectedVouchers
          .where((s) => s.scope != 'GLOBAL')
          .toList();
      return _meetsMin(v, _subAfterSpecificFor(selectedSpecific));
    }
    return _hasEligibleItem(v);
  }

  /// Discount thực áp cho 1 item dựa trên _selectedVouchers (best-wins).
  /// Dùng để hiển thị giá per-item: 0 → giá gốc, >0 → giá đã giảm + strikethrough.
  double _itemDiscountFor(CheckoutItemEntity item) {
    final base = item.originalTotalPrice;
    double itemDiscount = 0;
    for (final v in _selectedVouchers) {
      if (v.scope != 'GLOBAL' &&
          _matchesItem(v, item) &&
          _meetsMin(v, base)) {
        itemDiscount = max(itemDiscount, _calcSingle(v, base));
      }
    }
    return itemDiscount.clamp(0, base);
  }

  /// Tính discount cho 1 mã trên 1 base amount (FIXED hoặc PERCENTAGE).
  double _calcSingle(UserDiscountEntity v, double base) {
    if (base <= 0) return 0;
    double d = v.isPercentage ? base * v.value / 100 : v.value;
    if (v.maxDiscountAmount != null && d > v.maxDiscountAmount!) {
      d = v.maxDiscountAmount!;
    }
    return d.clamp(0, base);
  }

  UserDiscountEntity? _selectedByScope(String scope) {
    for (final v in _selectedVouchers) {
      if (v.scope == scope) return v;
    }
    return null;
  }

  /// Tính tổng theo logic 2-pha: specific item-level → global trên subtotal sau specific.
  /// Trả về (subAfterSpecific, totalSpecificDiscount, globalDiscount, finalTotal).
  ({
    double subAfterSpecific,
    double specificDiscount,
    double globalDiscount,
    double finalTotal,
  })
  _computeBreakdown() {
    // Nhánh REFUND_CREDIT độc quyền: trừ effectiveValue trực tiếp lên subtotal.
    if (_selectedVouchers.any((v) => v.isRefundCredit)) {
      double remaining = _subtotal;
      double refundApplied = 0;
      for (final v in _selectedVouchers.where((v) => v.isRefundCredit)) {
        if (remaining <= 0) break;
        final deduct = remaining < v.effectiveValue
            ? remaining
            : v.effectiveValue;
        refundApplied += deduct;
        remaining -= deduct;
      }
      return (
        subAfterSpecific: _subtotal,
        specificDiscount: 0,
        globalDiscount: refundApplied,
        finalTotal: remaining.clamp(0, double.infinity).toDouble(),
      );
    }

    double subAfterSpecific = 0;
    double specificDiscount = 0;
    for (final it in widget.items) {
      // Tính trên GIÁ GỐC — voucher toggle drive discount.
      // Bỏ tick → giá quay về originalPrice, tick → trừ.
      final base = it.originalTotalPrice;
      double itemDiscount = 0;
      for (final v in _selectedVouchers) {
        if (v.scope != 'GLOBAL' &&
            _matchesItem(v, it) &&
            _meetsMin(v, base)) {
          itemDiscount = max(itemDiscount, _calcSingle(v, base));
        }
      }
      specificDiscount += itemDiscount;
      subAfterSpecific += (base - itemDiscount).clamp(0, base);
    }

    final global = _selectedByScope('GLOBAL');
    double globalDiscount = 0;
    if (global != null &&
        (global.minOrderValue == null ||
            subAfterSpecific >= global.minOrderValue!)) {
      globalDiscount = _calcSingle(global, subAfterSpecific);
    }

    final finalTotal = (subAfterSpecific - globalDiscount)
        .clamp(0, double.infinity)
        .toDouble();
    return (
      subAfterSpecific: subAfterSpecific,
      specificDiscount: specificDiscount,
      globalDiscount: globalDiscount,
      finalTotal: finalTotal,
    );
  }

  double get _discountAmount {
    final b = _computeBreakdown();
    return b.specificDiscount + b.globalDiscount;
  }

  double get _total => _computeBreakdown().finalTotal;

  List<String> get _discountCodes =>
      _selectedVouchers.map((v) => v.discountCode).toList();

  /// Toggle voucher:
  /// - Cùng id → bỏ chọn.
  /// - GLOBAL: replace mã GLOBAL cũ (chỉ 1 mã GLOBAL / đơn).
  /// - CATEGORY / SPECIFIC_PRODUCT: append / remove tự do — nhiều mã OK
  ///   vì chúng áp lên item khác nhau, best-wins xử lý conflict trong _computeBreakdown.
  void _toggleVoucher(UserDiscountEntity v) {
    if (!_isVoucherSelectable(v)) return;
    setState(() {
      final existIdx = _selectedVouchers.indexWhere(
        (s) => s.userDiscountId == v.userDiscountId,
      );
      if (existIdx >= 0) {
        _selectedVouchers.removeAt(existIdx);
      } else {
        // GLOBAL: chỉ giữ 1
        if (v.scope == 'GLOBAL') {
          _selectedVouchers.removeWhere((s) => s.scope == 'GLOBAL');
        }
        _selectedVouchers.add(v);
      }
    });
  }

  void _autoApplyPreCodes() {
    if (_autoApplied) return;
    if (_walletVouchers.isEmpty) return; // wallet chưa load xong → đợi
    final preCodes = widget.items.expand((i) => i.autoAppliedCodes).toSet();
    if (preCodes.isEmpty) {
      _autoApplied = true;
      return;
    }
    // Chỉ auto-tick mã item-level (SPECIFIC_PRODUCT + CATEGORY).
    // GLOBAL để user tự chọn — sẽ có banner gợi ý nếu eligible.
    final toAdd = _walletVouchers
        .where(
          (v) =>
              preCodes.contains(v.discountCode) &&
              _isVoucherSelectable(v) &&
              v.scope != 'GLOBAL',
        )
        .toList();
    if (toAdd.isEmpty) {
      _autoApplied = true;
      return;
    }
    setState(() {
      // CATEGORY/SPECIFIC_PRODUCT: thêm tất cả eligible (nhiều mã OK, áp lên item khác nhau).
      // GLOBAL: chỉ giữ 1 mã tốt nhất (best-wins trên subtotal).
      _selectedVouchers.clear();

      final itemLevel = toAdd.where((v) => v.scope != 'GLOBAL').toList();
      _selectedVouchers.addAll(itemLevel);

      final globals = toAdd.where((v) => v.scope == 'GLOBAL').toList();
      if (globals.isNotEmpty) {
        globals.sort((a, b) =>
            _calcSingle(b, _subtotal).compareTo(_calcSingle(a, _subtotal)));
        _selectedVouchers.add(globals.first);
      }

      _autoApplied = true;
    });
  }

  Future<void> _loadWallet(String userId) async {
    setState(() => _walletLoading = true);
    try {
      final dioClient = context.read<DioClient>();
      final ds = DiscountRemoteDataSource(dioClient.dio);
      final vouchers = await ds.getWallet(userId);
      if (!mounted) return;
      setState(() {
        _walletVouchers = vouchers.where((v) => v.isAvailable).toList();
        _selectedVouchers.removeWhere((v) => !_isVoucherSelectable(v));
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  Future<void> _openVoucherSheet(String userId) async {
    if (_walletVouchers.isEmpty && !_walletLoading) {
      await _loadWallet(userId);
      _autoApplyPreCodes(); // retry nếu lần load đầu thất bại
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => _VoucherBottomSheet(
          vouchers: _walletVouchers,
          selected: _selectedVouchers,
          items: widget.items,
          onToggle: (v) {
            _toggleVoucher(v);
            setSheetState(() {}); // rebuild sheet để cập nhật ticks
          },
          onConfirm: () => Navigator.pop(sheetCtx),
        ),
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
          'discountCodes': _discountCodes,
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
          'discountCodes': _discountCodes,
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
                  _buildGlobalSuggestionBanner(),
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
        Builder(
          builder: (_) {
            // Hiển thị giá theo voucher đã chọn (không dùng unitPrice cứng từ cart):
            // - Có discount → giá đã giảm (đỏ) + giá gốc (gạch ngang) + tag -%
            // - Không discount → chỉ giá gốc, không gạch ngang
            final base = item.originalTotalPrice;
            final discount = _itemDiscountFor(item);
            final hasDiscount = discount > 0;
            final effective = (base - discount).clamp(0, base);
            final percent =
                hasDiscount ? ((discount / base) * 100).round() : 0;
            final unitDisplay = hasDiscount
                ? effective / item.quantity
                : item.originalPrice;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_currencyFormat.format(unitDisplay)}đ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasDiscount
                        ? AppColors.primaryRed
                        : AppColors.textDark,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_currencyFormat.format(item.originalPrice)}đ',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textGrey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-$percent%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  // ── Mã khuyến mãi ───────────────────────────────────────────────────────

  Widget _buildPromoSection() {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.currentUser?.userId ?? '';

    return _buildCard(
      title: 'Mã khuyến mãi',
      child: _selectedVouchers.isEmpty
          ? GestureDetector(
              onTap: () => _openVoucherSheet(userId),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chọn voucher từ ví của bạn (tối đa 3)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                    if (_walletLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textGrey,
                      ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._selectedVouchers.map((v) => _buildSelectedVoucherChip(v)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openVoucherSheet(userId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryRed.withValues(alpha: 0.4),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: AppColors.primaryRed,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Thêm / đổi voucher',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Coupon-style chip cho voucher đã chọn — accent theo scope, nét đứt phân tách,
  /// có tag saving số tiền giảm thực tế và nút bỏ chọn.
  Widget _buildSelectedVoucherChip(UserDiscountEntity v) {
    final accent = v.scope == 'GLOBAL'
        ? const Color(0xFFB91C1C)
        : v.scope == 'CATEGORY'
            ? const Color(0xFF1565C0)
            : const Color(0xFF6A1B9A);

    // Saving thực tế
    double saving = 0;
    if (v.scope == 'GLOBAL') {
      final subAfter = _subAfterSpecificFor(
        _selectedVouchers.where((s) => s.scope != 'GLOBAL').toList(),
      );
      if (_meetsMin(v, subAfter)) saving = _calcSingle(v, subAfter);
    } else {
      for (final it in widget.items) {
        if (_matchesItem(v, it) && _meetsMin(v, it.originalTotalPrice)) {
          saving = max(saving, _calcSingle(v, it.originalTotalPrice));
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left badge
              Container(
                width: 56,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    v.displayValue,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
              // Dashed
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: _DashedLinePainter(
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              v.discountCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.textDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              v.scopeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (saving > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '−${_currencyFormat.format(saving)}đ',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Remove button
              InkWell(
                onTap: () => _toggleVoucher(v),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Banner gợi ý mã GLOBAL chưa chọn ────────────────────────────────────

  Widget _buildGlobalSuggestionBanner() {
    final authState = context.read<AuthCubit>().state;
    final userId = authState.currentUser?.userId ?? '';

    // subAfterSpecific dùng các mã item-level đã chọn để tính saving thực tế
    final subAfterSpec = _subAfterSpecificFor(
      _selectedVouchers.where((v) => v.scope != 'GLOBAL').toList(),
    );

    final eligibleGlobals = _walletVouchers
        .where(
          (v) =>
              v.scope == 'GLOBAL' &&
              v.isAvailable &&
              _meetsMin(v, subAfterSpec) &&
              !_selectedVouchers.any((s) => s.discountCode == v.discountCode),
        )
        .toList();

    if (eligibleGlobals.isEmpty) return const SizedBox.shrink();

    final bestSaving = eligibleGlobals
        .map((v) => _calcSingle(v, subAfterSpec))
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () => _openVoucherSheet(userId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFC107)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFFF8F00),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF7B5800),
                    ),
                    children: [
                      TextSpan(
                        text: 'Bạn có ${eligibleGlobals.length} mã giảm toàn đơn. ',
                      ),
                      const TextSpan(text: 'Tiết kiệm thêm tới '),
                      TextSpan(
                        text: '${_currencyFormat.format(bestSaving)}đ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Xem mã',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF8F00),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
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
            _discountAmount > 0
                ? '- ${_currencyFormat.format(_discountAmount)}đ'
                : '0đ',
            valueColor: _discountAmount > 0 ? Colors.green.shade700 : null,
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

class _VoucherBottomSheet extends StatelessWidget {
  final List<UserDiscountEntity> vouchers;
  final List<UserDiscountEntity> selected;
  final List<CheckoutItemEntity> items;
  final ValueChanged<UserDiscountEntity> onToggle;
  final VoidCallback onConfirm;

  const _VoucherBottomSheet({
    required this.vouchers,
    required this.selected,
    required this.items,
    required this.onToggle,
    required this.onConfirm,
  });

  bool _matchesItem(UserDiscountEntity v, CheckoutItemEntity item) {
    if (v.scope == 'SPECIFIC_PRODUCT') {
      return v.applicableProductIds.contains(item.productId);
    }
    if (v.scope == 'CATEGORY') {
      return item.categoryId != null &&
          v.applicableCategoryIds.contains(item.categoryId!);
    }
    return false;
  }

  bool _meetsMin(UserDiscountEntity v, double amount) =>
      v.minOrderValue == null ||
      v.minOrderValue! <= 0 ||
      amount >= v.minOrderValue!;

  double _calcSingle(UserDiscountEntity v, double base) {
    if (base <= 0) return 0;
    double d = v.isPercentage ? base * v.value / 100 : v.value;
    if (v.maxDiscountAmount != null && d > v.maxDiscountAmount!) {
      d = v.maxDiscountAmount!;
    }
    return d.clamp(0, base);
  }

  double _subAfterSpecificFor(List<UserDiscountEntity> vouchers) {
    double result = 0;
    for (final it in items) {
      final base = it.originalTotalPrice;
      double itemDiscount = 0;
      for (final v in vouchers) {
        if (v.scope != 'GLOBAL' &&
            _matchesItem(v, it) &&
            _meetsMin(v, base)) {
          itemDiscount = max(itemDiscount, _calcSingle(v, base));
        }
      }
      result += (base - itemDiscount).clamp(0, base);
    }
    return result;
  }

  String? _disabledReason(UserDiscountEntity v, NumberFormat currFmt) {
    if (!v.isAvailable) return 'Voucher không còn khả dụng';
    if (v.scope == 'GLOBAL') {
      final currentSubAfterSpecific = _subAfterSpecificFor(
        selected.where((s) => s.scope != 'GLOBAL').toList(),
      );
      if (_meetsMin(v, currentSubAfterSpecific)) return null;
      final need = v.minOrderValue! - currentSubAfterSpecific;
      return 'Mua thêm ${currFmt.format(need)} để dùng mã này';
    }

    final hasMatchingItem = items.any((it) => _matchesItem(v, it));
    if (!hasMatchingItem) return 'Không áp dụng cho sản phẩm trong đơn';

    final hasEligibleItem = items.any(
      (it) => _matchesItem(v, it) && _meetsMin(v, it.originalTotalPrice),
    );
    if (hasEligibleItem) return null;
    // Tìm sản phẩm match có gap nhỏ nhất để gợi ý
    double minGap = double.infinity;
    for (final it in items) {
      if (_matchesItem(v, it) && v.minOrderValue != null) {
        final gap = v.minOrderValue! - it.originalTotalPrice;
        if (gap > 0 && gap < minGap) minGap = gap;
      }
    }
    if (minGap.isFinite) {
      return 'Mua thêm ${currFmt.format(minGap)} sản phẩm áp dụng để dùng mã';
    }
    return 'Sản phẩm áp dụng tối thiểu ${currFmt.format(v.minOrderValue)}';
  }

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd/MM/yyyy');

    // Group vouchers by scope
    final groups = <String, List<UserDiscountEntity>>{
      'GLOBAL': [],
      'CATEGORY': [],
      'SPECIFIC_PRODUCT': [],
    };
    for (final v in vouchers) {
      groups.putIfAbsent(v.scope, () => []).add(v);
    }

    String headerLabel(String scope) {
      switch (scope) {
        case 'GLOBAL':
          return 'Mã giảm toàn đơn';
        case 'CATEGORY':
          return 'Mã theo danh mục';
        case 'SPECIFIC_PRODUCT':
          return 'Mã theo sản phẩm';
        default:
          return scope;
      }
    }

    // Tính subAfterSpecific để xếp hạng "Tốt nhất" cho GLOBAL
    final subAfterSpec = _subAfterSpecificFor(
      selected.where((s) => s.scope != 'GLOBAL').toList(),
    );

    // Tìm GLOBAL eligible có saving cao nhất → badge "Tốt nhất cho đơn này"
    UserDiscountEntity? bestGlobal;
    double bestSaving = 0;
    for (final v in (groups['GLOBAL'] ?? [])) {
      if (!v.isAvailable || !_meetsMin(v, subAfterSpec)) continue;
      final s = _calcSingle(v, subAfterSpec);
      if (s > bestSaving) {
        bestSaving = s;
        bestGlobal = v;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Chọn voucher',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selected.length}/3',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: vouchers.isEmpty
                ? Center(
                    child: Text(
                      'Bạn chưa có voucher nào có thể dùng',
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  )
                : ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final scope in const [
                        'GLOBAL',
                        'CATEGORY',
                        'SPECIFIC_PRODUCT',
                      ])
                        if ((groups[scope] ?? []).isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                            child: Text(
                              headerLabel(scope),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                          ...groups[scope]!.map(
                            (v) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _voucherTile(
                                v,
                                currFmt,
                                dateFmt,
                                isBestGlobal: bestGlobal != null &&
                                    v.userDiscountId == bestGlobal!.userDiscountId,
                              ),
                            ),
                          ),
                        ],
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Áp dụng (${selected.length})',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _voucherTile(
    UserDiscountEntity v,
    NumberFormat currFmt,
    DateFormat dateFmt, {
    bool isBestGlobal = false,
  }) {
    final isSelected = selected.any(
      (s) => s.userDiscountId == v.userDiscountId,
    );
    final disabledReason = _disabledReason(v, currFmt);
    final eligible = disabledReason == null;

    final accent = v.scope == 'GLOBAL'
        ? const Color(0xFFB91C1C) // GLOBAL red
        : v.scope == 'CATEGORY'
            ? const Color(0xFF1565C0) // CATEGORY blue
            : const Color(0xFF6A1B9A); // SPECIFIC purple

    return Opacity(
      opacity: eligible ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: eligible ? () => onToggle(v) : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent : const Color(0xFFE5E7EB),
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left: value badge with coupon-style notch
                  Container(
                    width: 88,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            v.displayValue,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'GIẢM',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Dashed connector
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CustomPaint(
                      size: const Size(1, double.infinity),
                      painter: _DashedLinePainter(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  // Right: details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  v.discountCode,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isBestGlobal) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8F00),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Tốt nhất',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            v.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                eligible
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.error_outline_rounded,
                                size: 13,
                                color: eligible
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  eligible
                                      ? (v.scope == 'GLOBAL'
                                          ? 'Đủ điều kiện'
                                          : 'Áp dụng được')
                                      : disabledReason,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: eligible
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'HSD ${dateFmt.format(v.endDate)}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right edge: tick indicator
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected ? accent : Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Đường gạch nét đứt dọc — separator giữa value badge và details.
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
