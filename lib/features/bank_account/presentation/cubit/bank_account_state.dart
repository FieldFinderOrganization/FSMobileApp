import '../../data/models/bank_account_model.dart';
import '../../data/models/bank_info_model.dart';

enum BankAccountStatus { initial, loading, success, failure }

class BankAccountState {
  final BankAccountStatus status;
  final List<BankAccountModel> accounts;
  final List<BankInfoModel> banks;
  final bool saving;
  final String errorMessage;

  const BankAccountState({
    this.status = BankAccountStatus.initial,
    this.accounts = const [],
    this.banks = const [],
    this.saving = false,
    this.errorMessage = '',
  });

  BankAccountModel? get defaultAccount {
    for (final a in accounts) {
      if (a.isDefault) return a;
    }
    return accounts.isNotEmpty ? accounts.first : null;
  }

  BankAccountState copyWith({
    BankAccountStatus? status,
    List<BankAccountModel>? accounts,
    List<BankInfoModel>? banks,
    bool? saving,
    String? errorMessage,
  }) {
    return BankAccountState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      banks: banks ?? this.banks,
      saving: saving ?? this.saving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
