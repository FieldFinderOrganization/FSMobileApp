import '../../data/models/bank_account_model.dart';
import '../../data/models/bank_info_model.dart';
import '../../data/models/bank_lookup_result.dart';

abstract class BankAccountRepository {
  Future<List<BankAccountModel>> list();
  Future<BankAccountModel?> getDefault();
  Future<BankLookupResult> lookup({
    required String bankBin,
    required String accountNumber,
  });
  Future<BankAccountModel> save({
    required String bankBin,
    String? bankName,
    required String accountNumber,
    required String accountName,
  });
  Future<BankAccountModel> setDefault(String bankAccountId);
  Future<void> delete(String bankAccountId);
  Future<List<BankInfoModel>> fetchBankList();
}
