class PitchEntity {
  final String pitchId;
  final String name;
  final String type;
  final String environment;
  final double price;
  final String description;
  final List<String> imageUrls;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? providerUserId;
  final String? providerName;
  final String? providerPhone;
  final double? providerRating; // điểm TB mọi sân của chủ; null = chưa có
  final int? providerReviewCount;
  final String? status; // 'ACTIVE' | 'INACTIVE'
  final DateTime? deactivationDate; // ngày ngưng theo lịch; từ ngày này không đặt được

  const PitchEntity({
    required this.pitchId,
    required this.name,
    required this.type,
    required this.environment,
    required this.price,
    required this.description,
    required this.imageUrls,
    this.address = '',
    this.latitude,
    this.longitude,
    this.providerUserId,
    this.providerName,
    this.providerPhone,
    this.providerRating,
    this.providerReviewCount,
    this.status,
    this.deactivationDate,
  });

  /// Có toạ độ để dẫn đường không.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Sân đang hoạt động.
  bool get isActive => status == null || status == 'ACTIVE';

  /// Ngày [d] có nằm trong khoảng đã ngưng (>= ngày ngưng) không → không đặt được.
  bool isDateDeactivated(DateTime d) {
    if (deactivationDate == null) return false;
    final dd = DateTime(
        deactivationDate!.year, deactivationDate!.month, deactivationDate!.day);
    final day = DateTime(d.year, d.month, d.day);
    return !day.isBefore(dd);
  }

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

  /// Chuyển nhãn hiển thị ("Sân 7") sang mã enum BE ("SEVEN_A_SIDE").
  /// BE lọc bằng `PitchType.valueOf(type)`, gửi nhãn sẽ throw → bỏ lọc → lẫn loại.
  static String typeCodeFromDisplay(String label) {
    switch (label.trim()) {
      case 'Sân 5':
        return 'FIVE_A_SIDE';
      case 'Sân 7':
        return 'SEVEN_A_SIDE';
      case 'Sân 11':
        return 'ELEVEN_A_SIDE';
      default:
        return label; // đã là mã enum hoặc rỗng
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
