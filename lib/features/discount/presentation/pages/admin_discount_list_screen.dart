import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../cubit/admin_discount_cubit.dart';
import 'admin_discount_form_screen.dart';
import 'admin_assign_discount_screen.dart';

class AdminDiscountListScreen extends StatefulWidget {
  const AdminDiscountListScreen({super.key});

  @override
  State<AdminDiscountListScreen> createState() =>
      _AdminDiscountListScreenState();
}

class _AdminDiscountListScreenState extends State<AdminDiscountListScreen> {
  // Palette — giống admin_users
  static const _kPrimary = Color(0xFF4454A0);
  static const _kPrimaryEnd = Color(0xFF9E91D1);
  static const _kTeal = Color(0xFF059669);
  static const _kAmber = Color(0xFFF59E0B);
  static const _kGrey = Color(0xFF6B7280);
  static const _kCoralPink = Color(0xFFE05FA3);
  static const _kDeepIndigo = Color(0xFF3E54AC);

  String _filterStatus = 'ALL'; // ALL | ACTIVE | INACTIVE | EXPIRED
  String _filterType = 'ALL'; // ALL | PERCENTAGE | FIXED_AMOUNT
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  DateTime _lastUpdated = DateTime.now();

  String _getTimeAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) return 'Cập nhật ${diff.inSeconds}s trước';
    if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes}p trước';
    return 'Cập nhật ${diff.inHours}h trước';
  }

  @override
  void initState() {
    super.initState();
    context.read<AdminDiscountCubit>().loadDiscounts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Sort: active (sắp hết hạn trước) → inactive → expired (mới nhất trước)
  List<AdminDiscountEntity> _sortedAndFiltered(List<AdminDiscountEntity> all) {
    final filtered = all.where((d) {
      if (_filterStatus != 'ALL' && d.effectiveStatus != _filterStatus)
        return false;
      if (_filterType != 'ALL' && d.discountType != _filterType) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return d.code.toLowerCase().contains(q) ||
            d.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int statusOrder(String s) => s == 'ACTIVE'
          ? 0
          : s == 'INACTIVE'
          ? 1
          : 2;
      final so = statusOrder(
        a.effectiveStatus,
      ).compareTo(statusOrder(b.effectiveStatus));
      if (so != 0) return so;
      // Trong cùng nhóm ACTIVE: sắp xếp endDate tăng dần (sắp hết hạn lên đầu)
      if (a.effectiveStatus == 'ACTIVE') return a.endDate.compareTo(b.endDate);
      // INACTIVE: startDate giảm dần (mới nhất lên đầu)
      if (a.effectiveStatus == 'INACTIVE')
        return b.startDate.compareTo(a.startDate);
      // EXPIRED: endDate giảm dần (mới hết nhất lên đầu)
      return b.endDate.compareTo(a.endDate);
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminDiscountCubit, AdminDiscountState>(
      listener: (context, state) {
        if (state.status == AdminDiscountStatus.success &&
            state.discounts.isNotEmpty) {
          setState(() => _lastUpdated = DateTime.now());
        }
        if (state.status == AdminDiscountStatus.actionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.actionMessage,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: _kTeal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state.status == AdminDiscountStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final all = state.discounts;
        final totalCount = all.length;
        final activeCount = all
            .where((d) => d.effectiveStatus == 'ACTIVE')
            .length;
        final inactiveCount = all
            .where((d) => d.effectiveStatus == 'INACTIVE')
            .length;
        final expiredCount = all
            .where((d) => d.effectiveStatus == 'EXPIRED')
            .length;
        final filtered = _sortedAndFiltered(all);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),

              // ── KPI cards (2×2 grid giống dashboard) ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              title: 'Tổng cộng',
                              value: '$totalCount',
                              subtitle: 'mã',
                              icon: Icons.confirmation_number_outlined,
                              accentColor: _kDeepIndigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpiCard(
                              title: 'Hoạt động',
                              value: '$activeCount',
                              subtitle: 'đang dùng',
                              icon: Icons.check_circle_outline,
                              accentColor: _kTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _kpiCard(
                              title: 'Đã tắt',
                              value: '$inactiveCount',
                              subtitle: 'tạm ngừng',
                              icon: Icons.pause_circle_outline,
                              accentColor: _kAmber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _kpiCard(
                              title: 'Hết hạn',
                              value: '$expiredCount',
                              subtitle: 'đã hết hạn',
                              icon: Icons.timer_off_outlined,
                              accentColor: _kGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar (toggle) ─────────────────────────────────────────
              if (_showSearch)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo mã hoặc mô tả…',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: _kPrimary,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Filter bars ────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildStatusFilterBar()),
              SliverToBoxAdapter(child: _buildTypeFilterBar()),

              // ── List ────────────────────────────────────────────────────────
              if (state.status == AdminDiscountStatus.loading && all.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 52,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có mã nào',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.of(context).padding.bottom + 80,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DiscountCard(
                          discount: filtered[i],
                          onToggle: () =>
                              context.read<AdminDiscountCubit>().toggleStatus(
                                filtered[i].id,
                                filtered[i].isActive,
                              ),
                          onEdit: () => _openForm(context, filtered[i]),
                          onAssign: filtered[i].scope == 'GLOBAL'
                              ? null
                              : () => _openAssign(context, filtered[i]),
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context, null),
            backgroundColor: _kPrimary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Tạo mã',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── SliverAppBar ─────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 85,
      pinned: true,
      backgroundColor: _kPrimary,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Mã khuyến mãi',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      titleSpacing: 0,
      actions: [
        IconButton(
          tooltip: 'Tìm kiếm',
          icon: Icon(
            _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) {
              _searchCtrl.clear();
              _searchQuery = '';
            }
          }),
        ),
        IconButton(
          tooltip: 'Làm mới',
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => context.read<AdminDiscountCubit>().loadDiscounts(),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimary, _kPrimaryEnd],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: 56,
                bottom: 6,
                child: Row(
                  children: [
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (_, _) => Text(
                        _getTimeAgo(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            context.read<AdminDiscountCubit>().loadDiscounts(),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.sync_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── KPI card — y hệt _buildCompactKpiCard của dashboard ──────────────────

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Filter bars ───────────────────────────────────────────────────────────

  Widget _buildStatusFilterBar() {
    const items = [
      ('ALL', 'Tất cả'),
      ('ACTIVE', 'Hoạt động'),
      ('INACTIVE', 'Đã tắt'),
      ('EXPIRED', 'Hết hạn'),
    ];
    return _filterChipBar(
      items: items,
      selected: _filterStatus,
      onSelect: (v) => setState(() => _filterStatus = v),
    );
  }

  Widget _buildTypeFilterBar() {
    const items = [
      ('ALL', 'Tất cả loại'),
      ('PERCENTAGE', '% Phần trăm'),
      ('FIXED_AMOUNT', '₫ Cố định'),
    ];
    return _filterChipBar(
      items: items,
      selected: _filterType,
      onSelect: (v) => setState(() => _filterType = v),
      topPadding: 0,
    );
  }

  Widget _filterChipBar({
    required List<(String, String)> items,
    required String selected,
    required ValueChanged<String> onSelect,
    double topPadding = 12,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 4),
      child: Row(
        children: items.map((item) {
          final (val, label) = item;
          final isSel = selected == val;
          return GestureDetector(
            onTap: () => onSelect(val),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSel ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isSel)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
                border: isSel ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isSel ? Colors.white : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openForm(BuildContext ctx, AdminDiscountEntity? discount) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: ctx.read<AdminDiscountCubit>(),
          child: AdminDiscountFormScreen(discount: discount),
        ),
      ),
    );
  }

  void _openAssign(BuildContext ctx, AdminDiscountEntity discount) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: ctx.read<AdminDiscountCubit>(),
          child: AdminAssignDiscountScreen(discount: discount),
        ),
      ),
    );
  }
}

// ─── Discount Card ────────────────────────────────────────────────────────────

class _DiscountCard extends StatelessWidget {
  final AdminDiscountEntity discount;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onAssign;

  const _DiscountCard({
    required this.discount,
    required this.onToggle,
    required this.onEdit,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yy');
    final currFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final effStatus = discount.effectiveStatus;

    Color statusColor;
    Color leftBorder;
    String statusLabel;
    switch (effStatus) {
      case 'ACTIVE':
        statusColor = const Color(0xFF059669);
        leftBorder = const Color(0xFF059669);
        statusLabel = 'Hoạt động';
        break;
      case 'INACTIVE':
        statusColor = const Color(0xFFF59E0B);
        leftBorder = const Color(0xFFF59E0B);
        statusLabel = 'Đã tắt';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        leftBorder = const Color(0xFFD1D5DB);
        statusLabel = 'Hết hạn';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(left: BorderSide(color: leftBorder, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    discount.displayValue,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    discount.code,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A1D2E),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (discount.description.isNotEmpty)
              Text(
                discount.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _MetaChip(label: _scopeLabel(discount.scope)),
                _MetaChip(
                  label: discount.isPercentage ? '% Phần trăm' : '₫ Cố định',
                ),
                _MetaChip(label: 'Còn lại: ${discount.quantity}'),
                if (discount.minOrderValue != null &&
                    discount.minOrderValue! > 0)
                  _MetaChip(
                    label: 'Min ${currFmt.format(discount.minOrderValue)}',
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '${dateFmt.format(discount.startDate)} → ${dateFmt.format(discount.endDate)}',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
                if (effStatus == 'ACTIVE') ...[
                  const SizedBox(width: 6),
                  Text(
                    _daysLeft(discount.endDate),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF059669),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onAssign != null) ...[
                  _ActionBtn(
                    icon: Icons.person_add_outlined,
                    label: 'Gán user',
                    onTap: onAssign!,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                ],
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Sửa',
                  onTap: onEdit,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: discount.isActive
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                  label: discount.isActive ? 'Tắt' : 'Bật',
                  onTap: onToggle,
                  color: discount.isActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF059669),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel(String scope) {
    switch (scope) {
      case 'GLOBAL':
        return '🌐 Toàn bộ';
      case 'CATEGORY':
        return '📂 Danh mục';
      default:
        return '📦 Sản phẩm';
    }
  }

  String _daysLeft(DateTime end) {
    final days = end.difference(DateTime.now()).inDays;
    if (days == 0) return '• Hết hạn hôm nay';
    if (days == 1) return '• Còn 1 ngày';
    return '• Còn $days ngày';
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(color: const Color(0xFF374151), fontSize: 10),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
