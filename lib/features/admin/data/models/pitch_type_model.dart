class PitchTypeModel {
  final String type;
  final int count;
  final double percentage;

  const PitchTypeModel({
    required this.type,
    required this.count,
    required this.percentage,
  });

  factory PitchTypeModel.fromJson(Map<String, dynamic> json) {
    return PitchTypeModel(
      type: json['type'] as String,
      count: (json['count'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
