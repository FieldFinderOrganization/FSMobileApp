import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/refund_remote_data_source.dart';
import 'refund_state.dart';

class RefundCubit extends Cubit<RefundState> {
  final RefundRemoteDataSource _dataSource;

  RefundCubit({required RefundRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const RefundState());

  Future<void> loadMine() async {
    emit(state.copyWith(status: RefundListStatus.loading, errorMessage: ''));
    try {
      final refunds = await _dataSource.getMine();
      emit(state.copyWith(
        status: RefundListStatus.success,
        refunds: refunds,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RefundListStatus.failure,
        errorMessage: 'Không tải được lịch sử hoàn tiền.',
      ));
    }
  }

  /// Lịch sử nhận tiền của chủ sân (doanh thu booking + bồi thường).
  Future<void> loadProviderEarnings() async {
    emit(state.copyWith(status: RefundListStatus.loading, errorMessage: ''));
    try {
      final earnings = await _dataSource.getProviderEarnings();
      emit(state.copyWith(
        status: RefundListStatus.success,
        refunds: earnings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: RefundListStatus.failure,
        errorMessage: 'Không tải được lịch sử nhận tiền.',
      ));
    }
  }
}
