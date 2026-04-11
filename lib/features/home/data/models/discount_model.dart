import '../../domain/entities/discount_entity.dart';

class DiscountModel extends DiscountEntity {
  const DiscountModel({
    required super.id,
    required super.code,
    required super.description,
    required super.value,
    required super.discountType,
    required super.status,
    required super.startDate,
    required super.endDate,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      status: json['status'] as String? ?? 'INACTIVE',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
