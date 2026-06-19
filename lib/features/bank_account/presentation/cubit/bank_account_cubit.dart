import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/bank_account_repository.dart';
import 'bank_account_state.dart';

class BankAccountCubit extends Cubit<BankAccountState> {
  final BankAccountRepository _repository;

  BankAccountCubit({required BankAccountRepository repository})
      : _repository = repository,
        super(const BankAccountState());

  /// Nạp danh sách TK + danh sách ngân hàng (cho dropdown).
  Future<void> load() async {
    emit(state.copyWith(status: BankAccountStatus.loading, errorMessage: ''));
    try {
      final accounts = await _repository.list();
      // Danh sách ngân hàng không chặn — lỗi thì để rỗng
      List banks = state.banks;
      if (state.banks.isEmpty) {
        try {
          banks = await _repository.fetchBankList();
        } catch (_) {}
      }
      emit(state.copyWith(
        status: BankAccountStatus.success,
        accounts: accounts,
        banks: banks.cast(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BankAccountStatus.failure,
        errorMessage: _msg(e),
      ));
    }
  }

  /// Thêm / cập nhật TK. Trả về true nếu thành công.
  Future<bool> save({
    required String bankBin,
    String? bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    emit(state.copyWith(saving: true, errorMessage: ''));
    try {
      await _repository.save(
        bankBin: bankBin,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
      );
      final accounts = await _repository.list();
      emit(state.copyWith(saving: false, accounts: accounts));
      return true;
    } catch (e) {
      emit(state.copyWith(saving: false, errorMessage: _msg(e)));
      return false;
    }
  }

  Future<void> setDefault(String bankAccountId) async {
    try {
      await _repository.setDefault(bankAccountId);
      final accounts = await _repository.list();
      emit(state.copyWith(accounts: accounts));
    } catch (e) {
      emit(state.copyWith(errorMessage: _msg(e)));
    }
  }

  Future<void> delete(String bankAccountId) async {
    try {
      await _repository.delete(bankAccountId);
      final accounts = await _repository.list();
      emit(state.copyWith(accounts: accounts));
    } catch (e) {
      emit(state.copyWith(errorMessage: _msg(e)));
    }
  }

  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Lỗi kết nối, vui lòng thử lại.';
    }
    return e.toString();
  }
}
