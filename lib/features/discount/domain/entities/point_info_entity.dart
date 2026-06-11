/// Số dư + lịch sử điểm thưởng (BE: GET /points/{userId}).
class PointInfoEntity {
  final int balance;
  final List<PointTransactionEntity> transactions;

  const PointInfoEntity({required this.balance, this.transactions = const []});
}

class PointTransactionEntity {
  final int amount; // signed: + cộng, - trừ
  final String type; // EARN_ORDER | REVERT_ORDER | REDEEM_VOUCHER
  final String description;
  final DateTime createdAt;

  const PointTransactionEntity({
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  bool get isPositive => amount > 0;
}
