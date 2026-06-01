import 'package:equatable/equatable.dart';

class ProviderAddressEntity extends Equatable {
  final String providerAddressId;
  final String address;
  final double? latitude;
  final double? longitude;

  const ProviderAddressEntity({
    required this.providerAddressId,
    required this.address,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [providerAddressId, address, latitude, longitude];
}
