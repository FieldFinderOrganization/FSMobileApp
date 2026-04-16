import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/provider_model.dart';
import '../models/provider_address_model.dart';

class ProviderRemoteDatasource {
  final Dio _dio;

  ProviderRemoteDatasource(this._dio);

  Future<ProviderModel> fetchProviderByUserId(String userId) async {
    final response = await _dio.get('${ApiConstants.providers}/user/$userId');
    return ProviderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProviderModel> updateProvider(String providerId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.providers}/$providerId', data: data);
    return ProviderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ProviderAddressModel>> fetchAddressesByProvider(String providerId) async {
    final response = await _dio.get('${ApiConstants.providerAddresses}/provider/$providerId');
    final list = response.data as List;
    return list.map((e) => ProviderAddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProviderAddressModel> addAddress(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.providerAddresses, data: data);
    return ProviderAddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProviderAddressModel> updateAddress(String addressId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.providerAddresses}/$addressId', data: data);
    return ProviderAddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String addressId) async {
    await _dio.delete('${ApiConstants.providerAddresses}/$addressId');
  }
}
