import '../../domain/entities/provider_entity.dart';

class ProviderModel extends ProviderEntity {
  const ProviderModel({
    required super.providerId,
    required super.userId,
    super.cardNumber,
    super.bank,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      providerId: json['providerId'] as String,
      userId: json['userId'] as String,
      cardNumber: json['cardNumber'] as String?,
      bank: json['bank'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardNumber': cardNumber,
      'bank': bank,
    };
  }
}
