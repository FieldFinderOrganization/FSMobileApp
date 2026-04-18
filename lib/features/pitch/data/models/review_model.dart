import '../../domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.reviewId,
    required super.pitchId,
    required super.userId,
    required super.userName,
    super.userImageUrl,
    super.pitchName,
    required super.rating,
    required super.comment,
    required super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['reviewId']?.toString() ?? '',
      pitchId: json['pitchId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] as String? ?? 'Người dùng ẩn danh',
      userImageUrl: json['userImageUrl'] as String?,
      pitchName: json['pitchName'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
