class AdminRatingStatsModel {
  final List<RatingDistItem> distribution;
  final int totalReviews;
  final double averageRating;
  final List<RecentReview> recentReviews;

  const AdminRatingStatsModel({
    required this.distribution,
    required this.totalReviews,
    required this.averageRating,
    required this.recentReviews,
  });

  factory AdminRatingStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminRatingStatsModel(
      distribution: (json['distribution'] as List<dynamic>? ?? [])
          .map((e) => RatingDistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalReviews: (json['totalReviews'] as num? ?? 0).toInt(),
      averageRating: (json['averageRating'] as num? ?? 0).toDouble(),
      recentReviews: (json['recentReviews'] as List<dynamic>? ?? [])
          .map((e) => RecentReview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RatingDistItem {
  final int stars;
  final int count;
  final double percentage;

  const RatingDistItem({
    required this.stars,
    required this.count,
    required this.percentage,
  });

  factory RatingDistItem.fromJson(Map<String, dynamic> json) {
    return RatingDistItem(
      stars: (json['stars'] as num? ?? 0).toInt(),
      count: (json['count'] as num? ?? 0).toInt(),
      percentage: (json['percentage'] as num? ?? 0).toDouble(),
    );
  }
}

class RecentReview {
  final String reviewId;
  final String userName;
  final int rating;
  final String comment;
  final String pitchName;
  final String createdAt;

  const RecentReview({
    required this.reviewId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.pitchName,
    required this.createdAt,
  });

  factory RecentReview.fromJson(Map<String, dynamic> json) {
    return RecentReview(
      reviewId: json['reviewId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '—',
      rating: (json['rating'] as num? ?? 0).toInt(),
      comment: json['comment']?.toString() ?? '',
      pitchName: json['pitchName']?.toString() ?? '—',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
