import 'package:equatable/equatable.dart';

class ProviderEntity extends Equatable {
  final String providerId;
  final String userId;
  // TK ngân hàng chủ sân chuyển sang entity BankAccount (key theo userId).

  const ProviderEntity({
    required this.providerId,
    required this.userId,
  });

  @override
  List<Object?> get props => [providerId, userId];

  ProviderEntity copyWith({
    String? providerId,
    String? userId,
  }) {
    return ProviderEntity(
      providerId: providerId ?? this.providerId,
      userId: userId ?? this.userId,
    );
  }
}
