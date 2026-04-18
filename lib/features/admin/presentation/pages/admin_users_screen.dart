import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/admin_user_list_model.dart';
import '../../data/models/admin_user_stats_model.dart';

class AdminUsersScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminUsersScreen({super.key, required this.datasource});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // Palette
  static const _kPrimary   = Color(0xFF4454A0);
  static const _kPrimaryEnd= Color(0xFF9E91D1);
  static const _kTeal      = Color(0xFF0D9988);
  static const _kRed       = Color(0xFFEF4444);
  static const _kOrange    = Color(0xFFF59E0B);
  static const _kProviderColor = Color(0xFF059669);
  DateTime _lastUpdated = DateTime.now();

  // Avatar palette (Gmail-style)
  static const _kAvatarPalette = [
    Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFF8D6E63),
    Color(0xFF42A5F5), Color(0xFF66BB6A), Color(0xFFEC407A),
    Color(0xFFAB47BC), Color(0xFFFF7043),
  ];

  AdminUserStatsModel? _stats;
  AdminUserListModel?  _page;
  bool   _loading     = true;
  String? _error;
  int    _currentPage = 0;
  bool   _showSearch  = false;
  String _searchQuery = '';
  final _searchCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final results = await Future.wait([
        widget.datasource.getUserStats(),
        widget.datasource.getUsers(page: _currentPage, search: _searchQuery),
      ]);
      
      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminUserStatsModel;
        _page  = results[1] as AdminUserListModel;
        _loading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadPage(int page) async {
    setState(() { _currentPage = page; _loading = true; });
    try {
      final result = await widget.datasource.getUsers(page: page, search: _searchQuery);
      setState(() { _page = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _getTimeAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) {
      return 'Dữ liệu cập nhật ${diff.inSeconds} giây trước';
    } else if (diff.inMinutes < 60) {
      return 'Dữ liệu cập nhật ${diff.inMinutes}p trước';
    } else {
      return 'Dữ liệu cập nhật ${diff.inHours}h trước';
    }
  }

  void _onSearch(String q) {
    _searchQuery = q;
    _currentPage = 0;
    _load();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stats  = _stats;
    final total  = stats?.total ?? 0;
    final active = stats?.byStatus.where((s) => s.status == 'ACTIVE').fold(0, (a, b) => a + b.count) ?? 0;
    final blocked = total - active;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _statCard('Tổng cộng', '$total',  null,    Icons.people_alt_outlined),
                  const SizedBox(width: 10),
                  _statCard('Hoạt động', '$active',  _kTeal, Icons.circle),
                  const SizedBox(width: 10),
                  _statCard('Bị khóa',   '$blocked', _kRed,  Icons.circle),
                ],
              ),
            ),
          ),

          // ── Search bar (optional) ───────────────────────────────────────
          if (_showSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: _onSearch,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc email…',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF4454A0)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

          // ── Main content ────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF4454A0))))
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!)))
          else ...[
            if (stats != null) SliverToBoxAdapter(child: _buildDonutCard(stats, total)),
            SliverToBoxAdapter(child: _buildTableSection()),
          ],
        ],
      ),
    );
  }

  // ─── SLIVER APP BAR ───────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 85,
      pinned: true,
      backgroundColor: _kPrimary,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Người dùng',
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      titleSpacing: 0,
      actions: [
        IconButton(
          tooltip: 'Tìm kiếm',
          icon: Icon(
            _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            color: Colors.white, size: 22,
          ),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) { _searchCtrl.clear(); _onSearch(''); }
          }),
        ),
        IconButton(
          tooltip: 'Lọc',
          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          onPressed: () {},
        ),
        IconButton(
          tooltip: 'Thêm người dùng',
          icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
          onPressed: () {},
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
                right: -30, top: -20,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                left: 56, 
                bottom: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dùng StreamBuilder để CHỈ render lại dòng chữ này mỗi 1 giây
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        return Text(
                          _getTimeAgo(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      }
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loading ? null : _load,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.sync_rounded, 
                            size: 16, 
                            color: Colors.white.withOpacity(_loading ? 0.4 : 0.9)
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

  // ─── STAT CARDS (overlap) ─────────────────────────────────────────────────

  Widget _statCard(String label, String value, Color? dotColor, IconData dotIcon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (dotColor != null) ...[
                  Icon(dotIcon, size: 8, color: dotColor),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D2E), height: 1)),
          ],
        ),
      ),
    );
  }

  // ─── DONUT + STATUS BARS ─────────────────────────────────────────────────

  Widget _buildDonutCard(AdminUserStatsModel stats, int total) {
    final roleColors = [_kPrimary, _kOrange, _kProviderColor, _kPrimaryEnd];
    final roles = stats.byRole;
    final active  = stats.byStatus.where((s) => s.status == 'ACTIVE').fold(0, (a, b) => a + b.count);
    final blocked = total - active;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân bổ vai trò',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D2E))),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: roles.map((r) => r.count.toDouble()).toList(),
                      colors: roleColors,
                    ),
                    child: Center(
                      child: Text('$total',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1A1D2E))),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: List.generate(roles.length, (i) {
                      final r     = roles[i];
                      final color = roleColors[i % roleColors.length];
                      final pct   = total > 0 ? (r.count / total * 100).toStringAsFixed(1) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_roleLabel(r.role),
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600))),
                            Text('${r.count} ($pct%)',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1D2E))),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text('Trạng thái tài khoản',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            _statusBar('Hoạt động', active, total, _kTeal),
            const SizedBox(height: 8),
            _statusBar('Bị khóa',   blocked, total, _kRed),
          ],
        ),
      ),
    );
  }

  Widget _statusBar(String label, int count, int total, Color color) {
    final frac = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 6),
            SizedBox(
              width: 62,
              child: Text(label,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
            ),
          ],
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D2E))),
        ),
      ],
    );
  }

  // ─── TABLE ────────────────────────────────────────────────────────────────

  Widget _buildTableSection() {
    final users = _page?.content ?? [];
    final bottomPad = MediaQuery.of(context).padding.bottom + 24;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh sách người dùng',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D2E))),
              if (_page != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_page!.totalElements} người',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ...users.asMap().entries.map((e) => _buildUserRow(e.value, e.key == users.length - 1)),
                if (users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Không tìm thấy người dùng',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_page != null && _page!.totalPages > 1) ...[
            const SizedBox(height: 16),
            buildAdminPaginationBar(_currentPage, _page!.totalPages, _loadPage, _kPrimary),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRow(AdminUserItem user, bool isLast) {
    final initials    = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final avatarColor = _avatarColor(user.name);
    final isBlocked   = user.status != 'ACTIVE';
    final isAdmin     = user.role == 'ADMIN';
    final isProvider  = user.role == 'PROVIDER';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Avatar with status dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor.withOpacity(0.18),
                    child: Text(initials,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, color: avatarColor, fontSize: 15)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: isBlocked ? _kRed : _kTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(user.name,
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1D2E)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        // Only show badge for ADMIN or PROVIDER
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          _roleBadge('Admin', _kRed),
                        ] else if (isProvider) ...[
                          const SizedBox(width: 6),
                          _roleBadge('NCC', _kProviderColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(user.email,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (user.createdAt != null)
                      Text('Tham gia ${_fmtDate(user.createdAt!)}',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              // Last login
              if (user.lastLoginAt != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Login cuối',
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade400)),
                    Text(_fmtDate(user.lastLoginAt!),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600)),
                  ],
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Color _avatarColor(String name) {
    if (name.isEmpty) return _kAvatarPalette[0];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _kAvatarPalette.length;
    return _kAvatarPalette[idx];
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _roleLabel(String role) => switch (role) {
    'ADMIN'    => 'Admin',
    'PROVIDER' => 'Nhà cung cấp',
    _          => 'Người dùng',
  };

  Widget _roleBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── SHARED PAGINATION BAR ────────────────────────────────────────────────────

Widget buildAdminPaginationBar(
    int current, int total, void Function(int) onChanged, Color accent) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _PageBtn(label: '← Trước', enabled: current > 0, accent: accent,
          onTap: () => onChanged(current - 1)),
      const SizedBox(width: 16),
      Text('Trang ${current + 1} / $total',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D2E))),
      const SizedBox(width: 16),
      _PageBtn(label: 'Tiếp →', enabled: current < total - 1, accent: accent,
          onTap: () => onChanged(current + 1)),
    ],
  );
}

class _PageBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  const _PageBtn(
      {required this.label, required this.enabled, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? accent.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? accent : Colors.grey.shade400)),
      ),
    );
  }
}

// ─── DONUT PAINTER ────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);
    final paint  = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap  = StrokeCap.butt;

    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect.deflate(6.5), start + 0.03, sweep - 0.06, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
