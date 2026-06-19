import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/money_utils.dart';
import '../../data/models/refund_request_model.dart';
import '../cubit/refund_cubit.dart';
import '../cubit/refund_state.dart';

class RefundHistoryScreen extends StatefulWidget {
  const RefundHistoryScreen({super.key});

  @override
  State<RefundHistoryScreen> createState() => _RefundHistoryScreenState();
}

class _RefundHistoryScreenState extends State<RefundHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RefundCubit>().loadMine();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoàn tiền'),
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
            onRefresh: () => ctx.read<RefundCubit>().loadMine(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.refunds.length,
              itemBuilder: (_, i) => _refundCard(ctx, state.refunds[i]),
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
            Icon(Icons.receipt_long_outlined,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Chưa có khoản hoàn tiền nào',
                style: TextStyle(color: Colors.grey.shade600)),
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
              onPressed: () => ctx.read<RefundCubit>().loadMine(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );

  Widget _refundCard(BuildContext ctx, RefundRequestModel r) {
    final s = _statusOf(r.status);
    final sourceLabel = r.sourceType == 'ORDER' ? 'Đơn hàng' : 'Đặt sân';
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
                  child: Text('Hoàn tiền $sourceLabel',
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
            Text(formatVnd(r.amount),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (r.isCash && r.maskedAccount != null)
              _line(Icons.account_balance_outlined,
                  'Chuyển về TK ${r.maskedAccount}'),
            if (!r.isCash && r.refundCode != null)
              _voucherCode(ctx, r),
            if (r.reason != null && r.reason!.isNotEmpty)
              _line(Icons.info_outline, r.reason!),
            if (r.status == 'PAYOUT_PENDING' && r.deadlineAt != null)
              _line(Icons.schedule,
                  'Sẽ hoàn trước ${_fmtDate(r.deadlineAt!)}'),
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

  Widget _voucherCode(BuildContext ctx, RefundRequestModel r) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: r.refundCode!));
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Đã copy mã hoàn tiền.')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 15),
              const SizedBox(width: 6),
              Text(r.refundCode!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
              const Spacer(),
              Icon(Icons.copy, size: 14, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  _StatusStyle _statusOf(String status) {
    switch (status) {
      case 'PAYOUT_SUCCEEDED':
        return _StatusStyle('Đã hoàn tiền', Colors.green, Icons.check_circle);
      case 'PAYOUT_PROCESSING':
        return _StatusStyle('Đang chuyển khoản', Colors.orange, Icons.sync);
      case 'PAYOUT_PENDING':
        return _StatusStyle('Đang chờ chuyển', Colors.orange, Icons.schedule);
      case 'PAYOUT_FAILED':
        return _StatusStyle('Lỗi, đang xử lý', Colors.red, Icons.error_outline);
      case 'ISSUED':
        return _StatusStyle('Đã cấp mã', Colors.blue, Icons.local_offer);
      case 'REJECTED':
        return _StatusStyle('Bị từ chối', Colors.grey, Icons.block);
      case 'FAILED':
        return _StatusStyle('Thất bại', Colors.red, Icons.error_outline);
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
