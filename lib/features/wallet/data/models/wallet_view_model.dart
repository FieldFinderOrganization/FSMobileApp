class WalletViewModel {
  final double balance; // có thể âm = nợ
  final double reserve;
  final double withdrawable;
  final bool blocked;
  final DateTime? negativeSince;
  final int blockGraceDays;

  const WalletViewModel({
    required this.balance,
    required this.reserve,
    required this.withdrawable,
    required this.blocked,
    this.negativeSince,
    this.blockGraceDays = 7,
  });

  bool get isNegative => balance < 0;

  /// Hạn phải bù trước khi bị chặn nhận booking.
  DateTime? get blockDeadline =>
      negativeSince?.add(Duration(days: blockGraceDays));

  factory WalletViewModel.fromJson(Map<String, dynamic> json) {
    return WalletViewModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      reserve: (json['reserve'] as num?)?.toDouble() ?? 0,
      withdrawable: (json['withdrawable'] as num?)?.toDouble() ?? 0,
      blocked: json['blocked'] as bool? ?? false,
      negativeSince: json['negativeSince'] != null
          ? DateTime.tryParse(json['negativeSince'].toString())
          : null,
      blockGraceDays: (json['blockGraceDays'] as num?)?.toInt() ?? 7,
    );
  }
}
