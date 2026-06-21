import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/money_utils.dart';
import '../../data/models/wallet_transaction_model.dart';
import '../../data/models/wallet_view_model.dart';
import '../cubit/wallet_cubit.dart';
import '../cubit/wallet_state.dart';

/// Ví chủ sân: số dư, rút được, reserve, cảnh báo khi âm, sao kê giao dịch.
class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (ctx, state) {
          if (state.status == WalletStatus.loading && state.wallet == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == WalletStatus.failure && state.wallet == null) {
            return _retry(ctx, state.errorMessage);
          }
          final w = state.wallet;
          if (w == null) return const SizedBox.shrink();
          return RefreshIndicator(
            onRefresh: () => ctx.read<WalletCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _balanceCard(w),
                const SizedBox(height: 12),
                if (w.isNegative || w.blocked) _warningBanner(w),
                _infoNote(),
                const SizedBox(height: 16),
                const Text('Sao kê',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                if (state.transactions.isEmpty)
                  _empty()
                else
                  ...state.transactions.map(_txnTile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _balanceCard(WalletViewModel w) {
    final negative = w.isNegative;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: negative
              ? [Colors.red.shade400, Colors.red.shade700]
              : [Colors.green.shade400, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(negative ? 'Số dư ví (đang nợ)' : 'Số dư ví',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            (negative ? '− ' : '') + formatVnd(w.balance.abs()),
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniStat('Rút được', formatVnd(w.withdrawable))),
              Container(width: 1, height: 28, color: Colors.white24),
              Expanded(child: _miniStat('Đang giữ (reserve)', formatVnd(w.reserve))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _warningBanner(WalletViewModel w) {
    final deadline = w.blockDeadline;
    final msg = w.blocked
        ? 'Ví đang âm quá hạn — sân của bạn đang BỊ CHẶN nhận booking. Doanh thu đơn tới sẽ tự bù nợ.'
        : 'Ví đang âm. Sẽ tự bù từ doanh thu các đơn tới'
            '${deadline != null ? '. Quá hạn ${_fmtDate(deadline)} mà chưa bù sẽ bị chặn nhận booking' : ''}.';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (w.blocked ? Colors.red : Colors.orange).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: (w.blocked ? Colors.red : Colors.orange).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(w.blocked ? Icons.block : Icons.warning_amber_rounded,
              size: 18, color: w.blocked ? Colors.red.shade700 : Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: w.blocked ? Colors.red.shade900 : Colors.orange.shade900)),
          ),
        ],
      ),
    );
  }

  Widget _infoNote() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 15, color: Colors.blueGrey),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Doanh thu tự chuyển về TK ngân hàng khi đủ điều kiện; phần "đang giữ" là đệm cho phí hủy đơn.',
                style: TextStyle(fontSize: 11.5, color: Colors.blueGrey, height: 1.4),
              ),
            ),
          ],
        ),
      );

  Widget _txnTile(WalletTransactionModel t) {
    final credit = t.isCredit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (credit ? Colors.green : Colors.orange).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconOf(t.type), size: 18,
                color: credit ? Colors.green.shade700 : Colors.orange.shade800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelOf(t.type),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (t.maskedAccount != null) 'TK ${t.maskedAccount}',
                    if (t.createdAt != null) _fmtDate(t.createdAt!),
                  ].join(' · '),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                (credit ? '+ ' : '− ') + formatVnd(t.amount.abs()),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: credit ? Colors.green.shade700 : Colors.orange.shade800),
              ),
              if (_statusLabel(t) != null)
                Text(_statusLabel(t)!,
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  String _labelOf(String type) {
    switch (type) {
      case 'BOOKING_REVENUE':
        return 'Doanh thu đặt sân';
      case 'CANCEL_PENALTY':
        return 'Phí hủy đơn';
      case 'HOST_COMPENSATION':
        return 'Bồi thường khách hủy';
      case 'WITHDRAWAL':
        return 'Rút về tài khoản';
      case 'ADJUSTMENT':
        return 'Điều chỉnh';
      default:
        return type;
    }
  }

  IconData _iconOf(String type) {
    switch (type) {
      case 'BOOKING_REVENUE':
        return Icons.sports_soccer;
      case 'CANCEL_PENALTY':
        return Icons.remove_circle_outline;
      case 'HOST_COMPENSATION':
        return Icons.volunteer_activism_outlined;
      case 'WITHDRAWAL':
        return Icons.account_balance_outlined;
      default:
        return Icons.tune;
    }
  }

  String? _statusLabel(WalletTransactionModel t) {
    if (t.type != 'WITHDRAWAL') return null;
    switch (t.status) {
      case 'SUCCEEDED':
        return 'Đã chuyển';
      case 'PROCESSING':
        return 'Đang chuyển';
      case 'PENDING':
        return 'Đang chờ';
      case 'FAILED':
        return 'Thất bại';
      default:
        return null;
    }
  }

  String _fmtDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Text('Chưa có giao dịch nào',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      );

  Widget _retry(BuildContext ctx, String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ctx.read<WalletCubit>().load(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
}
