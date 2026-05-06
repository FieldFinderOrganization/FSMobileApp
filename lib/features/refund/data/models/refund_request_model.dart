class RefundRequestModel {
  final String refundId;
  final String sourceType; // ORDER | BOOKING
  final String sourceId;
  final double amount;
  final String status;
  final String? reason;
  final String? refundCode;
  final DateTime? expiryDate;
  final double? remainingValue;
  final DateTime? createdAt;
  final DateTime? processedAt;

  const RefundRequestModel({
    required this.refundId,
    required this.sourceType,
    required this.sourceId,
    required this.amount,
    required this.status,
    this.reason,
    this.refundCode,
    this.expiryDate,
    this.remainingValue,
    this.createdAt,
    this.processedAt,
  });

  factory RefundRequestModel.fromJson(Map<String, dynamic> json) {
    return RefundRequestModel(
      refundId: json['refundId']?.toString() ?? '',
      sourceType: json['sourceType'] as String? ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      reason: json['reason'] as String?,
      refundCode: json['refundCode'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      remainingValue: (json['remainingValue'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'].toString())
          : null,
    );
  }
}
