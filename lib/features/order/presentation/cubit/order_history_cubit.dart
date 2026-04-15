import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/models/order_model.dart';
import 'order_history_state.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  final OrderRemoteDataSource dataSource;
  final String userId;

  OrderHistoryCubit({
    required this.dataSource,
    required this.userId,
  }) : super(OrderHistoryInitial());

  Future<void> loadOrders() async {
    emit(OrderHistoryLoading());
    try {
      final orders = await dataSource.getOrdersByUser(userId);
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(OrderHistorySuccess(
        allOrders: orders,
        filteredOrders: orders,
      ));
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? e.message ?? e.toString();
      emit(OrderHistoryError(message));
    } catch (e) {
      emit(OrderHistoryError(e.toString()));
    }
  }

  void filterByStatus(String? status) {
    if (state is! OrderHistorySuccess) return;
    final current = state as OrderHistorySuccess;

    final filtered = status == null
        ? current.allOrders
        : current.allOrders
            .where((o) => o.status.toUpperCase() == status.toUpperCase())
            .toList();

    emit(current.copyWith(
      filteredOrders: filtered,
      selectedStatus: status,
      clearStatus: status == null,
    ));
  }
}
