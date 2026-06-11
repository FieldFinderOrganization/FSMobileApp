import 'package:flutter/material.dart';

/// Thông tin hạng thành viên + tiến độ lên hạng kế (BE: GET /users/{id}/tier).
class TierInfoEntity {
  final String tier; // MEMBER | VIP | GOLD | DIAMOND
  final double totalSpent12m;
  final String? nextTier; // null nếu đã DIAMOND
  final double? nextTierThreshold;
  final double? amountToNextTier;
  final int progressPercent; // 0-100

  const TierInfoEntity({
    required this.tier,
    required this.totalSpent12m,
    this.nextTier,
    this.nextTierThreshold,
    this.amountToNextTier,
    required this.progressPercent,
  });

  bool get isMaxTier => nextTier == null;

  static String labelOf(String tier) {
    switch (tier) {
      case 'VIP':
        return 'VIP';
      case 'GOLD':
        return 'Vàng';
      case 'DIAMOND':
        return 'Kim cương';
      default:
        return 'Thành viên';
    }
  }

  static Color colorOf(String tier) {
    switch (tier) {
      case 'VIP':
        return const Color(0xFF7C3AED); // tím
      case 'GOLD':
        return const Color(0xFFD4A017); // vàng
      case 'DIAMOND':
        return const Color(0xFF0E7490); // cyan đậm
      default:
        return const Color(0xFF6B7280); // xám
    }
  }

  static IconData iconOf(String tier) {
    switch (tier) {
      case 'VIP':
        return Icons.star_rounded;
      case 'GOLD':
        return Icons.workspace_premium_rounded;
      case 'DIAMOND':
        return Icons.diamond_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  /// So sánh "hạng đó trở lên": user [tier] có dùng được voucher yêu cầu [minTier]?
  static bool meetsTier(String userTier, String? minTier) {
    if (minTier == null || minTier.isEmpty) return true;
    const order = ['MEMBER', 'VIP', 'GOLD', 'DIAMOND'];
    final u = order.indexOf(userTier);
    final m = order.indexOf(minTier);
    if (m < 0) return true;
    return u >= m;
  }

  String get label => labelOf(tier);
  Color get color => colorOf(tier);
}
