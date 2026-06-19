/// Một ngân hàng trong danh sách VietQR (dropdown chọn ngân hàng).
class BankInfoModel {
  final String bin;
  final String name;
  final String shortName;
  final String? logo;

  const BankInfoModel({
    required this.bin,
    required this.name,
    required this.shortName,
    this.logo,
  });

  factory BankInfoModel.fromJson(Map<String, dynamic> json) {
    return BankInfoModel(
      bin: json['bin']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      shortName: json['shortName'] as String? ?? json['name'] as String? ?? '',
      logo: json['logo'] as String?,
    );
  }

  /// Nhãn hiển thị: "MB - Ngân hàng Quân đội".
  String get label => shortName.isNotEmpty ? '$shortName - $name' : name;
}
