import 'package:equatable/equatable.dart';
import '../../data/models/order_model.dart';

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();

  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistorySuccess extends OrderHistoryState {
  final List<OrderModel> allOrders;
  final List<OrderModel> filteredOrders;
  final String? selectedStatus;

  const OrderHistorySuccess({
    required this.allOrders,
    required this.filteredOrders,
    this.selectedStatus,
  });

  OrderHistorySuccess copyWith({
    List<OrderModel>? allOrders,
    List<OrderModel>? filteredOrders,
    String? selectedStatus,
    bool clearStatus = false,
  }) {
    return OrderHistorySuccess(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
  }

  @override
  List<Object?> get props => [allOrders, filteredOrders, selectedStatus];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
