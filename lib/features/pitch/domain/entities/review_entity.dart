import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String reviewId;
  final String pitchId;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String? pitchName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  /// Trạng thái kiểm duyệt: PENDING | APPROVED | REJECTED. Null = coi như APPROVED.
  final String? status;

  /// Lý do bị từ chối (nếu có).
  final String? moderationReason;

  const ReviewEntity({
    required this.reviewId,
    required this.pitchId,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    this.pitchName,
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
        pitchId,
        userId,
        userName,
        userImageUrl,
        pitchName,
        rating,
        comment,
        createdAt,
        status,
        moderationReason,
      ];
}
