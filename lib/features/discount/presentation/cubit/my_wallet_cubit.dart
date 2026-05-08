import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_discount_entity.dart';
import '../../domain/repositories/discount_repository.dart';

enum WalletStatus { initial, loading, success, failure }

class MyWalletState {
  final WalletStatus status;
  final List<UserDiscountEntity> vouchers;
  final String errorMessage;

  const MyWalletState({
    this.status = WalletStatus.initial,
    this.vouchers = const [],
    this.errorMessage = '',
  });

  MyWalletState copyWith({
    WalletStatus? status,
    List<UserDiscountEntity>? vouchers,
    String? errorMessage,
  }) {
    return MyWalletState(
      status: status ?? this.status,
      vouchers: vouchers ?? this.vouchers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  List<UserDiscountEntity> get _promotionsOnly =>
      vouchers.where((v) => !v.isRefundCredit).toList();

  List<UserDiscountEntity> get available =>
      _promotionsOnly.where((v) => v.isAvailable).toList();

  List<UserDiscountEntity> get usedOrExpired =>
      _promotionsOnly.where((v) => !v.isAvailable).toList();

  List<UserDiscountEntity> get refundCredits =>
      vouchers.where((v) => v.isRefundCredit).toList();
}

class MyWalletCubit extends Cubit<MyWalletState> {
  final DiscountRepository _repository;

  MyWalletCubit({required DiscountRepository repository})
      : _repository = repository,
        super(const MyWalletState());

  Future<void> loadWallet(String userId) async {
    emit(state.copyWith(status: WalletStatus.loading));
    try {
      final vouchers = await _repository.getWallet(userId);
      emit(state.copyWith(status: WalletStatus.success, vouchers: vouchers));
    } catch (e) {
      emit(state.copyWith(
          status: WalletStatus.failure, errorMessage: e.toString()));
    }
  }
}
