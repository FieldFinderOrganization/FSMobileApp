import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/money_utils.dart';
import '../../../wallet/data/models/wallet_transaction_model.dart';
import '../../data/datasources/admin_statistics_datasource.dart';

/// Admin xem sao kê ví của 1 shipper (audit / giải thích vì sao ví âm = công nợ COD).
class AdminShipperWalletStatementScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;
  final String shipperId;
  final String shipperName;
  const AdminShipperWalletStatementScreen({
    super.key,
    required this.datasource,
    required this.shipperId,
    required this.shipperName,
  });

  @override
  State<AdminShipperWalletStatementScreen> createState() =>
      _AdminShipperWalletStatementScreenState();
}

class _AdminShipperWalletStatementScreenState
    extends State<AdminShipperWalletStatementScreen> {
  bool _loading = true;
  String? _error;
  List<WalletTransactionModel> _txns = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final txns = await widget.datasource.getShipperWalletTransactions(widget.shipperId);
      setState(() { _txns = txns; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Không tải được sao kê.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text('Sao kê ví — ${widget.shipperName}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 16)),
        backgroundColor: const Color(0xFFF8F9FC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
        ]),
      );
    }
    if (_txns.isEmpty) {
      return Center(
        child: Text('Chưa có giao dịch nào', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _txns.length,
        itemBuilder: (_, i) => _tile(_txns[i]),
      ),
    );
  }

  Widget _tile(WalletTransactionModel t) {
    final credit = t.isCredit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_labelOf(t.type),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
              Text((credit ? '+ ' : '− ') + formatVnd(t.amount.abs()),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: credit ? Colors.green.shade700 : Colors.red.shade700)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Số dư sau: ${formatVnd(t.balanceAfter)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          if (t.reason != null && t.reason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(t.reason!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.3)),
            ),
          if (t.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(_fmt(t.createdAt!),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
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

  String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}
