/// Kết quả tra cứu tên chủ TK (preview trước khi lưu).
class BankLookupResult {
  final bool found;
  final String? accountName;
  final String? message;

  const BankLookupResult({
    required this.found,
    this.accountName,
    this.message,
  });

  factory BankLookupResult.fromJson(Map<String, dynamic> json) {
    return BankLookupResult(
      found: json['found'] as bool? ?? false,
      accountName: json['accountName'] as String?,
      message: json['message'] as String?,
    );
  }
}
