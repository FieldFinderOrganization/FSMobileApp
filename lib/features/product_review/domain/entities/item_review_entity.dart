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

  const ItemReviewEntity({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.userName,
    this.productName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

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
      ];
}
