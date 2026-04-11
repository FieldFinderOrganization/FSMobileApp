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

  String get displayType {
    switch (type) {
      case 'FIVE_A_SIDE':
        return 'Sân 5';
      case 'SEVEN_A_SIDE':
        return 'Sân 7';
      case 'ELEVEN_A_SIDE':
        return 'Sân 11';
      default:
        return type;
    }
  }
}
