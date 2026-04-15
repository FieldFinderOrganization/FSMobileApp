import 'order_item_model.dart';

class OrderModel {
  final int orderId;
  final String userName;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? paymentTime;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.orderId,
    required this.userName,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.paymentTime,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      userName: json['userName'] as String? ?? 'Khách hàng',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'UNKNOWN',
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      paymentTime: json['paymentTime'] != null
          ? DateTime.parse(json['paymentTime'] as String)
          : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
