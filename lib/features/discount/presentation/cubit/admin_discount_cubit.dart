import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../../domain/repositories/discount_repository.dart';

enum AdminDiscountStatus { initial, loading, success, failure, actionSuccess }

class AdminDiscountState {
  final AdminDiscountStatus status;
  final List<AdminDiscountEntity> discounts;
  final String errorMessage;
  final String actionMessage;

  const AdminDiscountState({
    this.status = AdminDiscountStatus.initial,
    this.discounts = const [],
    this.errorMessage = '',
    this.actionMessage = '',
  });

  AdminDiscountState copyWith({
    AdminDiscountStatus? status,
    List<AdminDiscountEntity>? discounts,
    String? errorMessage,
    String? actionMessage,
  }) {
    return AdminDiscountState(
      status: status ?? this.status,
      discounts: discounts ?? this.discounts,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}

class AdminDiscountCubit extends Cubit<AdminDiscountState> {
  final DiscountRepository _repository;

  AdminDiscountCubit({required DiscountRepository repository})
      : _repository = repository,
        super(const AdminDiscountState());

  Future<void> loadDiscounts() async {
    emit(state.copyWith(status: AdminDiscountStatus.loading));
    try {
      final list = await _repository.getAllDiscounts();
      emit(state.copyWith(status: AdminDiscountStatus.success, discounts: list));
    } catch (e) {
      emit(state.copyWith(
          status: AdminDiscountStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> createDiscount(Map<String, dynamic> body) async {
    emit(state.copyWith(status: AdminDiscountStatus.loading));
    try {
      await _repository.createDiscount(body);
      await loadDiscounts();
      emit(state.copyWith(
          status: AdminDiscountStatus.actionSuccess,
          actionMessage: 'Tạo mã thành công'));
    } catch (e) {
      emit(state.copyWith(
          status: AdminDiscountStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> updateDiscount(String id, Map<String, dynamic> body) async {
    emit(state.copyWith(status: AdminDiscountStatus.loading));
    try {
      await _repository.updateDiscount(id, body);
      await loadDiscounts();
      emit(state.copyWith(
          status: AdminDiscountStatus.actionSuccess,
          actionMessage: 'Cập nhật thành công'));
    } catch (e) {
      emit(state.copyWith(
          status: AdminDiscountStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> toggleStatus(String id, bool currentlyActive) async {
    final newStatus = currentlyActive ? 'INACTIVE' : 'ACTIVE';
    try {
      final updated = await _repository.toggleStatus(id, newStatus);
      final updatedList = state.discounts
          .map((d) => d.id == updated.id ? updated : d)
          .toList();
      emit(state.copyWith(
          status: AdminDiscountStatus.success, discounts: updatedList));
    } catch (e) {
      emit(state.copyWith(
          status: AdminDiscountStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> assignToUsers(String id, List<String> userIds) async {
    emit(state.copyWith(status: AdminDiscountStatus.loading));
    try {
      await _repository.assignToUsers(id, userIds);
      emit(state.copyWith(
          status: AdminDiscountStatus.actionSuccess,
          actionMessage: 'Đã gán mã cho ${userIds.length} người dùng'));
    } catch (e) {
      emit(state.copyWith(
          status: AdminDiscountStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> deleteDiscount(String id) async {
    emit(state.copyWith(status: AdminDiscountStatus.loading));
    try {
      await _repository.deleteDiscount(id);
      final updated = state.discounts.where((d) => d.id != id).toList();
      emit(state.copyWith(
          status: AdminDiscountStatus.success, discounts: updated));
    } catch (e) {
      emit(state.copyWith(
          status: AdminDiscountStatus.failure, errorMessage: e.toString()));
    }
  }
}
