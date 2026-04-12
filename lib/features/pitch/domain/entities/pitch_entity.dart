class PitchEntity {
  final String pitchId;
  final String name;
  final String type;
  final String environment;
  final double price;
  final String description;
  final List<String> imageUrls;
  final String address;

  const PitchEntity({
    required this.pitchId,
    required this.name,
    required this.type,
    required this.environment,
    required this.price,
    required this.description,
    required this.imageUrls,
    this.address = '',
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

  /// Trích quận/huyện từ chuỗi địa chỉ.
  /// Ví dụ: "123 Nguyễn Trãi, Phường 2, Quận 5, TP.HCM" → "Quận 5"
  String get district {
    if (address.isEmpty) return '';
    final parts = address.split(',');
    for (final part in parts) {
      final t = part.trim();
      if (t.startsWith('Quận') ||
          t.startsWith('Huyện') ||
          t.startsWith('Q.') ||
          t.startsWith('H.')) {
        return t;
      }
    }
    // fallback: phần áp chót (thường là quận nếu cuối là tp)
    if (parts.length >= 2) return parts[parts.length - 2].trim();
    return parts.last.trim();
  }
}
