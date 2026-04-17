import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/admin_rating_stats_model.dart';

class AdminRatingScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminRatingScreen({super.key, required this.datasource});

  @override
  State<AdminRatingScreen> createState() => _AdminRatingScreenState();
}

class _AdminRatingScreenState extends State<AdminRatingScreen> {
  static const _accent = Color(0xFF7C6FCD);
  static const _gold = Color(0xFFF59E0B);

  AdminRatingStatsModel? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.datasource.getRatingStats();
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!)))
          else ...[
            SliverToBoxAdapter(child: _buildRatingChart()),
            SliverToBoxAdapter(child: _buildRecentReviews()),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: _accent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
        title: Text('Đánh giá',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C4FC7), Color(0xFF9B8EE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChart() {
    final data = _data!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            // Big rating display
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      data.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                          fontSize: 52, fontWeight: FontWeight.w900, color: Colors.black87, height: 1),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < data.averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: _gold,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text('${data.totalReviews} đánh giá',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: data.distribution.map((d) {
                      final frac = d.percentage / 100.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('${d.stars}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                            const SizedBox(width: 4),
                            Icon(Icons.star_rounded, size: 12, color: _gold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: frac,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation(_accent),
                                  minHeight: 7,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 32,
                              child: Text('${d.count}',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReviews() {
    final reviews = _data!.recentReviews;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đánh giá gần đây',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ...reviews.asMap().entries.map((e) => _buildReviewRow(e.value, e.key == reviews.length - 1)),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Chưa có đánh giá', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(RecentReview r, bool isLast) {
    final initials = r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _accent.withOpacity(0.12),
                child: Text(initials,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _accent, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.userName,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                        Row(
                          children: List.generate(5, (i) => Icon(
                            i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 12, color: _gold,
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(r.pitchName,
                        style: GoogleFonts.inter(fontSize: 11, color: _accent.withOpacity(0.7))),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(r.comment,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Text(r.createdAt,
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }
}
