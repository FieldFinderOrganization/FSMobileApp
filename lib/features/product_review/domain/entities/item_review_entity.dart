import 'package:equatable/equatable.dart';

class ItemReviewEntity extends Equatable {
  final String reviewId;
  final String productId;
  final String userId;
  final String userName;
  final String? productName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  /// Trạng thái kiểm duyệt: PENDING | APPROVED | REJECTED. Null = coi như APPROVED
  /// (danh sách công khai chỉ trả về bản đã duyệt).
  final String? status;

  /// Lý do bị từ chối (nếu có).
  final String? moderationReason;

  const ItemReviewEntity({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.userName,
    this.productName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.status,
    this.moderationReason,
  });

  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';

  @override
  List<Object?> get props => [
        reviewId,
        productId,
        userId,
        userName,
        productName,
        rating,
        comment,
        createdAt,
        status,
        moderationReason,
      ];
}
