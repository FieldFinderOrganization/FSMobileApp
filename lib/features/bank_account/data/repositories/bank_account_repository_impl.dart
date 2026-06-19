import '../../domain/repositories/bank_account_repository.dart';
import '../datasources/bank_account_remote_datasource.dart';
import '../models/bank_account_model.dart';
import '../models/bank_info_model.dart';

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
  }) =>
      remoteDataSource.save(
        bankBin: bankBin,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
      );

  @override
  Future<BankAccountModel> setDefault(String bankAccountId) =>
      remoteDataSource.setDefault(bankAccountId);

  @override
  Future<void> delete(String bankAccountId) =>
      remoteDataSource.delete(bankAccountId);

  @override
  Future<List<BankInfoModel>> fetchBankList() =>
      remoteDataSource.fetchBankList();
}
