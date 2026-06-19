class BankAccountModel {
  final String bankAccountId;
  final String bankBin;
  final String? bankName;
  final String accountNumber;
  final String? maskedAccountNumber;
  final String accountName;
  final bool isDefault;
  final bool verified;

  const BankAccountModel({
    required this.bankAccountId,
    required this.bankBin,
    this.bankName,
    required this.accountNumber,
    this.maskedAccountNumber,
    required this.accountName,
    this.isDefault = false,
    this.verified = false,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      bankAccountId: json['bankAccountId']?.toString() ?? '',
      bankBin: json['bankBin']?.toString() ?? '',
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber']?.toString() ?? '',
      maskedAccountNumber: json['maskedAccountNumber'] as String?,
      accountName: json['accountName'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
    );
  }
}
