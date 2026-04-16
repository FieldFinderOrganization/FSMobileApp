import '../entities/provider_entity.dart';
import '../entities/provider_address_entity.dart';

abstract class ProviderRepository {
  Future<ProviderEntity> getProviderByUserId(String userId);
  Future<ProviderEntity> updateProvider(String providerId, String cardNumber, String bank);
  Future<List<ProviderAddressEntity>> getAddressesByProvider(String providerId);
  Future<ProviderAddressEntity> addAddress(String providerId, String address);
  Future<ProviderAddressEntity> updateAddress(String addressId, String address);
  Future<void> deleteAddress(String addressId);
}
