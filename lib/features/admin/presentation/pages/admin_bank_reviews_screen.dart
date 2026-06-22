import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/datasources/admin_statistics_datasource.dart';

/// Admin duyệt TK ngân hàng có tên lệch hồ sơ (name-match → PENDING_REVIEW).
class AdminBankReviewsScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;
  const AdminBankReviewsScreen({super.key, required this.datasource});

  @override
  State<AdminBankReviewsScreen> createState() => _AdminBankReviewsScreenState();
}

class _AdminBankReviewsScreenState extends State<AdminBankReviewsScreen> {
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
      final items = await widget.datasource.getPendingBankReviews();
      setState(() { _items = items; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Không tải được danh sách.'; _loading = false; });
    }
  }

  Future<void> _act(Map<String, dynamic> it, bool approve) async {
    final id = it['bankAccountId'] as String;
    setState(() => _busy.add(id));
    try {
      await widget.datasource.reviewBankAccount(id, approve);
      setState(() => _items = _items.where((x) => x['bankAccountId'] != id).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Đã duyệt TK.' : 'Đã từ chối TK.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thao tác thất bại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text('Duyệt TK ngân hàng',
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
          Icon(Icons.verified_user_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Không có TK chờ duyệt', style: TextStyle(color: Colors.grey.shade600)),
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
    final id = it['bankAccountId'] as String;
    final busy = _busy.contains(id);
    final bank = (it['bankName'] as String?) ?? '';
    final masked = (it['maskedAccountNumber'] as String?) ?? (it['accountNumber'] as String? ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${it['accountName'] ?? ''}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('$bank $masked'.trim(),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          if (it['reviewNote'] != null) ...[
            const SizedBox(height: 6),
            Text(it['reviewNote'] as String,
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12.5, height: 1.3)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : () => _act(it, false),
                child: const Text('Từ chối'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: busy ? null : () => _act(it, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Duyệt'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
