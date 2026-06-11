import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../../domain/entities/point_info_entity.dart';
import '../../domain/entities/tier_info_entity.dart';
import '../cubit/points_cubit.dart';
import '../cubit/tier_cubit.dart';

/// Màn điểm thưởng: tab "Điểm của tôi" (số dư + lịch sử) + tab "Đổi quà"
/// (catalog mã pointCost, đổi điểm lấy voucher vào ví).
class PointsScreen extends StatefulWidget {
  final String userId;

  const PointsScreen({super.key, required this.userId});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PointsCubit>().load(widget.userId);
    context.read<TierCubit>().load(widget.userId); // khóa mã gắn hạng
  }

  static final _pointFmt = NumberFormat.decimalPattern('vi_VN');

  Future<void> _onRedeem(AdminDiscountEntity voucher) async {
    final cubit = context.read<PointsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đổi voucher',
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Dùng ${_pointFmt.format(voucher.pointCost)} điểm để đổi mã ${voucher.code}?',
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy',
                style: GoogleFonts.inter(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Đổi',
                style: GoogleFonts.inter(
                    color: AppColors.primaryRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await cubit.redeem(widget.userId, voucher.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã đổi mã ${voucher.code} — kiểm tra ví voucher'
              : _friendlyError(cubit.state.errorMessage),
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: ok ? const Color(0xFF15803D) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('Không đủ điểm')) return 'Bạn không đủ điểm để đổi mã này';
    if (raw.contains('đã đổi')) return 'Bạn đã đổi mã này rồi';
    if (raw.contains('hạng')) return 'Mã này yêu cầu hạng thành viên cao hơn';
    return 'Đổi mã thất bại, thử lại sau';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Điểm thưởng',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black87),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryRed,
            unselectedLabelColor: Colors.grey[500],
            indicatorColor: AppColors.primaryRed,
            labelStyle:
                GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Điểm của tôi'),
              Tab(text: 'Đổi quà'),
            ],
          ),
        ),
        body: BlocBuilder<PointsCubit, PointsState>(
          builder: (context, state) {
            if (state.status == PointsStatus.loading ||
                state.status == PointsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == PointsStatus.failure) {
              return Center(
                child: Text('Không tải được điểm thưởng',
                    style: GoogleFonts.inter(color: Colors.grey)),
              );
            }
            return TabBarView(
              children: [
                _buildHistoryTab(state),
                _buildRedeemTab(state),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Tab 1: số dư + lịch sử ────────────────────────────────────────────────

  Widget _buildHistoryTab(PointsState state) {
    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () => context.read<PointsCubit>().load(widget.userId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(state.balance),
          const SizedBox(height: 16),
          Text(
            'Lịch sử giao dịch',
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          if (state.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Chưa có giao dịch nào.\nMua hàng để tích điểm nhé!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ...state.transactions.map(_buildTxRow),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(int balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
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
              const Icon(Icons.monetization_on_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'Điểm hiện có',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _pointFmt.format(balance),
            style: GoogleFonts.inter(
                fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Mỗi 10.000₫ chi tiêu = 1 điểm (cộng khi giao hàng thành công)',
            style: GoogleFonts.inter(
                fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildTxRow(PointTransactionEntity tx) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final positive = tx.isPositive;
    final color = positive ? const Color(0xFF15803D) : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  dateFmt.format(tx.createdAt),
                  style:
                      GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${_pointFmt.format(tx.amount)}',
            style: GoogleFonts.inter(
                fontSize: 14.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: đổi quà ────────────────────────────────────────────────────────

  Widget _buildRedeemTab(PointsState state) {
    if (state.catalog.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Chưa có mã nào để đổi',
                style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }
    final userTier = context.watch<TierCubit>().state.userTier;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () => context.read<PointsCubit>().load(widget.userId),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
        itemCount: state.catalog.length,
        itemBuilder: (_, i) {
          final v = state.catalog[i];
          return _RedeemCard(
            voucher: v,
            balance: state.balance,
            owned: state.ownedCodes.contains(v.code),
            tierLocked: !TierInfoEntity.meetsTier(userTier, v.minTier),
            redeeming: state.redeemingId == v.id,
            disabled: state.redeemingId != null && state.redeemingId != v.id,
            onRedeem: () => _onRedeem(v),
          );
        },
      ),
    );
  }
}

class _RedeemCard extends StatelessWidget {
  final AdminDiscountEntity voucher;
  final int balance;
  final bool owned;
  final bool tierLocked;
  final bool redeeming;
  final bool disabled;
  final VoidCallback onRedeem;

  const _RedeemCard({
    required this.voucher,
    required this.balance,
    required this.owned,
    required this.tierLocked,
    required this.redeeming,
    required this.disabled,
    required this.onRedeem,
  });

  static final _pointFmt = NumberFormat.decimalPattern('vi_VN');

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final cost = voucher.pointCost ?? 0;
    final notEnough = balance < cost;
    final blocked = owned || tierLocked || notEnough;

    String buttonLabel;
    if (owned) {
      buttonLabel = 'Đã đổi';
    } else if (tierLocked) {
      buttonLabel = 'Cần ${TierInfoEntity.labelOf(voucher.minTier ?? '')}';
    } else if (notEnough) {
      buttonLabel = 'Thiếu điểm';
    } else {
      buttonLabel = 'Đổi ${_pointFmt.format(cost)} điểm';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFD97706),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      voucher.displayValue,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GIẢM',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.code,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          '${_pointFmt.format(cost)} điểm',
                          style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD97706)),
                        ),
                        if (voucher.minTier != null) ...[
                          const SizedBox(width: 8),
                          Icon(TierInfoEntity.iconOf(voucher.minTier!),
                              size: 12,
                              color: TierInfoEntity.colorOf(voucher.minTier!)),
                          const SizedBox(width: 2),
                          Text(
                            '${TierInfoEntity.labelOf(voucher.minTier!)}+',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    TierInfoEntity.colorOf(voucher.minTier!)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HSD: ${dateFmt.format(voucher.endDate)}',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: (redeeming || disabled || blocked) ? null : onRedeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    disabledBackgroundColor: owned
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFFD97706).withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: redeeming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          buttonLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
