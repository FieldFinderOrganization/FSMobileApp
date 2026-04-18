class RevenuePointModel {
  final String date;
  final double revenue;

  const RevenuePointModel({required this.date, required this.revenue});

  factory RevenuePointModel.fromJson(Map<String, dynamic> json) {
    return RevenuePointModel(
      date: json['date'] as String,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}
