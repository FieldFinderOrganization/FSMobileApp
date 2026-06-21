import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/wallet_remote_data_source.dart';
import 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final WalletRemoteDataSource _dataSource;

  WalletCubit({required WalletRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const WalletState());

  Future<void> load() async {
    emit(state.copyWith(status: WalletStatus.loading, errorMessage: ''));
    try {
      final wallet = await _dataSource.getWallet();
      final txns = await _dataSource.getTransactions();
      emit(state.copyWith(
        status: WalletStatus.success,
        wallet: wallet,
        transactions: txns,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: WalletStatus.failure,
        errorMessage: 'Không tải được ví.',
      ));
    }
  }
}
