class WalletTransactionModel {
  final String txnId;
  final String type; // BOOKING_REVENUE | CANCEL_PENALTY | HOST_COMPENSATION | WITHDRAWAL | ADJUSTMENT
  final double amount; // CÓ DẤU: + cộng, − trừ
  final double balanceAfter;
  final String? reason;
  final String status; // COMPLETED | PENDING | PROCESSING | SUCCEEDED | FAILED
  final String? maskedAccount;
  final DateTime? createdAt;
  final DateTime? processedAt;

  const WalletTransactionModel({
    required this.txnId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.reason,
    required this.status,
    this.maskedAccount,
    this.createdAt,
    this.processedAt,
  });

  bool get isCredit => amount >= 0;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      txnId: json['txnId']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? '',
      maskedAccount: json['maskedAccount'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'].toString())
          : null,
    );
  }
}
