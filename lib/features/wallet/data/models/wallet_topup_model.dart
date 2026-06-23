/// Kết quả tạo lệnh nạp ví: link/QR PayOS + id để poll trạng thái.
class WalletTopupModel {
  final String topupId;
  final String? transactionId;
  final String? checkoutUrl;
  final String? qrCode;
  final double amount;
  final String status;

  const WalletTopupModel({
    required this.topupId,
    this.transactionId,
    this.checkoutUrl,
    this.qrCode,
    required this.amount,
    required this.status,
  });

  factory WalletTopupModel.fromJson(Map<String, dynamic> json) {
    return WalletTopupModel(
      topupId: json['topupId'] as String,
      transactionId: json['transactionId'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      qrCode: json['qrCode'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
    );
  }
}
