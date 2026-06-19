class ProviderDebtModel {
  final String providerDebtId;
  final String? providerId;
  final String? providerName;
  final String sourceBookingId;
  final double amount;
  final String status; // OUTSTANDING | SETTLED | WAIVED
  final String? reason;
  final bool overdue;
  final DateTime? deadlineAt;
  final DateTime? createdAt;
  final DateTime? settledAt;

  const ProviderDebtModel({
    required this.providerDebtId,
    this.providerId,
    this.providerName,
    required this.sourceBookingId,
    required this.amount,
    required this.status,
    this.reason,
    this.overdue = false,
    this.deadlineAt,
    this.createdAt,
    this.settledAt,
  });

  factory ProviderDebtModel.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) =>
        v != null ? DateTime.tryParse(v.toString()) : null;
    return ProviderDebtModel(
      providerDebtId: json['providerDebtId']?.toString() ?? '',
      providerId: json['providerId']?.toString(),
      providerName: json['providerName'] as String?,
      sourceBookingId: json['sourceBookingId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      reason: json['reason'] as String?,
      overdue: json['overdue'] as bool? ?? false,
      deadlineAt: parse(json['deadlineAt']),
      createdAt: parse(json['createdAt']),
      settledAt: parse(json['settledAt']),
    );
  }
}
