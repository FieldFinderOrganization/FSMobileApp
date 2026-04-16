import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/provider_entity.dart';
import '../../domain/entities/provider_address_entity.dart';
import '../../domain/repositories/provider_repository.dart';

abstract class ProviderState extends Equatable {
  const ProviderState();
  @override
  List<Object?> get props => [];
}

class ProviderInitial extends ProviderState {}

class ProviderLoading extends ProviderState {}

class ProviderLoaded extends ProviderState {
  final ProviderEntity provider;
  final List<ProviderAddressEntity> addresses;
  final String? message;

  const ProviderLoaded({
    required this.provider,
    required this.addresses,
    this.message,
  });

  @override
  List<Object?> get props => [provider, addresses, message];
}

class ProviderError extends ProviderState {
  final String message;
  const ProviderError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProviderCubit extends Cubit<ProviderState> {
  final ProviderRepository repository;

  ProviderCubit({required this.repository}) : super(ProviderInitial());

  Future<void> loadProviderData(String userId) async {
    emit(ProviderLoading());
    try {
      final provider = await repository.getProviderByUserId(userId);
      final addresses = await repository.getAddressesByProvider(provider.providerId);
      emit(ProviderLoaded(provider: provider, addresses: addresses));
    } catch (e) {
      emit(ProviderError(e.toString()));
    }
  }

  Future<void> updateProviderInfo(String providerId, String cardNumber, String bank) async {
    final currentState = state;
    if (currentState is ProviderLoaded) {
      try {
        final updatedProvider = await repository.updateProvider(providerId, cardNumber, bank);
        emit(ProviderLoaded(
          provider: updatedProvider,
          addresses: currentState.addresses,
          message: 'Cập nhật thông tin ngân hàng thành công!',
        ));
      } catch (e) {
        emit(ProviderError(e.toString()));
      }
    }
  }

  Future<void> addAddress(String providerId, String address) async {
    final currentState = state;
    if (currentState is ProviderLoaded) {
      try {
        await repository.addAddress(providerId, address);
        final addresses = await repository.getAddressesByProvider(providerId);
        emit(ProviderLoaded(
          provider: currentState.provider,
          addresses: addresses,
          message: 'Thêm khu vực thành công!',
        ));
      } catch (e) {
        emit(ProviderError(e.toString()));
      }
    }
  }

  Future<void> updateAddress(String addressId, String address) async {
    final currentState = state;
    if (currentState is ProviderLoaded) {
      try {
        await repository.updateAddress(addressId, address);
        final addresses = await repository.getAddressesByProvider(currentState.provider.providerId);
        emit(ProviderLoaded(
          provider: currentState.provider,
          addresses: addresses,
          message: 'Cập nhật khu vực thành công!',
        ));
      } catch (e) {
        emit(ProviderError(e.toString()));
      }
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final currentState = state;
    if (currentState is ProviderLoaded) {
      try {
        await repository.deleteAddress(addressId);
        final addresses = await repository.getAddressesByProvider(currentState.provider.providerId);
        emit(ProviderLoaded(
          provider: currentState.provider,
          addresses: addresses,
          message: 'Xóa khu vực thành công!',
        ));
      } catch (e) {
        emit(ProviderError(e.toString()));
      }
    }
  }

  void clearMessage() {
    final currentState = state;
    if (currentState is ProviderLoaded && currentState.message != null) {
      emit(ProviderLoaded(
        provider: currentState.provider,
        addresses: currentState.addresses,
        message: null,
      ));
    }
  }
}
