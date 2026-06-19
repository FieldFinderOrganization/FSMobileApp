import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/bank_account_model.dart';
import '../models/bank_info_model.dart';

class BankAccountRemoteDataSource {
  final DioClient dioClient;

  const BankAccountRemoteDataSource({required this.dioClient});

  /// TK ngân hàng của user (mới nhất trước).
  Future<List<BankAccountModel>> list() async {
    final res = await dioClient.dio.get('/bank-accounts');
    final data = res.data as List<dynamic>;
    return data
        .map((e) => BankAccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// TK mặc định nhận hoàn tiền; null nếu chưa đăng ký.
  Future<BankAccountModel?> getDefault() async {
    final res = await dioClient.dio.get('/bank-accounts/default');
    final data = res.data;
    if (data is Map<String, dynamic> && data['hasAccount'] == false) return null;
    return BankAccountModel.fromJson(data as Map<String, dynamic>);
  }

  /// Thêm/cập nhật TK (TK mới thành mặc định).
  Future<BankAccountModel> save({
    required String bankBin,
    String? bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final res = await dioClient.dio.post('/bank-accounts', data: {
      'bankBin': bankBin,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
    });
    return BankAccountModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<BankAccountModel> setDefault(String bankAccountId) async {
    final res =
        await dioClient.dio.put('/bank-accounts/$bankAccountId/default');
    return BankAccountModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String bankAccountId) async {
    await dioClient.dio.delete('/bank-accounts/$bankAccountId');
  }

  /// Danh sách ngân hàng VietQR (public, không cần auth). Dùng Dio riêng.
  Future<List<BankInfoModel>> fetchBankList() async {
    final plain = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    final res = await plain.get('https://api.vietqr.io/v2/banks');
    final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((e) => BankInfoModel.fromJson(e as Map<String, dynamic>))
        .where((b) => b.bin.isNotEmpty)
        .toList();
  }
}
