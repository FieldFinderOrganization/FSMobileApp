import '../../domain/entities/point_info_entity.dart';

class PointInfoModel extends PointInfoEntity {
  const PointInfoModel({required super.balance, super.transactions});

  factory PointInfoModel.fromJson(Map<String, dynamic> json) {
    return PointInfoModel(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => PointTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PointTransactionModel extends PointTransactionEntity {
  const PointTransactionModel({
    required super.amount,
    required super.type,
    required super.description,
    required super.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
