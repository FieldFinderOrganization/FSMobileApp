import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../../bank_account/data/datasources/bank_account_remote_datasource.dart';
import '../../../bank_account/data/repositories/bank_account_repository_impl.dart';
import '../../../bank_account/presentation/cubit/bank_account_cubit.dart';
import '../../../bank_account/presentation/pages/bank_account_screen.dart';

/// Tab "Thông tin" của Quản lý Đối tác = quản lý TK ngân hàng nhận tiền của chủ sân.
/// Dùng chung entity BankAccount (key theo userId) với màn Tài khoản ngân hàng ở profile —
/// nguồn DUY NHẤT cho cả hiển thị lúc thu tiền lẫn payout. Đã bỏ field text rời provider.bank/cardNumber.
class ProviderInfoTab extends StatelessWidget {
  final UserEntity user;

  const ProviderInfoTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final dio = context.read<DioClient>();
    return BlocProvider(
      create: (_) => BankAccountCubit(
        repository: BankAccountRepositoryImpl(
          remoteDataSource: BankAccountRemoteDataSource(dioClient: dio),
        ),
      ),
      child: const BankAccountScreen(embedded: true),
    );
  }
}
