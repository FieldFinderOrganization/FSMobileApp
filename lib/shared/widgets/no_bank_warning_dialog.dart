import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/dio_client.dart';
import '../../features/bank_account/data/datasources/bank_account_remote_datasource.dart';
import '../../features/bank_account/data/repositories/bank_account_repository_impl.dart';
import '../../features/bank_account/presentation/cubit/bank_account_cubit.dart';
import '../../features/bank_account/presentation/pages/bank_account_screen.dart';

/// Kiểm tra user có TK ngân hàng mặc định chưa, trước khi hủy đơn BANK.
///
/// BE hoàn TIỀN MẶT về TK khi có liên kết ngân hàng (cả hủy hợp lệ lẫn sát giờ);
/// chưa có TK → chỉ nhận mã đền bù. Vì vậy luôn cảnh báo khi chưa có TK ngân hàng.
///
/// Trả về true nếu có TK ngân hàng (hoàn tiền mặt) hoặc user chọn "Tiếp tục"
/// (chấp nhận chỉ nhận mã đền bù). false khi user đóng / đi cập nhật ngân hàng.
Future<bool> confirmCancelWithBankCheck(BuildContext context) async {
  final dio = context.read<DioClient>();
  Object? defaultBank;
  try {
    defaultBank = await BankAccountRepositoryImpl(
      remoteDataSource: BankAccountRemoteDataSource(dioClient: dio),
    ).getDefault();
  } catch (_) {
    defaultBank = null;
  }
  if (!context.mounted) return false;
  if (defaultBank != null) return true; // có bank → hoàn tiền mặt, không cần cảnh báo

  final proceed = await _showNoBankWarning(context);
  return proceed == true;
}

Future<bool?> _showNoBankWarning(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Chưa có tài khoản ngân hàng',
                style:
                    GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
      content: Text(
        'Bạn chưa thêm tài khoản ngân hàng. Nếu tiếp tục hủy, khoản hoàn sẽ '
        'được cấp dưới dạng MÃ ĐỀN BÙ (dùng cho lần đặt sau) thay vì hoàn '
        'tiền mặt về tài khoản.',
        style: GoogleFonts.inter(fontSize: 14, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop(false);
            final dio = context.read<DioClient>();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => BankAccountCubit(
                    repository: BankAccountRepositoryImpl(
                      remoteDataSource:
                          BankAccountRemoteDataSource(dioClient: dio),
                    ),
                  ),
                  child: const BankAccountScreen(),
                ),
              ),
            );
          },
          child: Text('Cập nhật ngân hàng',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Tiếp tục',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
