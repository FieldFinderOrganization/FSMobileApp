import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/money_utils.dart';
import '../../data/models/refund_request_model.dart';
import '../cubit/refund_cubit.dart';
import '../cubit/refund_state.dart';

/// Lịch sử NHẬN TIỀN của chủ sân: doanh thu booking đã giải ngân + tiền bồi thường khách hủy.
/// Dùng chung RefundCubit/RefundRequestModel (RefundRequest BOOKING_PAYOUT/BOOKING_HOST từ BE).
class ProviderEarningsScreen extends StatefulWidget {
  const ProviderEarningsScreen({super.key});

  @override
  State<ProviderEarningsScreen> createState() => _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends State<ProviderEarningsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RefundCubit>().loadProviderEarnings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nhận tiền'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: BlocBuilder<RefundCubit, RefundState>(
        builder: (ctx, state) {
          if (state.status == RefundListStatus.loading &&
              state.refunds.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == RefundListStatus.failure &&
              state.refunds.isEmpty) {
            return _retry(ctx, state.errorMessage);
          }
          if (state.refunds.isEmpty) {
            return _empty();
          }
          return RefreshIndicator(
            onRefresh: () => ctx.read<RefundCubit>().loadProviderEarnings(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.refunds.length,
              itemBuilder: (_, i) => _earningCard(state.refunds[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Chưa có khoản nhận tiền nào',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Doanh thu sẽ chuyển về TK sau khi trận đá kết thúc',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _retry(BuildContext ctx, String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ctx.read<RefundCubit>().loadProviderEarnings(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );

  Widget _earningCard(RefundRequestModel r) {
    final s = _statusOf(r.status);
    final title = r.sourceType == 'BOOKING_HOST'
        ? 'Bồi thường khách hủy'
        : 'Doanh thu đặt sân';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.color.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(s.icon, size: 13, color: s.color.shade700),
                      const SizedBox(width: 4),
                      Text(s.label,
                          style: TextStyle(
                              color: s.color.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('+ ${formatVnd(r.amount)}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700)),
            const SizedBox(height: 6),
            if (r.maskedAccount != null)
              _line(Icons.account_balance_outlined,
                  'Về TK ${r.maskedAccount}'),
            if (r.status == 'PAYOUT_PENDING' && r.deadlineAt != null)
              _line(Icons.schedule, 'Dự kiến trước ${_fmtDate(r.deadlineAt!)}'),
            if (r.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Tạo lúc ${_fmtDate(r.createdAt!)}',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ),
          ],
        ),
      );

  String _fmtDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  _StatusStyle _statusOf(String status) {
    switch (status) {
      case 'PAYOUT_SUCCEEDED':
        return _StatusStyle('Đã nhận tiền', Colors.green, Icons.check_circle);
      case 'PAYOUT_PROCESSING':
        return _StatusStyle('Đang chuyển về TK', Colors.orange, Icons.sync);
      case 'PAYOUT_PENDING':
        return _StatusStyle('Đang chờ chuyển', Colors.orange, Icons.schedule);
      case 'PAYOUT_FAILED':
        return _StatusStyle('Lỗi, đang xử lý', Colors.red, Icons.error_outline);
      case 'ISSUED':
        return _StatusStyle('Đã cấp (voucher)', Colors.blue, Icons.local_offer);
      default:
        return _StatusStyle('Đang xử lý', Colors.grey, Icons.hourglass_empty);
    }
  }
}

class _StatusStyle {
  final String label;
  final MaterialColor color;
  final IconData icon;
  _StatusStyle(this.label, this.color, this.icon);
}
