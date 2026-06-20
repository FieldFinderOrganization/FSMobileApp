import '../../domain/entities/provider_entity.dart';

class ProviderModel extends ProviderEntity {
  const ProviderModel({
    required super.providerId,
    required super.userId,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      providerId: json['providerId'] as String,
      userId: json['userId'] as String,
    );
  }
}
