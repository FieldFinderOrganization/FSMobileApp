import '../../domain/entities/item_review_entity.dart';

class ItemReviewModel extends ItemReviewEntity {
  const ItemReviewModel({
    required super.reviewId,
    required super.productId,
    required super.userId,
    required super.userName,
    super.productName,
    required super.rating,
    required super.comment,
    required super.createdAt,
    super.status,
    super.moderationReason,
  });

  factory ItemReviewModel.fromJson(Map<String, dynamic> json) {
    return ItemReviewModel(
      reviewId: json['reviewId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] as String? ?? 'Người dùng ẩn danh',
      productName: json['productName'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String?,
      moderationReason: json['moderationReason'] as String?,
    );
  }
}
