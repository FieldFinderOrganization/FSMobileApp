import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../payment_pin/presentation/payment_pin.dart';
import '../../../wallet/data/models/wallet_transaction_model.dart';
import '../../../wallet/data/models/wallet_view_model.dart';
import '../../data/models/shipper_cod_remit_model.dart';
import '../../data/shipper_remote_data_source.dart';
import 'shipper_cod_remit_screen.dart';

/// Ví shipper: số dư rút được (thu nhập ship), công nợ COD (số dư âm = tiền hàng thu hộ
/// chưa nộp), nút tự rút về TK ngân hàng (gác PIN), sao kê. Mirror ví chủ sân.
class ShipperWalletScreen extends StatefulWidget {
  const ShipperWalletScreen({super.key});

  @override
  State<ShipperWalletScreen> createState() => _ShipperWalletScreenState();
}

class _ShipperWalletScreenState extends State<ShipperWalletScreen> {
  late final ShipperRemoteDataSource _ds;

  WalletViewModel? _wallet;
  List<WalletTransactionModel> _txns = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Future.wait([_ds.getWallet(), _ds.getWalletTransactions()]);
      if (!mounted) return;
      setState(() {
        _wallet = res[0] as WalletViewModel;
        _txns = res[1] as List<WalletTransactionModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = messageFromError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Đổi mã PIN',
            icon: const Icon(Icons.lock_outline, size: 20),
            onPressed: () => changePaymentPin(context),
          ),
        ],
      ),
      body: _loading && _wallet == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _wallet == null
              ? _retry(_error!)
              : _body(),
    );
  }

  Widget _body() {
    final w = _wallet!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _balanceCard(w),
          const SizedBox(height: 12),
          _withdrawSection(w),
          if (w.isNegative) ...[
            const SizedBox(height: 10),
            _remitButton(w),
          ],
          const SizedBox(height: 12),
          if (w.isNegative || w.blocked) _warningBanner(w),
          _infoNote(),
          const SizedBox(height: 16),
          const Text('Sao kê',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          if (_txns.isEmpty) _empty() else ..._txns.map(_txnTile),
        ],
      ),
    );
  }

  Widget _balanceCard(WalletViewModel w) {
    final negative = w.isNegative;
    final codDebt = negative ? w.balance.abs() : 0.0;
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
          Text(negative ? 'Số dư ví (đang nợ COD)' : 'Số dư ví',
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
              Expanded(child: _miniStat('Công nợ COD', formatVnd(codDebt))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _withdrawSection(WalletViewModel w) {
    final minStr = formatVnd(w.minWithdraw);
    final canWithdraw = w.withdrawable >= w.minWithdraw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canWithdraw ? () => _onWithdraw(w) : null,
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
            label: Text(canWithdraw
                ? 'Rút về TK (tối đa ${formatVnd(w.withdrawable)})'
                : 'Rút về TK'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          canWithdraw
              ? 'Rút tối thiểu $minStr / lệnh.'
              : 'Cần rút được ≥ $minStr mới rút được (hiện ${formatVnd(w.withdrawable)}). '
                  'Tiền cũng tự chuyển khi đủ điều kiện.',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
        ),
      ],
    );
  }

  Future<void> _onWithdraw(WalletViewModel w) async {
    final amount = await _askAmount(w.withdrawable, w.minWithdraw);
    if (amount == null || !mounted) return;
    final pin = await ensurePaymentPin(context); // gác bằng PIN
    if (pin == null || !mounted) return;
    String? err;
    try {
      await _ds.withdraw(amount, pin);
    } catch (e) {
      err = messageFromError(e);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Đã gửi lệnh rút — tiền sẽ về TK trong ít phút.'),
      backgroundColor: err == null ? Colors.green : Colors.red,
    ));
    if (err == null) _load();
  }

  Future<double?> _askAmount(double max, double min) {
    final minStr = formatVnd(min);
    final c = TextEditingController(text: max.toStringAsFixed(0));
    return showDialog<double>(
      context: context,
      builder: (d) {
        String? error;
        return StatefulBuilder(
          builder: (d, setState) => AlertDialog(
            title: const Text('Rút tiền'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Rút tối thiểu $minStr — tối đa ${formatVnd(max)}'),
              const SizedBox(height: 10),
              TextField(
                controller: c,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Số tiền', border: OutlineInputBorder()),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(c.text) ?? 0;
                  if (v < min || v > max) {
                    setState(() =>
                        error = 'Số tiền phải từ $minStr đến ${formatVnd(max)}.');
                    return;
                  }
                  Navigator.pop(d, v);
                },
                child: const Text('Rút'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _remitButton(WalletViewModel w) {
    final debt = w.balance.abs();
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _onRemit(debt),
        icon: const Icon(Icons.upload_outlined, size: 18),
        label: Text('Nộp tiền COD (nợ ${formatVnd(debt)})'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          foregroundColor: Colors.orange.shade800,
          side: BorderSide(color: Colors.orange.shade700),
        ),
      ),
    );
  }

  Future<void> _onRemit(double debt) async {
    final amount = await _askRemitAmount(debt);
    if (amount == null || !mounted) return;
    ShipperCodRemitModel remit;
    try {
      remit = await _ds.createCodRemit(amount);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(messageFromError(e)), backgroundColor: Colors.red));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShipperCodRemitScreen(
        remit: remit, ds: _ds, onCredited: _load),
    ));
  }

  Future<double?> _askRemitAmount(double debt) {
    const minRemit = 10000.0;
    final c = TextEditingController(text: debt.toStringAsFixed(0));
    return showDialog<double>(
      context: context,
      builder: (d) {
        String? error;
        return StatefulBuilder(
          builder: (d, setState) => AlertDialog(
            title: const Text('Nộp tiền COD'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Nộp tối thiểu ${formatVnd(minRemit)} — tối đa công nợ ${formatVnd(debt)}.'),
              const SizedBox(height: 10),
              TextField(
                controller: c,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Số tiền', border: OutlineInputBorder()),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(c.text) ?? 0;
                  if (v < minRemit || v > debt) {
                    setState(() => error =
                        'Số tiền phải từ ${formatVnd(minRemit)} đến ${formatVnd(debt)}.');
                    return;
                  }
                  Navigator.pop(d, v);
                },
                child: const Text('Nộp'),
              ),
            ],
          ),
        );
      },
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
        ? 'Đang nợ tiền COD quá hạn — bạn BỊ CHẶN nhận đơn mới. Nộp lại tiền hàng thu hộ để mở khóa.'
        : 'Ví đang nợ tiền hàng thu hộ (COD)'
            '${deadline != null ? '. Quá hạn ${_fmtDate(deadline)} mà chưa nộp sẽ bị chặn nhận đơn' : ''}.';
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
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 15, color: Colors.blueGrey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phí ship đơn đã giao được cộng vào ví và tự chuyển về TK khi đủ điều kiện. '
                'Đơn COD: tiền hàng bạn thu hộ ghi nợ, nộp lại để xóa nợ.',
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
      case 'SHIP_EARNING':
        return 'Thu nhập ship';
      case 'COD_COLLECTED':
        return 'Tiền hàng thu hộ (COD)';
      case 'COD_REMIT':
        return 'Nộp lại tiền COD';
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
      case 'SHIP_EARNING':
        return Icons.local_shipping_outlined;
      case 'COD_COLLECTED':
        return Icons.payments_outlined;
      case 'COD_REMIT':
        return Icons.upload_outlined;
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

  Widget _retry(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
}
