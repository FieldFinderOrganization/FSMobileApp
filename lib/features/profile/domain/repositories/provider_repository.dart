import '../entities/provider_entity.dart';
import '../entities/provider_address_entity.dart';
import '../../data/models/pitch_ranking_model.dart';

abstract class ProviderRepository {
  Future<ProviderEntity> getProviderByUserId(String userId);
  Future<List<PitchRankingModel>> getPitchRankings(String providerId);
  Future<ProviderEntity> updateProvider(String providerId, String cardNumber, String bank);
  Future<List<ProviderAddressEntity>> getAddressesByProvider(String providerId);
  Future<ProviderAddressEntity> addAddress(String providerId, String address,
      {double? latitude, double? longitude});
  Future<ProviderAddressEntity> updateAddress(String addressId, String address,
      {double? latitude, double? longitude});
  Future<void> deleteAddress(String addressId);
}
