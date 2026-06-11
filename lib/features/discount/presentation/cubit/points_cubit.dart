import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../../domain/entities/point_info_entity.dart';
import '../../domain/repositories/discount_repository.dart';

enum PointsStatus { initial, loading, success, failure }

class PointsState {
  final PointsStatus status;
  final int balance;
  final List<PointTransactionEntity> transactions;
  final List<AdminDiscountEntity> catalog; // mã đổi được bằng điểm
  final Set<String> ownedCodes; // mã đã có trong ví (chặn đổi lại)
  final String errorMessage;
  final String? redeemingId; // discountId đang đổi (spinner + disable)

  const PointsState({
    this.status = PointsStatus.initial,
    this.balance = 0,
    this.transactions = const [],
    this.catalog = const [],
    this.ownedCodes = const {},
    this.errorMessage = '',
    this.redeemingId,
  });

  PointsState copyWith({
    PointsStatus? status,
    int? balance,
    List<PointTransactionEntity>? transactions,
    List<AdminDiscountEntity>? catalog,
    Set<String>? ownedCodes,
    String? errorMessage,
    String? redeemingId,
    bool clearRedeeming = false,
  }) {
    return PointsState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      catalog: catalog ?? this.catalog,
      ownedCodes: ownedCodes ?? this.ownedCodes,
      errorMessage: errorMessage ?? this.errorMessage,
      redeemingId: clearRedeeming ? null : (redeemingId ?? this.redeemingId),
    );
  }
}

class PointsCubit extends Cubit<PointsState> {
  final DiscountRepository _repository;

  PointsCubit({required DiscountRepository repository})
      : _repository = repository,
        super(const PointsState());

  Future<void> load(String userId) async {
    emit(state.copyWith(status: PointsStatus.loading));
    try {
      final results = await Future.wait([
        _repository.getPointInfo(userId),
        _repository.getAllDiscounts(),
        _repository.getWallet(userId),
      ]);
      final info = results[0] as PointInfoEntity;
      final all = results[1] as List<AdminDiscountEntity>;
      final wallet = results[2] as List;

      final catalog = all
          .where((d) => d.pointCost != null && d.isClaimable)
          .toList()
        ..sort((a, b) => (a.pointCost ?? 0).compareTo(b.pointCost ?? 0));

      emit(state.copyWith(
        status: PointsStatus.success,
        balance: info.balance,
        transactions: info.transactions,
        catalog: catalog,
        ownedCodes: wallet.map((w) => w.discountCode as String).toSet(),
      ));
    } catch (e) {
      emit(state.copyWith(
          status: PointsStatus.failure, errorMessage: e.toString()));
    }
  }

  /// Đổi điểm lấy mã; true = thành công (UI hiện snackbar + reload).
  Future<bool> redeem(String userId, String discountId) async {
    if (state.redeemingId != null) return false;
    emit(state.copyWith(redeemingId: discountId));
    try {
      await _repository.redeemVoucher(userId, discountId);
      emit(state.copyWith(clearRedeeming: true));
      await load(userId); // refresh balance + history + ownedCodes
      return true;
    } catch (e) {
      emit(state.copyWith(clearRedeeming: true, errorMessage: e.toString()));
      return false;
    }
  }
}
