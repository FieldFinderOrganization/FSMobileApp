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
  });

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
      ];
}
