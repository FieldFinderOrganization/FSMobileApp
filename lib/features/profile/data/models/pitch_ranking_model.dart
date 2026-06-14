/// Số liệu xếp hạng 1 sân của provider — trả từ
/// GET /api/providers/{providerId}/statistics/pitch-rankings.
class PitchRankingModel {
  final String pitchId;
  final String pitchName;
  final String? imageUrl;
  final int bookingCount;
  final double totalRevenue;
  final double avgRating;
  final int reviewCount;

  const PitchRankingModel({
    required this.pitchId,
    required this.pitchName,
    this.imageUrl,
    required this.bookingCount,
    required this.totalRevenue,
    required this.avgRating,
    required this.reviewCount,
  });

  factory PitchRankingModel.fromJson(Map<String, dynamic> json) {
    return PitchRankingModel(
      pitchId: json['pitchId']?.toString() ?? '',
      pitchName: json['pitchName'] ?? '',
      imageUrl: json['imageUrl'] as String?,
      bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}
