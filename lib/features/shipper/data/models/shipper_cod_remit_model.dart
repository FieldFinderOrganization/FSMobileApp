/// Lệnh shipper nộp lại tiền COD qua PayOS — trả về cho FE hiện QR + poll trạng thái.
class ShipperCodRemitModel {
  final String remitId;
  final String? transactionId;
  final String? checkoutUrl;
  final String? qrCode;
  final double amount;
  final String status; // PENDING | CREDITED

  const ShipperCodRemitModel({
    required this.remitId,
    this.transactionId,
    this.checkoutUrl,
    this.qrCode,
    required this.amount,
    required this.status,
  });

  factory ShipperCodRemitModel.fromJson(Map<String, dynamic> json) {
    return ShipperCodRemitModel(
      remitId: json['remitId']?.toString() ?? '',
      transactionId: json['transactionId'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      qrCode: json['qrCode'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'PENDING',
    );
  }
}
