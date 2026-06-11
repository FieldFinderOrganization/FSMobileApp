import '../../domain/entities/tier_info_entity.dart';

class TierInfoModel extends TierInfoEntity {
  const TierInfoModel({
    required super.tier,
    required super.totalSpent12m,
    super.nextTier,
    super.nextTierThreshold,
    super.amountToNextTier,
    required super.progressPercent,
  });

  factory TierInfoModel.fromJson(Map<String, dynamic> json) {
    return TierInfoModel(
      tier: json['tier'] as String? ?? 'MEMBER',
      totalSpent12m: (json['totalSpent12m'] as num?)?.toDouble() ?? 0.0,
      nextTier: json['nextTier'] as String?,
      nextTierThreshold: (json['nextTierThreshold'] as num?)?.toDouble(),
      amountToNextTier: (json['amountToNextTier'] as num?)?.toDouble(),
      progressPercent: (json['progressPercent'] as num?)?.toInt() ?? 0,
    );
  }
}
