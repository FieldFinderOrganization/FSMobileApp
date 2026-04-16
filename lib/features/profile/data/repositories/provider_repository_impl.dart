import '../../domain/repositories/provider_repository.dart';
import '../../domain/entities/provider_entity.dart';
import '../../domain/entities/provider_address_entity.dart';
import '../datasources/provider_remote_datasource.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  final ProviderRemoteDatasource remoteDatasource;

  ProviderRepositoryImpl(this.remoteDatasource);

  @override
  Future<ProviderEntity> getProviderByUserId(String userId) async {
    return await remoteDatasource.fetchProviderByUserId(userId);
  }

  @override
  Future<ProviderEntity> updateProvider(String providerId, String cardNumber, String bank) async {
    return await remoteDatasource.updateProvider(providerId, {
      'cardNumber': cardNumber,
      'bank': bank,
    });
  }

  @override
  Future<List<ProviderAddressEntity>> getAddressesByProvider(String providerId) async {
    return await remoteDatasource.fetchAddressesByProvider(providerId);
  }

  @override
  Future<ProviderAddressEntity> addAddress(String providerId, String address) async {
    return await remoteDatasource.addAddress({
      'providerId': providerId,
      'address': address,
    });
  }

  @override
  Future<ProviderAddressEntity> updateAddress(String addressId, String address) async {
    return await remoteDatasource.updateAddress(addressId, {
      'address': address,
    });
  }

  @override
  Future<void> deleteAddress(String addressId) async {
    await remoteDatasource.deleteAddress(addressId);
  }
}
