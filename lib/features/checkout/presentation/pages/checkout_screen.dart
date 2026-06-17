import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/map_picker_screen.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../product/presentation/cubit/product_cubit.dart';
import '../../../pitch/data/datasources/payment_remote_datasource.dart';
import '../../domain/checkout_pricing.dart';
import '../../domain/entities/checkout_item_entity.dart';
import '../../../order/presentation/pages/order_history_screen.dart';
import '../../../discount/data/datasources/discount_remote_data_source.dart';
import '../../../discount/domain/entities/user_discount_entity.dart';
import '../widgets/voucher_bottom_sheet.dart';
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
  double? _destLat;
  double? _destLng;
  List<UserDiscountEntity> _walletVouchers = [];
  final List<UserDiscountEntity> _selectedVouchers = [];
  bool _walletLoading = false;
  bool _autoApplied = false;
  String _userTier = 'MEMBER'; // hạng user → lọc mã gắn hạng (minTier)

  // Phí ship (preview từ BE). null = chưa có điểm giao / chưa quote xong.
  double? _shippingFee;
  double? _grossFee; // phí gốc theo khoảng cách (trước freeship) — để tính lại freeship local
  double? _distanceKm;
  bool _freeship = false;
  bool _feeLoading = false;
  double _amountToFreeship = 0;
  double _freeshipMaxKm = 0;
  double _freeshipThreshold = 0;

  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    // Auto-load wallet để có thể auto-tick mã pre-applied
    final userId = context.read<AuthCubit>().state.currentUser?.userId;
    if (userId != null) {
      _loadWallet(userId).then((_) => _autoApplyPreCodes());
      _loadTier(userId);
    }
  }

  /// Lấy hạng user để chặn mã gắn hạng (minTier). Lỗi → giữ MEMBER.
  Future<void> _loadTier(String userId) async {
    try {
      final ds = DiscountRemoteDataSource(context.read<DioClient>().dio);
      final info = await ds.getTierInfo(userId);
      if (!mounted) return;
      setState(() {
        _userTier = info.tier;
        // Bỏ chọn mã không còn hợp lệ theo hạng vừa load.
        _selectedVouchers.removeWhere((v) => !_isVoucherSelectable(v));
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  /// Toàn bộ logic tính giá/điều kiện voucher nằm trong CheckoutPricing
  /// (dùng chung với card checkout trong AI chat).
  CheckoutPricing get _pricing => CheckoutPricing(
        items: widget.items,
        selectedVouchers: _selectedVouchers,
        userTier: _userTier,
      );

  double get _subtotal => _pricing.subtotal;

  bool _matchesItem(UserDiscountEntity v, CheckoutItemEntity item) =>
      _pricing.matchesItem(v, item);

  bool _meetsMin(UserDiscountEntity v, double amount) =>
      _pricing.meetsMin(v, amount);

  double _subAfterSpecificFor(List<UserDiscountEntity> vouchers) =>
      _pricing.subAfterSpecificFor(vouchers);

  bool _isVoucherSelectable(UserDiscountEntity v) =>
      _pricing.isVoucherSelectable(v);

  double _itemDiscountFor(CheckoutItemEntity item) =>
      _pricing.itemDiscountFor(item);

  double _calcSingle(UserDiscountEntity v, double base) =>
      CheckoutPricing.calcSingle(v, base);

  double get _discountAmount => _pricing.discountAmount;

  double get _total => _pricing.total;

  /// Tổng phải trả = tiền hàng sau giảm + phí ship (server tính lại khi tạo đơn).
  double get _grandTotal => _total + (_shippingFee ?? 0);

  List<String> get _discountCodes =>
      _selectedVouchers.map((v) => v.discountCode).toList();

  /// Toggle voucher:
  /// - Cùng id → bỏ chọn.
  /// - GLOBAL: replace mã GLOBAL cũ (chỉ 1 mã GLOBAL / đơn).
  /// - CATEGORY / SPECIFIC_PRODUCT: append / remove tự do — nhiều mã OK
  ///   vì chúng áp lên item khác nhau, best-wins xử lý conflict trong CheckoutPricing.
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
    // Đổi voucher chỉ đổi _total → ngưỡng/nudge freeship. Khoảng cách (địa chỉ)
    // không đổi nên KHÔNG gọi lại OSRM; tính lại freeship local từ phí gốc đã có.
    _recomputeFreeshipLocally();
  }

  /// Tính lại phí ship khi _total đổi (đổi voucher) mà KHÔNG gọi mạng.
  /// Dùng phí gốc + khoảng cách đã quote; chỉ xét lại ngưỡng freeship.
  void _recomputeFreeshipLocally() {
    final gross = _grossFee;
    final dist = _distanceKm;
    if (gross == null || dist == null) return; // chưa có quote nào → bỏ qua
    final freeshipEnabled = _freeshipThreshold > 0;
    final inFreeRadius = _freeshipMaxKm <= 0 || dist <= _freeshipMaxKm;
    final freeshipApplied =
        freeshipEnabled && _total >= _freeshipThreshold && inFreeRadius;
    final remaining = _freeshipThreshold - _total;
    setState(() {
      _freeship = freeshipApplied;
      _shippingFee = freeshipApplied ? 0 : gross;
      _amountToFreeship =
          (freeshipEnabled && inFreeRadius && remaining > 0) ? remaining : 0;
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
        globals.sort(
          (a, b) =>
              _calcSingle(b, _subtotal).compareTo(_calcSingle(a, _subtotal)),
        );
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
    VoucherBottomSheet.show(
      context,
      vouchers: _walletVouchers,
      selected: _selectedVouchers,
      items: widget.items,
      onToggle: _toggleVoucher,
      userTier: _userTier,
    );
  }

  bool _isPlacingOrder = false;

  Future<void> _pickLocation() async {
    final result = await Navigator.push<MapPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _destLat,
          initialLng: _destLng,
          title: 'Chọn điểm giao hàng',
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _destLat = result.latLng.latitude;
      _destLng = result.latLng.longitude;
      if (result.address != null && result.address!.isNotEmpty) {
        _addressController.text = result.address!;
      }
    });
    _fetchShippingQuote();
  }

  /// Lấy báo giá phí ship từ BE (preview). Lỗi không chặn checkout —
  /// BE vẫn tính lại phí authoritative khi tạo đơn.
  Future<void> _fetchShippingQuote() async {
    if (_destLat == null || _destLng == null) return;
    setState(() => _feeLoading = true);
    try {
      final dataSource =
          PaymentRemoteDataSource(dioClient: context.read<DioClient>());
      final q = await dataSource.getShippingQuote(
        destLat: _destLat!,
        destLng: _destLng!,
        subtotal: _total, // giá trị đơn sau giảm giá → xét ngưỡng freeship
      );
      if (!mounted) return;
      setState(() {
        _shippingFee = (q['fee'] as num?)?.toDouble() ?? 0;
        _grossFee = (q['grossFee'] as num?)?.toDouble() ?? _shippingFee;
        _distanceKm = (q['distanceKm'] as num?)?.toDouble();
        _freeship = q['freeshipApplied'] as bool? ?? false;
        _amountToFreeship = (q['amountToFreeship'] as num?)?.toDouble() ?? 0;
        _freeshipMaxKm = (q['freeshipMaxKm'] as num?)?.toDouble() ?? 0;
        _freeshipThreshold = (q['freeshipThreshold'] as num?)?.toDouble() ?? 0;
      });
    } catch (_) {
      if (mounted) setState(() => _shippingFee = null);
    } finally {
      if (mounted) setState(() => _feeLoading = false);
    }
  }

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

    if (_destLat == null || _destLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng chọn điểm giao trên bản đồ để shipper định vị.',
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
          'deliveryAddress': _addressController.text.trim(),
          'destLat': _destLat,
          'destLng': _destLng,
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
        // Dùng tổng tiền server trả về (đã gồm phí ship tính authoritative),
        // tránh QR lệch nếu phí preview khác phí thực.
        final serverTotal =
            (orderData['totalAmount'] as num?)?.toDouble() ?? _grandTotal;

        // 2. Create shop payment (get QR code)
        final paymentResp = await dataSource.createShopPayment({
          'userId': user.userId,
          'amount': serverTotal,
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
          'deliveryAddress': _addressController.text.trim(),
          'destLat': _destLat,
          'destLng': _destLng,
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
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (_destLat != null
                        ? Colors.green
                        : AppColors.primaryRed)
                    .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_destLat != null
                          ? Colors.green
                          : AppColors.primaryRed)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _destLat != null ? Icons.check_circle : Icons.map_outlined,
                    size: 18,
                    color: _destLat != null ? Colors.green : AppColors.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _destLat != null
                          ? 'Đã ghim điểm giao trên bản đồ'
                          : 'Chọn điểm giao trên bản đồ (bắt buộc)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _destLat != null
                            ? Colors.green.shade700
                            : AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textGrey),
                ],
              ),
            ),
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
            final percent = hasDiscount ? ((discount / base) * 100).round() : 0;
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
                  painter: DashedLinePainter(color: const Color(0xFFE5E7EB)),
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
                        text:
                            'Bạn có ${eligibleGlobals.length} mã giảm toàn đơn. ',
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
    // Hiển thị phí ship theo trạng thái quote.
    final String shipText;
    Color? shipColor;
    if (_destLat == null) {
      shipText = 'Chọn điểm giao';
      shipColor = AppColors.textGrey;
    } else if (_feeLoading) {
      shipText = 'Đang tính...';
      shipColor = AppColors.textGrey;
    } else if (_shippingFee == null) {
      shipText = 'Tính khi đặt';
      shipColor = AppColors.textGrey;
    } else if (_freeship || _shippingFee == 0) {
      shipText = 'Miễn phí';
      shipColor = Colors.green.shade700;
    } else {
      shipText = '${_currencyFormat.format(_shippingFee)}đ';
      shipColor = null;
    }

    final showNudge = _amountToFreeship > 0;
    final showRadiusNote = !_freeship &&
        _distanceKm != null &&
        _freeshipMaxKm > 0 &&
        _distanceKm! > _freeshipMaxKm &&
        _freeshipThreshold > 0 &&
        _total >= _freeshipThreshold;

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
            shipText,
            valueColor: shipColor,
          ),
          if (showNudge) ...[
            const SizedBox(height: 8),
            _buildFreeshipNudge(),
          ],
          if (showRadiusNote) ...[
            const SizedBox(height: 8),
            _buildRadiusNote(),
          ],
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
                '${_currencyFormat.format(_grandTotal)}đ',
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

  /// Gợi ý "mua thêm Yđ để được miễn phí ship" (đẩy AOV kiểu Shopee).
  Widget _buildFreeshipNudge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mua thêm ${_currencyFormat.format(_amountToFreeship)}đ để được miễn phí vận chuyển',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Note giải thích đơn đủ ngưỡng nhưng giao ngoài bán kính freeship.
  Widget _buildRadiusNote() {
    final km = _distanceKm?.toStringAsFixed(1) ?? '';
    final maxKm = _freeshipMaxKm.toStringAsFixed(0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.textGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Miễn phí ship trong $maxKm km — điểm giao cách ~$km km nên vẫn tính phí.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
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
                    'Đặt hàng · ${_currencyFormat.format(_grandTotal)}đ',
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
