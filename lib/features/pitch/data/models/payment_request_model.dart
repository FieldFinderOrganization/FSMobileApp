import 'dart:convert';

class PaymentRequestModel {
  final String bookingId;
  final String userId;
  final double amount;
  final String paymentMethod;

  PaymentRequestModel({
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
    };
  }

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) {
    return PaymentRequestModel(
      bookingId: json['bookingId'],
      userId: json['userId'],
      amount: json['amount'].toDouble(),
      paymentMethod: json['paymentMethod'],
    );
  }
}
