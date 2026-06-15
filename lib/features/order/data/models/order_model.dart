import 'order_item_model.dart';

class OrderModel {
  final int orderId;
  final String userName;
  final double totalAmount;
  final double shippingFee;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? paymentTime;
  final String? deliveryAddress;
  final double? destLat;
  final double? destLng;
  final String? shipperName;
  final String? shipperId;
  final String? customerId;
  final String? customerPhone;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.orderId,
    required this.userName,
    required this.totalAmount,
    this.shippingFee = 0.0,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.paymentTime,
    this.deliveryAddress,
    this.destLat,
    this.destLng,
    this.shipperName,
    this.shipperId,
    this.customerId,
    this.customerPhone,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      userName: json['userName'] as String? ?? 'Khách hàng',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'UNKNOWN',
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      paymentTime: json['paymentTime'] != null
          ? DateTime.parse(json['paymentTime'] as String)
          : null,
      deliveryAddress: json['deliveryAddress'] as String?,
      destLat: (json['destLat'] as num?)?.toDouble(),
      destLng: (json['destLng'] as num?)?.toDouble(),
      shipperName: json['shipperName'] as String?,
      shipperId: json['shipperId'] as String?,
      customerId: json['customerId'] as String?,
      customerPhone: json['customerPhone'] as String?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
