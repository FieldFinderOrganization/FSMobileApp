import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../discount/domain/entities/tier_info_entity.dart';
import '../../../discount/presentation/cubit/tier_cubit.dart';

/// Thẻ hạng thành viên trên trang cá nhân: badge hạng, tổng chi tiêu 12 tháng,
/// progress bar tới hạng kế. Tap để mở sheet quyền lợi 4 hạng.
class TierMembershipCard extends StatefulWidget {
  final String userId;

  const TierMembershipCard({super.key, required this.userId});

  @override
  State<TierMembershipCard> createState() => _TierMembershipCardState();
}

class _TierMembershipCardState extends State<TierMembershipCard> {
  @override
  void initState() {
    super.initState();
    context.read<TierCubit>().load(widget.userId);
  }

  static final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TierCubit, TierState>(
      builder: (context, state) {
        if (state.status == TierStatus.failure) {
          return const SizedBox.shrink(); // lỗi thì ẩn card, không chặn profile
        }
        final info = state.info;
        if (info == null) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _buildCard(context, info);
      },
    );
  }

  Widget _buildCard(BuildContext context, TierInfoEntity info) {
    final color = info.color;
    return GestureDetector(
      onTap: () => _showBenefitsSheet(context, info),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.92), color.withValues(alpha: 0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(TierInfoEntity.iconOf(info.tier),
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Hạng ${info.label}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.85), size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Chi tiêu 12 tháng: ${_currency.format(info.totalSpent12m)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: info.progressPercent / 100,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.isMaxTier
                  ? 'Bạn đang ở hạng cao nhất 🎉'
                  : 'Còn ${_currency.format(info.amountToNextTier ?? 0)} để lên hạng ${TierInfoEntity.labelOf(info.nextTier!)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBenefitsSheet(BuildContext context, TierInfoEntity info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _TierBenefitsSheet(currentTier: info.tier),
    );
  }
}

class _TierBenefitsSheet extends StatelessWidget {
  final String currentTier;

  const _TierBenefitsSheet({required this.currentTier});

  static const _tiers = [
    (
      'MEMBER',
      'Thành viên',
      'Chi tiêu dưới 2.000.000₫',
      ['Lưu và dùng mọi voucher công khai', 'Tích lũy chi tiêu để thăng hạng'],
    ),
    (
      'SILVER',
      'Bạc',
      'Chi tiêu từ 2.000.000₫ / 12 tháng',
      ['Toàn bộ ưu đãi hạng Thành viên', 'Voucher riêng cho hạng Bạc', 'Tự động nhận voucher Bạc khi lên hạng'],
    ),
    (
      'GOLD',
      'Vàng',
      'Chi tiêu từ 5.000.000₫ / 12 tháng',
      ['Toàn bộ ưu đãi hạng Bạc', 'Voucher riêng cho hạng Vàng', 'Ưu đãi giá trị cao hơn'],
    ),
    (
      'DIAMOND',
      'Kim cương',
      'Chi tiêu từ 10.000.000₫ / 12 tháng',
      ['Toàn bộ ưu đãi hạng Vàng', 'Voucher độc quyền Kim cương', 'Ưu đãi cao nhất từ SportsHub'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quyền lợi hạng thành viên',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hạng xét theo tổng chi tiêu 12 tháng gần nhất. Voucher hạng cao dùng được cho mọi hạng thấp hơn của bạn.',
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _tiers.map((t) => _tierRow(t)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierRow((String, String, String, List<String>) t) {
    final (code, label, condition, benefits) = t;
    final color = TierInfoEntity.colorOf(code);
    final isCurrent = code == currentTier;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? color.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? color : const Color(0xFFEAEAEA),
          width: isCurrent ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TierInfoEntity.iconOf(code), size: 18, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Hạng của bạn',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            condition,
            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.inter(
                          fontSize: 12.5, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
