import 'dart:math';

import '../../discount/domain/entities/user_discount_entity.dart';
import '../../discount/domain/entities/tier_info_entity.dart';
import 'entities/checkout_item_entity.dart';

/// Kết quả tính giá: specific/category per-item → GLOBAL → REFUND_CREDIT.
typedef CheckoutBreakdown = ({
  double subAfterSpecific,
  double specificDiscount,
  double globalDiscount,
  double finalTotal,
});

/// Logic tính giá + điều kiện voucher cho checkout sản phẩm.
/// Dùng chung giữa CheckoutScreen và card checkout trong AI chat —
/// mọi thay đổi rule giảm giá chỉ sửa ở đây.
class CheckoutPricing {
  final List<CheckoutItemEntity> items;
  final List<UserDiscountEntity> selectedVouchers;

  /// Hạng hiện tại của user — để chặn mã yêu cầu hạng cao hơn (minTier).
  final String userTier;

  const CheckoutPricing({
    required this.items,
    required this.selectedVouchers,
    this.userTier = 'MEMBER',
  });

  /// Subtotal theo GIÁ GỐC — base để tính lại discount ở checkout.
  /// Tránh double-discount: cart đã hiển thị unitPrice giảm rồi,
  /// checkout phải tính từ originalPrice và áp lại theo voucher đã chọn.
  double get subtotal =>
      items.fold(0, (sum, i) => sum + i.originalTotalPrice);

  bool matchesItem(UserDiscountEntity v, CheckoutItemEntity item) {
    if (v.scope == 'SPECIFIC_PRODUCT') {
      return v.applicableProductIds.contains(item.productId);
    }
    if (v.scope == 'CATEGORY') {
      return item.categoryId != null &&
          v.applicableCategoryIds.contains(item.categoryId!);
    }
    return false;
  }

  bool meetsMin(UserDiscountEntity v, double amount) =>
      v.minOrderValue == null ||
      v.minOrderValue! <= 0 ||
      amount >= v.minOrderValue!;

  bool hasEligibleItem(UserDiscountEntity v) {
    if (v.scope == 'GLOBAL') return true;
    return items.any(
      (it) => matchesItem(v, it) && meetsMin(v, it.originalTotalPrice),
    );
  }

  double subAfterSpecificFor(List<UserDiscountEntity> vouchers) {
    double result = 0;
    for (final it in items) {
      final base = it.originalTotalPrice;
      double itemDiscount = 0;
      for (final v in vouchers) {
        if (v.scope != 'GLOBAL' && matchesItem(v, it) && meetsMin(v, base)) {
          itemDiscount = max(itemDiscount, calcSingle(v, base));
        }
      }
      result += (base - itemDiscount).clamp(0, base);
    }
    return result;
  }

  bool isVoucherSelectable(UserDiscountEntity v) {
    if (!v.isAvailable) return false;
    // Mã gắn hạng: user chưa đủ hạng thì không được chọn (BE cũng chặn → tránh 400 khi đặt).
    if (!TierInfoEntity.meetsTier(userTier, v.minTier)) return false;

    // REFUND_CREDIT có thể stack tự do với mọi promo (GLOBAL/CATEGORY/SPECIFIC).
    // Refund là tiền thật của user → trừ trực tiếp lên subtotal sau khi đã áp promo.
    if (v.isRefundCredit) {
      return v.effectiveValue > 0;
    }

    if (v.scope == 'GLOBAL') {
      final selectedSpecific =
          selectedVouchers.where((s) => s.scope != 'GLOBAL').toList();
      return meetsMin(v, subAfterSpecificFor(selectedSpecific));
    }
    return hasEligibleItem(v);
  }

  /// Discount thực áp cho 1 item dựa trên selectedVouchers (best-wins).
  /// Dùng để hiển thị giá per-item: 0 → giá gốc, >0 → giá đã giảm + strikethrough.
  double itemDiscountFor(CheckoutItemEntity item) {
    final base = item.originalTotalPrice;
    double itemDiscount = 0;
    for (final v in selectedVouchers) {
      if (v.scope != 'GLOBAL' && matchesItem(v, item) && meetsMin(v, base)) {
        itemDiscount = max(itemDiscount, calcSingle(v, base));
      }
    }
    return itemDiscount.clamp(0, base);
  }

  /// Tính discount cho 1 mã trên 1 base amount (FIXED hoặc PERCENTAGE).
  static double calcSingle(UserDiscountEntity v, double base) {
    if (base <= 0) return 0;
    double d = v.isPercentage ? base * v.value / 100 : v.value;
    if (v.maxDiscountAmount != null && d > v.maxDiscountAmount!) {
      d = v.maxDiscountAmount!;
    }
    return d.clamp(0, base);
  }

  UserDiscountEntity? selectedByScope(String scope) {
    for (final v in selectedVouchers) {
      if (v.scope == scope) return v;
    }
    return null;
  }

  /// Tính tổng theo logic 2-pha: specific item-level → global trên subtotal sau specific.
  CheckoutBreakdown computeBreakdown() {
    // Phase 1: promo (SPECIFIC + CATEGORY) per-item, best-wins.
    double subAfterSpecific = 0;
    double specificDiscount = 0;
    for (final it in items) {
      final base = it.originalTotalPrice;
      double itemDiscount = 0;
      for (final v in selectedVouchers) {
        if (v.isRefundCredit) continue;
        if (v.scope != 'GLOBAL' && matchesItem(v, it) && meetsMin(v, base)) {
          itemDiscount = max(itemDiscount, calcSingle(v, base));
        }
      }
      specificDiscount += itemDiscount;
      subAfterSpecific += (base - itemDiscount).clamp(0, base);
    }

    // Phase 2: GLOBAL promo trên subAfterSpecific.
    final global = selectedByScope('GLOBAL');
    double globalDiscount = 0;
    if (global != null &&
        !global.isRefundCredit &&
        (global.minOrderValue == null ||
            subAfterSpecific >= global.minOrderValue!)) {
      globalDiscount = calcSingle(global, subAfterSpecific);
    }

    double afterPromo = (subAfterSpecific - globalDiscount)
        .clamp(0, double.infinity)
        .toDouble();

    // Phase 3: REFUND_CREDIT trừ trực tiếp lên afterPromo, hỗ trợ stack nhiều mã.
    double refundApplied = 0;
    for (final v in selectedVouchers.where((v) => v.isRefundCredit)) {
      if (afterPromo <= 0) break;
      final deduct =
          afterPromo < v.effectiveValue ? afterPromo : v.effectiveValue;
      refundApplied += deduct;
      afterPromo -= deduct;
    }

    return (
      subAfterSpecific: subAfterSpecific,
      specificDiscount: specificDiscount,
      globalDiscount: globalDiscount + refundApplied,
      finalTotal: afterPromo.clamp(0, double.infinity).toDouble(),
    );
  }

  double get discountAmount {
    final b = computeBreakdown();
    return b.specificDiscount + b.globalDiscount;
  }

  double get total => computeBreakdown().finalTotal;
}
