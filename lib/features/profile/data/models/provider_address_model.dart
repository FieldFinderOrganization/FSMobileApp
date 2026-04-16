import '../../domain/entities/provider_address_entity.dart';

class ProviderAddressModel extends ProviderAddressEntity {
  const ProviderAddressModel({
    required super.providerAddressId,
    required super.address,
  });

  factory ProviderAddressModel.fromJson(Map<String, dynamic> json) {
    return ProviderAddressModel(
      providerAddressId: json['providerAddressId'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
    };
  }
}
