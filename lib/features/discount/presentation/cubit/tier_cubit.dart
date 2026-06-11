import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tier_info_entity.dart';
import '../../domain/repositories/discount_repository.dart';

enum TierStatus { initial, loading, success, failure }

class TierState {
  final TierStatus status;
  final TierInfoEntity? info;
  final String errorMessage;

  const TierState({
    this.status = TierStatus.initial,
    this.info,
    this.errorMessage = '',
  });

  TierState copyWith({
    TierStatus? status,
    TierInfoEntity? info,
    String? errorMessage,
  }) {
    return TierState(
      status: status ?? this.status,
      info: info ?? this.info,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Hạng hiện tại của user, MEMBER khi chưa load xong.
  String get userTier => info?.tier ?? 'MEMBER';
}

class TierCubit extends Cubit<TierState> {
  final DiscountRepository _repository;

  TierCubit({required DiscountRepository repository})
      : _repository = repository,
        super(const TierState());

  Future<void> load(String userId) async {
    emit(state.copyWith(status: TierStatus.loading));
    try {
      final info = await _repository.getTierInfo(userId);
      emit(state.copyWith(status: TierStatus.success, info: info));
    } catch (e) {
      emit(state.copyWith(
          status: TierStatus.failure, errorMessage: e.toString()));
    }
  }
}
