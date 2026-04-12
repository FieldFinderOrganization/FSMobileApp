import '../../domain/entities/pitch_entity.dart';

class PitchModel extends PitchEntity {
  const PitchModel({
    required super.pitchId,
    required super.name,
    required super.type,
    required super.environment,
    required super.price,
    required super.description,
    required super.imageUrls,
    super.address,
  });

  factory PitchModel.fromJson(Map<String, dynamic> json) {
    return PitchModel(
      pitchId: json['pitchId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      environment: json['environment'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      address: json['address'] as String? ?? '',
    );
  }
}
