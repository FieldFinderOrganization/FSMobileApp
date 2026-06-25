import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/money_utils.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import 'admin_shipper_wallet_statement_screen.dart';

/// Admin xem ví ÂM của shipper (công nợ COD chưa nộp) + xóa nợ. Shipper tự nộp qua PayOS;
/// màn này để đối soát + miễn/đánh dấu đã thu hồi ngoài hệ thống.
class AdminShipperDebtsScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;
  const AdminShipperDebtsScreen({super.key, required this.datasource});

  @override
  State<AdminShipperDebtsScreen> createState() => _AdminShipperDebtsScreenState();
}

class _AdminShipperDebtsScreenState extends State<AdminShipperDebtsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await widget.datasource.getNegativeShipperWallets();
      setState(() { _items = items; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Không tải được danh sách.'; _loading = false; });
    }
  }

  Future<void> _waive(Map<String, dynamic> it) async {
    final sid = it['shipperId'] as String;
    setState(() => _busy.add(sid));
    try {
      await widget.datasource.waiveShipperDebt(sid);
      setState(() => _items = _items.where((x) => x['shipperId'] != sid).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa nợ (ví về 0).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thao tác thất bại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(sid));
    }
  }

  double _amt(Map<String, dynamic> it) {
    final b = it['balance'];
    return (b is num) ? b.toDouble() : double.tryParse(b?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text('Nợ shipper (ví âm)',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black87)),
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
    if (_items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Không có shipper nợ ví', style: TextStyle(color: Colors.grey.shade600)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> it) {
    final sid = it['shipperId'] as String;
    final busy = _busy.contains(sid);
    final amount = _amt(it).abs();
    final name = (it['shipperName'] as String?) ?? 'Shipper';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminShipperWalletStatementScreen(
                      datasource: widget.datasource,
                      shipperId: sid,
                      shipperName: name,
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Sao kê'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Nợ COD ${formatVnd(amount)}',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
          if (it['negativeSince'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Âm từ ${_fmt(it['negativeSince'] as String)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : () => _confirm(it),
              child: busy
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Xóa nợ (đã thu hồi/miễn)'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm(Map<String, dynamic> it) {
    final name = (it['shipperName'] as String?) ?? 'Shipper';
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Xóa nợ ví?'),
        content: Text('$name — ${formatVnd(_amt(it).abs())}\n'
            'Đưa ví về 0 (shipper đã nộp ngoài hệ thống / được miễn).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Hủy')),
          TextButton(
            onPressed: () { Navigator.pop(d); _waive(it); },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _fmt(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}
