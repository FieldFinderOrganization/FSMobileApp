import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/admin_statistics_datasource.dart';

/// Kiểm duyệt thủ công đánh giá (bước 2 sau kiểm duyệt tự động).
/// Tab: Sản phẩm / Sân. Lọc theo trạng thái: Chờ duyệt / Bị từ chối / Đã duyệt.
class AdminReviewModerationScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminReviewModerationScreen({super.key, required this.datasource});

  @override
  State<AdminReviewModerationScreen> createState() =>
      _AdminReviewModerationScreenState();
}

class _ModerationItem {
  final String id;
  final String title; // tên sản phẩm / sân
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String status;
  final String? reason;
  final bool isProduct;

  _ModerationItem({
    required this.id,
    required this.title,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.status,
    required this.reason,
    required this.isProduct,
  });
}

class _AdminReviewModerationScreenState
    extends State<AdminReviewModerationScreen>
    with SingleTickerProviderStateMixin {
  static const _kPrimary = Color(0xFF4454A0);
  static const _kGreen = Color(0xFF0D9988);
  static const _kRed = Color(0xFFEF4444);
  static const _kAmber = Color(0xFFF59E0B);

  // Trạng thái lọc: PENDING | REJECTED | APPROVED
  static const _statuses = ['PENDING', 'REJECTED', 'APPROVED'];
  static const _statusLabels = ['Chờ duyệt', 'Bị từ chối', 'Đã duyệt'];

  late final TabController _tab;
  int _statusIndex = 0;

  bool _loading = true;
  String? _error;
  List<_ModerationItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) _load();
      });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  bool get _isProductTab => _tab.index == 0;
  String get _status => _statuses[_statusIndex];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<_ModerationItem> items;
      if (_isProductTab) {
        final list =
            await widget.datasource.getProductReviewsForModeration(_status);
        items = list
            .map((r) => _ModerationItem(
                  id: r.reviewId,
                  title: r.productName ?? 'Sản phẩm',
                  userName: r.userName,
                  rating: r.rating,
                  comment: r.comment,
                  createdAt: r.createdAt,
                  status: r.status ?? _status,
                  reason: r.moderationReason,
                  isProduct: true,
                ))
            .toList();
      } else {
        final list =
            await widget.datasource.getPitchReviewsForModeration(_status);
        items = list
            .map((r) => _ModerationItem(
                  id: r.reviewId,
                  title: r.pitchName ?? 'Sân',
                  userName: r.userName,
                  rating: r.rating,
                  comment: r.comment,
                  createdAt: r.createdAt,
                  status: r.status ?? _status,
                  reason: r.moderationReason,
                  isProduct: false,
                ))
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách. Vui lòng thử lại.';
        _loading = false;
      });
    }
  }

  Future<void> _approve(_ModerationItem item) async {
    try {
      if (item.isProduct) {
        await widget.datasource.approveProductReview(item.id);
      } else {
        await widget.datasource.approvePitchReview(item.id);
      }
      _toast('Đã duyệt đánh giá', _kGreen);
      _load();
    } catch (_) {
      _toast('Thao tác thất bại', _kRed);
    }
  }

  Future<void> _reject(_ModerationItem item) async {
    final reason = await _askReason();
    if (reason == null) return; // huỷ
    try {
      if (item.isProduct) {
        await widget.datasource.rejectProductReview(item.id, reason: reason);
      } else {
        await widget.datasource.rejectPitchReview(item.id, reason: reason);
      }
      _toast('Đã từ chối đánh giá', _kRed);
      _load();
    } catch (_) {
      _toast('Thao tác thất bại', _kRed);
    }
  }

  Future<String?> _askReason() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Từ chối đánh giá',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 200,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Lý do từ chối (tuỳ chọn)…',
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huỷ', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Từ chối',
                style: GoogleFonts.inter(
                    color: _kRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _toast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text('Kiểm duyệt đánh giá',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 19, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tab,
          labelColor: _kPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _kPrimary,
          labelStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'Sản phẩm'), Tab(text: 'Sân bóng')],
        ),
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: List.generate(_statuses.length, (i) {
          final selected = i == _statusIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_statusLabels[i]),
              selected: selected,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54,
              ),
              selectedColor: _kPrimary,
              backgroundColor: const Color(0xFFEFF1F6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none),
              showCheckmark: false,
              onSelected: (_) {
                if (_statusIndex == i) return;
                setState(() => _statusIndex = i);
                _load();
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _kRed, size: 44),
            const SizedBox(height: 10),
            Text(_error!, style: GoogleFonts.inter(color: Colors.black54)),
            const SizedBox(height: 10),
            TextButton(
                onPressed: _load,
                child: Text('Thử lại',
                    style: GoogleFonts.inter(
                        color: _kPrimary, fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('Không có đánh giá ở mục này',
                style: GoogleFonts.inter(color: Colors.black45)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _items.length,
        itemBuilder: (_, i) => _buildCard(_items[i]),
      ),
    );
  }

  Widget _buildCard(_ModerationItem item) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt);
    final canApprove = item.status != 'APPROVED';
    final canReject = item.status != 'REJECTED';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.title,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
              ),
              _statusChip(item.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('bởi ${item.userName} · $dateStr',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return Icon(
                star <= item.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 17,
                color: star <= item.rating
                    ? const Color(0xFFFFC107)
                    : const Color(0xFFCCCCCC),
              );
            }),
          ),
          if (item.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(item.comment,
                style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.black87, height: 1.5)),
          ],
          if (item.status == 'REJECTED' &&
              (item.reason?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 6),
            Text('Lý do từ chối: ${item.reason}',
                style: GoogleFonts.inter(fontSize: 12.5, color: _kRed)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (canApprove)
                Expanded(
                  child: _actionButton(
                    label: 'Duyệt',
                    icon: Icons.check_rounded,
                    color: _kGreen,
                    onTap: () => _approve(item),
                  ),
                ),
              if (canApprove && canReject) const SizedBox(width: 10),
              if (canReject)
                Expanded(
                  child: _actionButton(
                    label: 'Từ chối',
                    icon: Icons.close_rounded,
                    color: _kRed,
                    filled: false,
                    onTap: () => _reject(item),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    late Color c;
    late String label;
    switch (status) {
      case 'APPROVED':
        c = _kGreen;
        label = 'Đã duyệt';
        break;
      case 'REJECTED':
        c = _kRed;
        label = 'Bị từ chối';
        break;
      default:
        c = _kAmber;
        label = 'Chờ duyệt';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
