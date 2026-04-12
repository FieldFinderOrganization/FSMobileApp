class PaymentResponseModel {
  final String transactionId;
  final String checkoutUrl;
  final String? qrCode;
  final String amount;
  final String status;
  final String? ownerName;
  final String? ownerCardNumber;
  final String? ownerBank;

  PaymentResponseModel({
    required this.transactionId,
    required this.checkoutUrl,
    this.qrCode,
    required this.amount,
    required this.status,
    this.ownerName,
    this.ownerCardNumber,
    this.ownerBank,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      transactionId: json['transactionId'] ?? '',
      checkoutUrl: json['checkoutUrl'] ?? '',
      qrCode: json['qrCode'],
      amount: json['amount'].toString(),
      status: json['status'] ?? '',
      ownerName: json['ownerName'],
      ownerCardNumber: json['ownerCardNumber'],
      ownerBank: json['ownerBank'],
    );
  }

  bool get isPaid => status == 'PAID';
}
