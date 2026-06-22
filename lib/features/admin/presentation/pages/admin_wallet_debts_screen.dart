import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/money_utils.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import 'admin_provider_wallet_statement_screen.dart';

/// Admin xem ví ÂM của chủ sân (nợ) + xóa nợ. Thay cho màn ProviderDebt cũ (đã gộp vào ví).
class AdminWalletDebtsScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;
  const AdminWalletDebtsScreen({super.key, required this.datasource});

  @override
  State<AdminWalletDebtsScreen> createState() => _AdminWalletDebtsScreenState();
}

class _AdminWalletDebtsScreenState extends State<AdminWalletDebtsScreen> {
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
      final items = await widget.datasource.getNegativeWallets();
      setState(() { _items = items; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Không tải được danh sách.'; _loading = false; });
    }
  }

  Future<void> _waive(Map<String, dynamic> it) async {
    final pid = it['providerId'] as String;
    setState(() => _busy.add(pid));
    try {
      await widget.datasource.waiveWalletDebt(pid);
      setState(() => _items = _items.where((x) => x['providerId'] != pid).toList());
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
      if (mounted) setState(() => _busy.remove(pid));
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
        title: Text('Nợ chủ sân (ví âm)',
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
          Text('Không có chủ sân nợ ví', style: TextStyle(color: Colors.grey.shade600)),
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
    final pid = it['providerId'] as String;
    final busy = _busy.contains(pid);
    final amount = _amt(it).abs();
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
                child: Text((it['providerName'] as String?) ?? 'Chủ sân',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminProviderWalletStatementScreen(
                      datasource: widget.datasource,
                      providerId: pid,
                      providerName: (it['providerName'] as String?) ?? 'Chủ sân',
                    ),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Sao kê'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Nợ ${formatVnd(amount)}',
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
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Xóa nợ ví?'),
        content: Text('${it['providerName'] ?? "Chủ sân"} — ${formatVnd(_amt(it).abs())}\n'
            'Đưa ví về 0 (chủ sân đã trả ngoài hệ thống / được miễn).'),
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
