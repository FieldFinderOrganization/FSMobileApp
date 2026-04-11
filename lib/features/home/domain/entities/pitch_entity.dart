class PitchEntity {
  final String pitchId;
  final String name;
  final String type;
  final String environment;
  final double price;
  final String description;
  final List<String> imageUrls;

  const PitchEntity({
    required this.pitchId,
    required this.name,
    required this.type,
    required this.environment,
    required this.price,
    required this.description,
    required this.imageUrls,
  });

  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';
}
