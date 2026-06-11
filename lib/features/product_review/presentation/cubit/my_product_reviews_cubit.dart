import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../order/data/datasources/order_remote_data_source.dart';
import '../../../order/data/models/order_item_model.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/repositories/item_review_repository_impl.dart';
import '../../domain/entities/item_review_entity.dart';
import 'my_product_reviews_state.dart';

class MyProductReviewsCubit extends Cubit<MyProductReviewsState> {
  final ItemReviewRepositoryImpl reviewRepository;
  final OrderRemoteDataSource orderDataSource;
  final String userId;

  /// = BE ORDER_REFUND_WINDOW_HOURS — đơn còn trong cửa sổ này vẫn hủy được.
  static const int _refundWindowHours = 24;

  MyProductReviewsCubit({
    required this.reviewRepository,
    required this.orderDataSource,
    required this.userId,
  }) : super(MyProductReviewsInitial());

  Future<void> load() async {
    emit(MyProductReviewsLoading());
    try {
      final reviews = await reviewRepository.getReviewsByUser(userId);
      final orders = await orderDataSource.getOrdersByUser(userId);

      final reviewedProductIds = reviews.map((r) => r.productId).toSet();

      // Gom 1 card / sản phẩm (lần đầu gặp) từ các đơn đủ điều kiện, bỏ SP đã review.
      final seen = <String>{};
      final unreviewedProducts = <OrderItemModel>[];
      for (final order in orders) {
        if (!_isReviewable(order)) continue;
        for (final item in order.items) {
          final pid = item.productId.toString();
          if (pid.isEmpty || pid == '0') continue;
          if (reviewedProductIds.contains(pid)) continue;
          if (seen.add(pid)) {
            unreviewedProducts.add(item);
          }
        }
      }

      emit(MyProductReviewsLoaded(
        reviews: reviews,
        unreviewedProducts: unreviewedProducts,
      ));
    } catch (e) {
      emit(MyProductReviewsError(e.toString()));
    }
  }

  /// Đơn đủ điều kiện đánh giá = đơn KHÔNG còn hủy được:
  /// SHIPPING/DELIVERED, hoặc CONFIRMED/PAID đã qua cửa sổ hoàn tiền 24h.
  bool _isReviewable(OrderModel o) {
    final s = o.status.toUpperCase();
    if (s == 'SHIPPING' || s == 'DELIVERED') return true;
    if (s == 'CONFIRMED' || s == 'PAID') {
      final pt = o.paymentTime;
      return pt != null &&
          DateTime.now()
              .isAfter(pt.add(const Duration(hours: _refundWindowHours)));
    }
    return false; // PENDING, CANCELED
  }

  Future<void> submitReview({
    required int productId,
    required int rating,
    required String comment,
  }) async {
    emit(MyProductReviewsSubmitting());
    ItemReviewEntity created;
    try {
      created = await reviewRepository.addReview(
        userId: userId,
        productId: productId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      emit(MyProductReviewsActionError(e.toString()));
      return;
    }
    emit(MyProductReviewsActionSuccess(_submitMessage(created)));
    await load();
  }

  Future<void> editReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    emit(MyProductReviewsSubmitting());
    ItemReviewEntity updated;
    try {
      updated = await reviewRepository.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      emit(MyProductReviewsActionError(e.toString()));
      return;
    }
    emit(MyProductReviewsActionSuccess(_submitMessage(updated)));
    await load();
  }

  /// Thông báo theo kết quả kiểm duyệt: bị auto từ chối / đang chờ duyệt / đã duyệt.
  String _submitMessage(ItemReviewEntity review) {
    if (review.isRejected) {
      final reason = review.moderationReason?.trim();
      return reason != null && reason.isNotEmpty
          ? 'Đánh giá bị từ chối: $reason'
          : 'Đánh giá bị từ chối do vi phạm nội dung.';
    }
    if (review.isPending) {
      return 'Đã gửi đánh giá, đang chờ kiểm duyệt.';
    }
    return 'Đánh giá đã được gửi!';
  }

  Future<void> deleteReview(String reviewId) async {
    emit(MyProductReviewsSubmitting());
    try {
      await reviewRepository.deleteReview(reviewId);
    } catch (e) {
      emit(MyProductReviewsActionError(e.toString()));
      return;
    }
    emit(MyProductReviewsActionSuccess('Đánh giá đã được xóa!'));
    await load();
  }
}
