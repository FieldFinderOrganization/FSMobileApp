class AdminPitchListModel {
  final List<AdminPitchItem> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  const AdminPitchListModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });

  factory AdminPitchListModel.fromJson(Map<String, dynamic> json) {
    return AdminPitchListModel(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => AdminPitchItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num? ?? 0).toInt(),
      totalPages: (json['totalPages'] as num? ?? 0).toInt(),
      currentPage: (json['currentPage'] as num? ?? 0).toInt(),
    );
  }
}

class AdminPitchItem {
  final String pitchId;
  final String name;
  final String type;
  final String providerName;
  final double price;
  final String environment;
  final String? providerAddressId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? status; // 'ACTIVE' | 'INACTIVE'

  const AdminPitchItem({
    required this.pitchId,
    required this.name,
    required this.type,
    required this.providerName,
    required this.price,
    required this.environment,
    this.providerAddressId,
    this.address,
    this.latitude,
    this.longitude,
    this.status,
  });

  bool get isActive => status == null || status == 'ACTIVE';

  factory AdminPitchItem.fromJson(Map<String, dynamic> json) {
    return AdminPitchItem(
      pitchId: json['pitchId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? '—',
      price: (json['price'] as num? ?? 0).toDouble(),
      environment: json['environment']?.toString() ?? '',
      providerAddressId: json['providerAddressId']?.toString(),
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String?,
    );
  }
}
