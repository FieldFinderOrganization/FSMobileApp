import '../../../order/data/models/order_item_model.dart';
import '../../domain/entities/item_review_entity.dart';

abstract class MyProductReviewsState {}

class MyProductReviewsInitial extends MyProductReviewsState {}

class MyProductReviewsLoading extends MyProductReviewsState {}

class MyProductReviewsLoaded extends MyProductReviewsState {
  final List<ItemReviewEntity> reviews;
  final List<OrderItemModel> unreviewedProducts;

  MyProductReviewsLoaded({
    required this.reviews,
    required this.unreviewedProducts,
  });
}

class MyProductReviewsError extends MyProductReviewsState {
  final String message;
  MyProductReviewsError(this.message);
}

class MyProductReviewsSubmitting extends MyProductReviewsState {}

class MyProductReviewsActionSuccess extends MyProductReviewsState {
  final String message;
  MyProductReviewsActionSuccess(this.message);
}

class MyProductReviewsActionError extends MyProductReviewsState {
  final String message;
  MyProductReviewsActionError(this.message);
}
