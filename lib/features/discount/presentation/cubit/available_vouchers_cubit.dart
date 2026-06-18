import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../../domain/entities/tier_info_entity.dart';
import '../../domain/repositories/discount_repository.dart';

enum AvailableVouchersStatus { initial, loading, success, failure }

class AvailableVouchersState {
  final AvailableVouchersStatus status;
  final List<AdminDiscountEntity> vouchers; // mã public claimable, chưa có trong ví
  final List<AdminDiscountEntity> redeemable; // mã đổi bằng điểm mà user ĐỦ điểm
  final int balance; // điểm thưởng hiện có
  final String errorMessage;
  final String? savingCode; // code đang lưu (disable nút + spinner)
  final String? redeemingId; // discountId đang đổi điểm (disable nút + spinner)

  const AvailableVouchersState({
    this.status = AvailableVouchersStatus.initial,
    this.vouchers = const [],
    this.redeemable = const [],
    this.balance = 0,
    this.errorMessage = '',
    this.savingCode,
    this.redeemingId,
  });

  AvailableVouchersState copyWith({
    AvailableVouchersStatus? status,
    List<AdminDiscountEntity>? vouchers,
    List<AdminDiscountEntity>? redeemable,
    int? balance,
    String? errorMessage,
    String? savingCode,
    bool clearSaving = false,
    String? redeemingId,
    bool clearRedeeming = false,
  }) {
    return AvailableVouchersState(
      status: status ?? this.status,
      vouchers: vouchers ?? this.vouchers,
      redeemable: redeemable ?? this.redeemable,
      balance: balance ?? this.balance,
      errorMessage: errorMessage ?? this.errorMessage,
      savingCode: clearSaving ? null : (savingCode ?? this.savingCode),
      redeemingId: clearRedeeming ? null : (redeemingId ?? this.redeemingId),
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

      // Số điểm thưởng → biết user đủ điểm đổi mã nào.
      int balance = 0;
      try {
        balance = (await _repository.getPointInfo(userId)).balance;
      } catch (_) {}

      final claimable = all
          .where((d) =>
              d.isClaimable &&
              d.pointCost == null && // mã đổi điểm hiển thị ở section riêng bên dưới
              TierInfoEntity.meetsTier(userTier, d.minTier) &&
              !ownedCodes.contains(d.code))
          .toList()
        ..sort((a, b) => a.endDate.compareTo(b.endDate)); // sắp hết hạn lên trước

      // Mã đổi bằng điểm mà user ĐỦ điểm để đổi ngay tại đây (thay vì phải vào màn Điểm thưởng).
      final redeemable = all
          .where((d) =>
              d.pointCost != null &&
              d.isClaimable &&
              balance >= d.pointCost! &&
              TierInfoEntity.meetsTier(userTier, d.minTier) &&
              !ownedCodes.contains(d.code))
          .toList()
        ..sort((a, b) => (a.pointCost ?? 0).compareTo(b.pointCost ?? 0));

      emit(state.copyWith(
        status: AvailableVouchersStatus.success,
        vouchers: claimable,
        redeemable: redeemable,
        balance: balance,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: AvailableVouchersStatus.failure, errorMessage: e.toString()));
    }
  }

  /// Lưu mã free vào ví; trả về true nếu thành công để UI hiện snackbar.
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

  /// Đổi điểm lấy mã ngay tại màn này; true = thành công (UI hiện snackbar + reload).
  Future<bool> redeem(String userId, String discountId) async {
    if (state.redeemingId != null) return false;
    emit(state.copyWith(redeemingId: discountId));
    try {
      await _repository.redeemVoucher(userId, discountId);
      emit(state.copyWith(clearRedeeming: true));
      await load(userId); // refresh balance + danh sách (mã đã đổi rời khỏi redeemable)
      return true;
    } catch (e) {
      emit(state.copyWith(clearRedeeming: true, errorMessage: e.toString()));
      return false;
    }
  }
}
