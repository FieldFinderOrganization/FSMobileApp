import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/money_utils.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/provider_debt_model.dart';

class AdminProviderDebtsScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;
  const AdminProviderDebtsScreen({super.key, required this.datasource});

  @override
  State<AdminProviderDebtsScreen> createState() =>
      _AdminProviderDebtsScreenState();
}

class _AdminProviderDebtsScreenState extends State<AdminProviderDebtsScreen> {
  bool _loading = true;
  String? _error;
  List<ProviderDebtModel> _debts = const [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final debts = await widget.datasource.getProviderDebts();
      setState(() {
        _debts = debts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không tải được danh sách nợ.';
        _loading = false;
      });
    }
  }

  Future<void> _act(ProviderDebtModel d, bool settle) async {
    setState(() => _busy.add(d.providerDebtId));
    try {
      if (settle) {
        await widget.datasource.settleProviderDebt(d.providerDebtId);
      } else {
        await widget.datasource.waiveProviderDebt(d.providerDebtId);
      }
      setState(() => _debts =
          _debts.where((x) => x.providerDebtId != d.providerDebtId).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(settle ? 'Đã thu hồi nợ.' : 'Đã miễn nợ.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thao tác thất bại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(d.providerDebtId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text('Nợ chủ sân',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: Colors.black87)),
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
    if (_debts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Không có khoản nợ chưa trả',
              style: TextStyle(color: Colors.grey.shade600)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _debts.length,
        itemBuilder: (_, i) => _card(_debts[i]),
      ),
    );
  }

  Widget _card(ProviderDebtModel d) {
    final busy = _busy.contains(d.providerDebtId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: d.overdue ? Colors.red.shade300 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.providerName ?? 'Chủ sân',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              if (d.overdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Quá hạn',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(formatVnd(d.amount),
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Booking: ${d.sourceBookingId}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          if (d.deadlineAt != null)
            Text('Hạn trả: ${_fmt(d.deadlineAt!)}',
                style: TextStyle(
                    color: d.overdue ? Colors.red : Colors.grey.shade600,
                    fontSize: 12)),
          if (d.reason != null && d.reason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(d.reason!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _confirm(d, false),
                  child: const Text('Miễn nợ'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : () => _confirm(d, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Đã thu hồi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirm(ProviderDebtModel d, bool settle) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(settle ? 'Xác nhận thu hồi nợ?' : 'Miễn khoản nợ?'),
        content: Text(
            '${d.providerName ?? "Chủ sân"} - ${formatVnd(d.amount)}\n'
            '${settle ? "Đánh dấu đã thu hồi (chủ sân đã trả)." : "Miễn khoản nợ này."}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              _act(d, settle);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }
}
