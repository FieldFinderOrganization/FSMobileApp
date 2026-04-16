import 'package:equatable/equatable.dart';

class ProviderEntity extends Equatable {
  final String providerId;
  final String userId;
  final String? cardNumber;
  final String? bank;

  const ProviderEntity({
    required this.providerId,
    required this.userId,
    this.cardNumber,
    this.bank,
  });

  @override
  List<Object?> get props => [providerId, userId, cardNumber, bank];

  ProviderEntity copyWith({
    String? providerId,
    String? userId,
    String? cardNumber,
    String? bank,
  }) {
    return ProviderEntity(
      providerId: providerId ?? this.providerId,
      userId: userId ?? this.userId,
      cardNumber: cardNumber ?? this.cardNumber,
      bank: bank ?? this.bank,
    );
  }
}
