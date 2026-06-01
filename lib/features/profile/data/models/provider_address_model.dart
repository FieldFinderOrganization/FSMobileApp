import '../../domain/entities/provider_address_entity.dart';

class ProviderAddressModel extends ProviderAddressEntity {
  const ProviderAddressModel({
    required super.providerAddressId,
    required super.address,
    super.latitude,
    super.longitude,
  });

  factory ProviderAddressModel.fromJson(Map<String, dynamic> json) {
    return ProviderAddressModel(
      providerAddressId: json['providerAddressId'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
    };
  }
}
