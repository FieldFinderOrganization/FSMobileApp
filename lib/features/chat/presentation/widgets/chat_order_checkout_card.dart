import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/map_picker_screen.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../checkout/domain/checkout_pricing.dart';
import '../../../checkout/domain/entities/checkout_item_entity.dart';
import '../../../checkout/presentation/pages/checkout_screen.dart';
import '../../../checkout/presentation/widgets/voucher_bottom_sheet.dart';
import '../../../discount/data/datasources/discount_remote_data_source.dart';
import '../../../discount/domain/entities/user_discount_entity.dart';
import '../cubit/chat_cubit.dart';

/// Card xác nhận đặt sản phẩm inline trong AI chat — thay cho việc
/// điều hướng sang CheckoutScreen. Trạng thái đặt (checkoutStatus)
/// persist trong aiData của message nên sống qua restart.
class ChatOrderCheckoutCard extends StatefulWidget {
  final String messageId;
  final Map<String, dynamic> aiData;

  const ChatOrderCheckoutCard({
    super.key,
    required this.messageId,
    required this.aiData,
  });

  @override
  State<ChatOrderCheckoutCard> createState() => _ChatOrderCheckoutCardState();
}

class _ChatOrderCheckoutCardState extends State<ChatOrderCheckoutCard> {
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  String _paymentMethod = 'cash'; // 'cash' | 'transfer'
  String _address = '';
  double? _destLat;
  double? _destLng;

  List<UserDiscountEntity> _walletVouchers = [];
  final List<UserDiscountEntity> _selectedVouchers = [];
  bool _walletLoading = false;

  @override
  void initState() {
    super.initState();
    // Prefill địa chỉ + toạ độ từ profile user (nếu có).
    final user = context.read<AuthCubit>().state.currentUser;
    _address = user?.address ?? '';
    _destLat = user?.latitude;
    _destLng = user?.longitude;
  }

  Map<String, dynamic> get _product =>
      (widget.aiData['product'] as Map?)?.cast<String, dynamic>() ?? {};

  CheckoutItemEntity get _item {
    final p = _product;
    final price = (p['price'] as num?)?.toDouble() ?? 0;
    return CheckoutItemEntity(
      productId: (p['id'] as num?)?.toInt() ?? 0,
      productName: p['name'] as String? ?? '',
      brand: p['brand'] as String? ?? '',
      imageUrl: p['imageUrl'] as String? ?? '',
      size: widget.aiData['selectedSize'] as String? ?? '',
      unitPrice: (p['salePrice'] as num?)?.toDouble() ?? price,
      originalPrice: price,
      salePercent: (p['salePercent'] as num?)?.toInt(),
      quantity: (widget.aiData['selectedQuantity'] as num?)?.toInt() ?? 1,
      categoryId: (p['categoryId'] as num?)?.toInt(),
    );
  }

  CheckoutPricing get _pricing =>
      CheckoutPricing(items: [_item], selectedVouchers: _selectedVouchers);

  String? get _status => widget.aiData['checkoutStatus'] as String?;
  bool get _isProcessing => _status == 'processing';
  bool get _isDone => _status == 'done';
  bool get _hasLocation => _destLat != null && _destLng != null;

  // ── Actions ───────────────────────────────────────────────────────────

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
        _address = result.address!;
      }
    });
  }

  void _toggleVoucher(UserDiscountEntity v) {
    if (!_pricing.isVoucherSelectable(v)) return;
    setState(() {
      final idx = _selectedVouchers.indexWhere(
        (s) => s.userDiscountId == v.userDiscountId,
      );
      if (idx >= 0) {
        _selectedVouchers.removeAt(idx);
      } else {
        if (v.scope == 'GLOBAL') {
          _selectedVouchers.removeWhere((s) => s.scope == 'GLOBAL');
        }
        _selectedVouchers.add(v);
      }
    });
  }

  Future<void> _openVoucherSheet() async {
    final userId = context.read<AuthCubit>().state.currentUser?.userId;
    if (userId == null) return;

    if (_walletVouchers.isEmpty && !_walletLoading) {
      setState(() => _walletLoading = true);
      try {
        final ds = DiscountRemoteDataSource(context.read<DioClient>().dio);
        final vouchers = await ds.getWallet(userId);
        if (!mounted) return;
        setState(() {
          _walletVouchers = vouchers.where((v) => v.isAvailable).toList();
        });
      } catch (_) {
      } finally {
        if (mounted) setState(() => _walletLoading = false);
      }
    }
    if (!mounted) return;

    VoucherBottomSheet.show(
      context,
      vouchers: _walletVouchers,
      selected: _selectedVouchers,
      items: [_item],
      onToggle: _toggleVoucher,
    );
  }

  void _confirm() {
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng.')),
      );
      return;
    }
    if (_address.trim().isEmpty || !_hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng ghim điểm giao trên bản đồ trước khi đặt.'),
        ),
      );
      return;
    }

    final item = _item;
    context.read<ChatCubit>().placeProductOrderFromChat(
          messageId: widget.messageId,
          userId: user.userId,
          paymentMethod: _paymentMethod == 'transfer' ? 'BANK' : 'CASH',
          deliveryAddress: _address.trim(),
          destLat: _destLat!,
          destLng: _destLng!,
          productId: item.productId,
          size: item.size,
          quantity: item.quantity,
          discountCodes:
              _selectedVouchers.map((v) => v.discountCode).toList(),
          total: _pricing.total,
        );
  }

  void _openFullCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(items: [_item])),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (item.productId == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 60, top: 6, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Xác nhận đơn hàng', Icons.shopping_bag_outlined),
          const SizedBox(height: 12),
          _buildProductRow(item),
          const Divider(height: 24),
          _buildAddressRow(),
          const SizedBox(height: 10),
          _buildVoucherRow(),
          const Divider(height: 24),
          _buildPriceSummary(),
          if (!_isDone) ...[
            const SizedBox(height: 12),
            _buildPaymentSelector(),
            const SizedBox(height: 12),
            _buildConfirmButton(),
          ],
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _isProcessing ? null : _openFullCheckout,
              child: Text(
                'Mở trang chi tiết',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryRed),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (_isDone)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 13, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Đã đặt',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductRow(CheckoutItemEntity item) {
    final discount = _pricing.itemDiscountFor(item);
    final base = item.originalTotalPrice;
    final hasDiscount = discount > 0;
    final unitDisplay =
        hasDiscount ? (base - discount) / item.quantity : item.originalPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrl.isNotEmpty
              ? Image.network(
                  item.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.grey, size: 20),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_outlined,
                      color: Colors.grey, size: 20),
                ),
        ),
        const SizedBox(width: 10),
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
              const SizedBox(height: 2),
              Text(
                '${item.brand} · Size ${item.size} · x${item.quantity}',
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_currencyFormat.format(unitDisplay)}đ',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasDiscount ? AppColors.primaryRed : AppColors.textDark,
              ),
            ),
            if (hasDiscount)
              Text(
                '${_currencyFormat.format(item.originalPrice)}đ',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.textGrey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressRow() {
    final pinned = _hasLocation;
    return InkWell(
      onTap: _isDone || _isProcessing ? null : _pickLocation,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (pinned ? Colors.green : AppColors.primaryRed)
              .withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (pinned ? Colors.green : AppColors.primaryRed)
                .withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              pinned ? Icons.location_on : Icons.location_off_outlined,
              size: 16,
              color: pinned ? Colors.green : AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _address.isNotEmpty
                    ? _address
                    : 'Chọn điểm giao trên bản đồ (bắt buộc)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: pinned
                      ? AppColors.textDark
                      : AppColors.primaryRed,
                ),
              ),
            ),
            if (!_isDone)
              const Icon(Icons.edit_location_alt_outlined,
                  size: 16, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherRow() {
    final label = _selectedVouchers.isEmpty
        ? 'Áp mã khuyến mãi'
        : _selectedVouchers.map((v) => v.discountCode).join(', ');
    return InkWell(
      onTap: _isDone || _isProcessing ? null : _openVoucherSheet,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 16, color: AppColors.primaryRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: _selectedVouchers.isEmpty
                      ? FontWeight.w500
                      : FontWeight.w700,
                  color: _selectedVouchers.isEmpty
                      ? AppColors.textGrey
                      : AppColors.textDark,
                ),
              ),
            ),
            if (_walletLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (!_isDone)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    final subtotal = _pricing.subtotal;
    final discount = _pricing.discountAmount;
    final total = _pricing.total;

    return Column(
      children: [
        _summaryRow('Tạm tính', '${_currencyFormat.format(subtotal)}đ'),
        if (discount > 0) ...[
          const SizedBox(height: 6),
          _summaryRow(
            'Giảm giá',
            '- ${_currencyFormat.format(discount)}đ',
            valueColor: Colors.green.shade700,
          ),
        ],
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tổng cộng',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${_currencyFormat.format(total)}đ',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelector() {
    return Row(
      children: [
        Expanded(
          child: _paymentTile(
              'cash', Icons.payments_outlined, 'Tiền mặt'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _paymentTile(
              'transfer', Icons.account_balance_outlined, 'Chuyển khoản'),
        ),
      ],
    );
  }

  Widget _paymentTile(String value, IconData icon, String label) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color:
                    selected ? AppColors.primaryRed : AppColors.textGrey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? AppColors.primaryRed : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm = !_isProcessing && _hasLocation;
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: canConfirm ? _confirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          disabledBackgroundColor: Colors.grey.shade300,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Đặt hàng · ${_currencyFormat.format(_pricing.total)}đ',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
