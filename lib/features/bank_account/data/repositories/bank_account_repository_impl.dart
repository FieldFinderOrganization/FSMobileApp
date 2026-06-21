import '../../domain/repositories/bank_account_repository.dart';
import '../datasources/bank_account_remote_datasource.dart';
import '../models/bank_account_model.dart';
import '../models/bank_info_model.dart';
import '../models/bank_lookup_result.dart';

class BankAccountRepositoryImpl implements BankAccountRepository {
  final BankAccountRemoteDataSource remoteDataSource;

  BankAccountRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<BankAccountModel>> list() => remoteDataSource.list();

  @override
  Future<BankAccountModel?> getDefault() => remoteDataSource.getDefault();

  @override
  Future<BankAccountModel> save({
    required String bankBin,
    String? bankName,
    required String accountNumber,
    required String accountName,
    String? pin,
  }) =>
      remoteDataSource.save(
        bankBin: bankBin,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
        pin: pin,
      );

  @override
  Future<BankLookupResult> lookup({
    required String bankBin,
    required String accountNumber,
  }) =>
      remoteDataSource.lookup(
        bankBin: bankBin,
        accountNumber: accountNumber,
      );

  @override
  Future<BankAccountModel> setDefault(String bankAccountId, {String? pin}) =>
      remoteDataSource.setDefault(bankAccountId, pin: pin);

  @override
  Future<void> delete(String bankAccountId) =>
      remoteDataSource.delete(bankAccountId);

  @override
  Future<List<BankInfoModel>> fetchBankList() =>
      remoteDataSource.fetchBankList();
}
