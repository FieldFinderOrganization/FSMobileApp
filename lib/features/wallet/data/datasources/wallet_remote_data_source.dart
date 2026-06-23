import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/wallet_topup_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/wallet_view_model.dart';

class WalletRemoteDataSource {
  final DioClient dioClient;

  const WalletRemoteDataSource({required this.dioClient});

  Future<WalletViewModel> getWallet() async {
    final res = await dioClient.dio.get('/providers/wallet');
    return WalletViewModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<WalletTransactionModel>> getTransactions() async {
    final res = await dioClient.dio.get('/providers/wallet/transactions');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Chủ sân tự rút tiền về TK (gác bằng PIN).
  Future<void> withdraw(double amount, String pin) async {
    await dioClient.dio.post('/providers/wallet/withdraw',
        data: {'amount': amount},
        options: Options(headers: {'X-Payment-Pin': pin}));
  }

  /// Tạo lệnh NẠP tiền vào ví → trả link/QR PayOS.
  Future<WalletTopupModel> createTopup(double amount) async {
    final res = await dioClient.dio.post('/providers/wallet/topup',
        data: {'amount': amount});
    return WalletTopupModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Poll trạng thái 1 lệnh nạp: CREDITED | PENDING.
  Future<String> getTopupStatus(String topupId) async {
    final res = await dioClient.dio.get('/providers/wallet/topup/$topupId/status');
    final data = res.data as Map<String, dynamic>;
    return (data['status'] as String?) ?? 'PENDING';
  }
}
