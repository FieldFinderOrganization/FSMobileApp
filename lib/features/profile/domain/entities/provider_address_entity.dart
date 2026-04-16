import 'package:equatable/equatable.dart';

class ProviderAddressEntity extends Equatable {
  final String providerAddressId;
  final String address;

  const ProviderAddressEntity({
    required this.providerAddressId,
    required this.address,
  });

  @override
  List<Object?> get props => [providerAddressId, address];
}
