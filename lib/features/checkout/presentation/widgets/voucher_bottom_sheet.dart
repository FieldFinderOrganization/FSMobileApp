import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../discount/domain/entities/user_discount_entity.dart';
import '../../domain/checkout_pricing.dart';
import '../../domain/entities/checkout_item_entity.dart';

/// Bottom sheet chọn voucher cho checkout sản phẩm — dùng chung giữa
/// CheckoutScreen và card checkout trong AI chat.
class VoucherBottomSheet extends StatelessWidget {
  final List<UserDiscountEntity> vouchers;
  final List<UserDiscountEntity> selected;
  final List<CheckoutItemEntity> items;
  final ValueChanged<UserDiscountEntity> onToggle;
  final VoidCallback onConfirm;

  const VoucherBottomSheet({
    super.key,
    required this.vouchers,
    required this.selected,
    required this.items,
    required this.onToggle,
    required this.onConfirm,
  });

  /// Mở sheet với wrapper StatefulBuilder chuẩn (rebuild ticks khi toggle).
  static Future<void> show(
    BuildContext context, {
    required List<UserDiscountEntity> vouchers,
    required List<UserDiscountEntity> selected,
    required List<CheckoutItemEntity> items,
    required ValueChanged<UserDiscountEntity> onToggle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => VoucherBottomSheet(
          vouchers: vouchers,
          selected: selected,
          items: items,
          onToggle: (v) {
            onToggle(v);
            setSheetState(() {});
          },
          onConfirm: () => Navigator.pop(sheetCtx),
        ),
      ),
    );
  }

  CheckoutPricing get _pricing =>
      CheckoutPricing(items: items, selectedVouchers: selected);

  String? _disabledReason(UserDiscountEntity v, NumberFormat currFmt) {
    final pricing = _pricing;
    if (!v.isAvailable) return 'Voucher không còn khả dụng';
    if (v.scope == 'GLOBAL') {
      final currentSubAfterSpecific = pricing.subAfterSpecificFor(
        selected.where((s) => s.scope != 'GLOBAL').toList(),
      );
      if (pricing.meetsMin(v, currentSubAfterSpecific)) return null;
      final need = v.minOrderValue! - currentSubAfterSpecific;
      return 'Mua thêm ${currFmt.format(need)} để dùng mã này';
    }

    final hasMatchingItem = items.any((it) => pricing.matchesItem(v, it));
    if (!hasMatchingItem) return 'Không áp dụng cho sản phẩm trong đơn';

    final hasEligibleItem = items.any(
      (it) =>
          pricing.matchesItem(v, it) &&
          pricing.meetsMin(v, it.originalTotalPrice),
    );
    if (hasEligibleItem) return null;
    // Tìm sản phẩm match có gap nhỏ nhất để gợi ý
    double minGap = double.infinity;
    for (final it in items) {
      if (pricing.matchesItem(v, it) && v.minOrderValue != null) {
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
    final pricing = _pricing;
    final subAfterSpec = pricing.subAfterSpecificFor(
      selected.where((s) => s.scope != 'GLOBAL').toList(),
    );

    // Tìm GLOBAL eligible có saving cao nhất → badge "Tốt nhất cho đơn này"
    UserDiscountEntity? bestGlobal;
    double bestSaving = 0;
    for (final v in (groups['GLOBAL'] ?? [])) {
      if (!v.isAvailable || !pricing.meetsMin(v, subAfterSpec)) continue;
      final s = CheckoutPricing.calcSingle(v, subAfterSpec);
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
                                isBestGlobal:
                                    bestGlobal != null &&
                                    v.userDiscountId ==
                                        bestGlobal.userDiscountId,
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
                      painter: DashedLinePainter(
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
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
