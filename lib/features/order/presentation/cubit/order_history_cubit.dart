import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/models/order_model.dart';
import '../../../refund/data/datasources/refund_remote_data_source.dart';
import '../../../refund/data/models/refund_request_model.dart';
import 'order_history_state.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderRemoteDataSource dataSource;
  final RefundRemoteDataSource? refundDataSource;
  final String userId;

  /// Mã hoàn tiền cuối cùng vừa phát hành — listener UI dùng để show dialog rồi clear.
  RefundRequestModel? lastRefund;

  OrderHistoryCubit({
    required this.dataSource,
    required this.userId,
    this.refundDataSource,
  }) : super(OrderHistoryInitial());

  void clearLastRefund() {
    lastRefund = null;
  }

  Future<void> loadOrders() async {
    emit(OrderHistoryLoading());
    try {
      final orders = await dataSource.getOrdersByUser(userId);
      
      final filtered = _applyFilters(
        orders,
        null,
        false, // sortAscending
        OrderSortMode.creationTime,
      );

      emit(OrderHistorySuccess(
        allOrders: orders,
        filteredOrders: filtered,
      ));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? e.toString();
      emit(OrderHistoryError(message));
    } catch (e) {
      emit(OrderHistoryError(e.toString()));
    }
  }

  void clearMessage() {
    if (state is OrderHistorySuccess) {
      final currentState = state as OrderHistorySuccess;
      if (currentState.message != null) {
        emit(currentState.copyWith(clearMessage: true));
      }
    }
  }

  void setSortMode(OrderSortMode mode) {
    if (state is! OrderHistorySuccess) return;
    final currentState = state as OrderHistorySuccess;

    final filtered = _applyFilters(
      currentState.allOrders,
      currentState.selectedStatus,
      currentState.sortAscending,
      mode,
    );

    emit(currentState.copyWith(
      filteredOrders: filtered,
      sortMode: mode,
    ));
  }

  void toggleSortOrder() {
    if (state is! OrderHistorySuccess) return;
    final currentState = state as OrderHistorySuccess;
    final newAscending = !currentState.sortAscending;

    final filtered = _applyFilters(
      currentState.allOrders,
      currentState.selectedStatus,
      newAscending,
      currentState.sortMode,
    );

    emit(currentState.copyWith(
      filteredOrders: filtered,
      sortAscending: newAscending,
    ));
  }

  Future<void> cancelOrder(int orderId, {String? reason}) async {
    try {
      await dataSource.cancelOrder(orderId, reason: reason);

      // Fetch refund (nullable — đơn PENDING không sinh refund)
      lastRefund = null;
      if (refundDataSource != null) {
        try {
          lastRefund = await refundDataSource!.getBySource(
            type: 'ORDER',
            sourceId: orderId.toString(),
          );
        } catch (_) {
          // Không fail toàn flow chỉ vì fetch refund lỗi
        }
      }

      final orders = await dataSource.getOrdersByUser(userId);

      final filtered = _applyFilters(
        orders,
        null,
        false, // sortAscending
        OrderSortMode.creationTime,
      );

      emit(OrderHistorySuccess(
        allOrders: orders,
        filteredOrders: filtered,
        message: lastRefund?.refundCode != null
            ? 'Hủy đơn thành công · Mã hoàn tiền ${lastRefund!.refundCode}'
            : 'Hủy đơn hàng thành công!',
      ));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? e.toString();
      emit(OrderHistoryError(message));
    } catch (e) {
      emit(OrderHistoryError(e.toString()));
    }
  }

  void filterByStatus(String? status) {
    if (state is! OrderHistorySuccess) return;
    final current = state as OrderHistorySuccess;

    final filtered = _applyFilters(
      current.allOrders,
      status,
      current.sortAscending,
      current.sortMode,
    );

    emit(
      current.copyWith(
        filteredOrders: filtered,
        selectedStatus: status,
        clearStatus: status == null,
      ),
    );
  }

  List<OrderModel> _applyFilters(
    List<OrderModel> all,
    String? status,
    bool ascending,
    OrderSortMode sortMode,
  ) {
    final result = all.where((order) {
      if (status != null && status != 'Tất cả') {
        return order.status.toUpperCase() == status.toUpperCase();
      }
      return true;
    }).toList();

    result.sort((a, b) {
      int cmp;
      if (sortMode == OrderSortMode.price) {
        cmp = a.totalAmount.compareTo(b.totalAmount);
      } else {
        cmp = a.createdAt.compareTo(b.createdAt);
      }

      if (cmp == 0) {
        cmp = a.orderId.compareTo(b.orderId);
      }

      return ascending ? cmp : -cmp;
    });

    return result;
  }
}
