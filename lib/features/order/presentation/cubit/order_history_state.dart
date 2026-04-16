import 'package:equatable/equatable.dart';
import '../../data/models/order_model.dart';
enum OrderSortMode { creationTime, price }

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
  final bool sortAscending;
  final OrderSortMode sortMode;
  final String? message;

  const OrderHistorySuccess({
    required this.allOrders,
    required this.filteredOrders,
    this.selectedStatus,
    this.sortAscending = false,
    this.sortMode = OrderSortMode.creationTime,
    this.message,
  });

  OrderHistorySuccess copyWith({
    List<OrderModel>? allOrders,
    List<OrderModel>? filteredOrders,
    String? selectedStatus,
    bool? sortAscending,
    OrderSortMode? sortMode,
    String? message,
    bool clearStatus = false,
    bool clearMessage = false,
  }) {
    return OrderHistorySuccess(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      sortAscending: sortAscending ?? this.sortAscending,
      sortMode: sortMode ?? this.sortMode,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [allOrders, filteredOrders, selectedStatus, sortAscending, sortMode, message];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
