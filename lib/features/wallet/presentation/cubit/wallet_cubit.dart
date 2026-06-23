import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/wallet_remote_data_source.dart';
import '../../data/models/wallet_topup_model.dart';
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

  /// Rút tiền. Trả về null nếu thành công, hoặc thông báo lỗi.
  Future<String?> withdraw(double amount, String pin) async {
    try {
      await _dataSource.withdraw(amount, pin);
      await load();
      return null;
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) return data['message'] as String;
      }
      return 'Rút tiền thất bại.';
    }
  }

  /// Tạo lệnh nạp tiền. Trả về (model, null) khi OK, hoặc (null, thông báo lỗi).
  Future<(WalletTopupModel?, String?)> createTopup(double amount) async {
    try {
      final topup = await _dataSource.createTopup(amount);
      return (topup, null);
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          return (null, data['message'] as String);
        }
      }
      return (null, 'Tạo lệnh nạp thất bại.');
    }
  }

  /// Poll trạng thái lệnh nạp. Trả 'CREDITED' khi đã cộng ví.
  Future<String> pollTopupStatus(String topupId) async {
    try {
      return await _dataSource.getTopupStatus(topupId);
    } catch (_) {
      return 'PENDING';
    }
  }
}
