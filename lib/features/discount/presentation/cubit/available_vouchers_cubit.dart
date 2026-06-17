import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../../domain/entities/tier_info_entity.dart';
import '../../domain/repositories/discount_repository.dart';

enum AvailableVouchersStatus { initial, loading, success, failure }

class AvailableVouchersState {
  final AvailableVouchersStatus status;
  final List<AdminDiscountEntity> vouchers; // mã public claimable, chưa có trong ví
  final String errorMessage;
  final String? savingCode; // code đang lưu (disable nút + spinner)

  const AvailableVouchersState({
    this.status = AvailableVouchersStatus.initial,
    this.vouchers = const [],
    this.errorMessage = '',
    this.savingCode,
  });

  AvailableVouchersState copyWith({
    AvailableVouchersStatus? status,
    List<AdminDiscountEntity>? vouchers,
    String? errorMessage,
    String? savingCode,
    bool clearSaving = false,
  }) {
    return AvailableVouchersState(
      status: status ?? this.status,
      vouchers: vouchers ?? this.vouchers,
      errorMessage: errorMessage ?? this.errorMessage,
      savingCode: clearSaving ? null : (savingCode ?? this.savingCode),
    );
  }
}

class AvailableVouchersCubit extends Cubit<AvailableVouchersState> {
  final DiscountRepository _repository;

  AvailableVouchersCubit({required DiscountRepository repository})
      : _repository = repository,
        super(const AvailableVouchersState());

  Future<void> load(String userId) async {
    emit(state.copyWith(status: AvailableVouchersStatus.loading));
    try {
      final all = await _repository.getAllDiscounts();
      final wallet = await _repository.getWallet(userId);
      final ownedCodes =
          wallet.map((w) => w.discountCode).toSet(); // loại mã đã có trong ví

      // Hạng user → ẩn mã gắn hạng cao hơn (BE chặn khi lưu → tránh hiển thị mã không claim được).
      String userTier = 'MEMBER';
      try {
        userTier = (await _repository.getTierInfo(userId)).tier;
      } catch (_) {}

      final claimable = all
          .where((d) =>
              d.isClaimable &&
              d.pointCost == null && // mã đổi điểm nằm ở màn Đổi quà, không lưu free
              TierInfoEntity.meetsTier(userTier, d.minTier) &&
              !ownedCodes.contains(d.code))
          .toList()
        ..sort((a, b) => a.endDate.compareTo(b.endDate)); // sắp hết hạn lên trước

      emit(state.copyWith(
        status: AvailableVouchersStatus.success,
        vouchers: claimable,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: AvailableVouchersStatus.failure, errorMessage: e.toString()));
    }
  }

  /// Lưu mã vào ví; trả về true nếu thành công để UI hiện snackbar.
  Future<bool> save(String userId, String code) async {
    if (state.savingCode != null) return false;
    emit(state.copyWith(savingCode: code));
    try {
      await _repository.saveToWallet(userId, code);
      // Bỏ mã vừa lưu khỏi danh sách claimable.
      final remaining =
          state.vouchers.where((d) => d.code != code).toList();
      emit(state.copyWith(vouchers: remaining, clearSaving: true));
      return true;
    } catch (e) {
      emit(state.copyWith(
          clearSaving: true, errorMessage: e.toString()));
      return false;
    }
  }
}
