import '../../../../core/network/dio_client.dart';
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
}
