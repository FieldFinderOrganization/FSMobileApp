import '../../data/models/wallet_transaction_model.dart';
import '../../data/models/wallet_view_model.dart';

enum WalletStatus { initial, loading, success, failure }

class WalletState {
  final WalletStatus status;
  final WalletViewModel? wallet;
  final List<WalletTransactionModel> transactions;
  final String errorMessage;

  const WalletState({
    this.status = WalletStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.errorMessage = '',
  });

  WalletState copyWith({
    WalletStatus? status,
    WalletViewModel? wallet,
    List<WalletTransactionModel>? transactions,
    String? errorMessage,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
