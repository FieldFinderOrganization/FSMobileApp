import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../../domain/entities/tier_info_entity.dart';
import '../cubit/available_vouchers_cubit.dart';
import '../cubit/tier_cubit.dart';

/// Màn hình liệt kê mã giảm giá public user có thể lưu vào ví.
/// Trả về `true` qua Navigator.pop khi user đã lưu ít nhất 1 mã (để màn ví reload).
class AvailableVouchersScreen extends StatefulWidget {
  final String userId;

  const AvailableVouchersScreen({super.key, required this.userId});

  @override
  State<AvailableVouchersScreen> createState() =>
      _AvailableVouchersScreenState();
}

class _AvailableVouchersScreenState extends State<AvailableVouchersScreen> {
  bool _savedAny = false;

  static final _pointFmt = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    context.read<AvailableVouchersCubit>().load(widget.userId);
    context.read<TierCubit>().load(widget.userId); // để khóa voucher chưa đủ hạng
  }

  Future<void> _onSave(String code) async {
    final cubit = context.read<AvailableVouchersCubit>();
    final ok = await cubit.save(widget.userId, code);
    if (!mounted) return;
    if (ok) {
      _savedAny = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu mã $code vào ví',
              style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final msg = cubit.state.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('already') ? 'Bạn đã lưu mã này rồi' : 'Lưu mã thất bại',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onRedeem(AdminDiscountEntity voucher) async {
    final cubit = context.read<AvailableVouchersCubit>();
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
            child:
                Text('Hủy', style: GoogleFonts.inter(color: Colors.grey[600])),
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
    if (ok) _savedAny = true; // mã đã vào ví → màn ví cần reload
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
    return PopScope(
      // Chặn pop ngầm (system back / vuốt) để tự trả _savedAny về màn ví.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _savedAny);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context, _savedAny),
          ),
          title: Text(
            'Mã có thể lưu',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black87),
          ),
        ),
        body: BlocBuilder<AvailableVouchersCubit, AvailableVouchersState>(
          builder: (context, state) {
            if (state.status == AvailableVouchersStatus.loading ||
                state.status == AvailableVouchersStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == AvailableVouchersStatus.failure) {
              return Center(
                child: Text('Không tải được danh sách mã',
                    style: GoogleFonts.inter(color: Colors.grey)),
              );
            }
            if (state.vouchers.isEmpty && state.redeemable.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Hiện không có mã nào để nhận',
                        style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              );
            }
            final bottomInset = MediaQuery.of(context).padding.bottom;
            final userTier = context.watch<TierCubit>().state.userTier;
            return RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: () =>
                  context.read<AvailableVouchersCubit>().load(widget.userId),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                children: [
                  if (state.redeemable.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Đổi bằng điểm',
                      subtitle: 'Bạn có ${_pointFmt.format(state.balance)} điểm',
                    ),
                    const SizedBox(height: 8),
                    ...state.redeemable.map(
                      (v) => _RedeemableCard(
                        voucher: v,
                        redeeming: state.redeemingId == v.id,
                        disabled: state.redeemingId != null &&
                            state.redeemingId != v.id,
                        onRedeem: () => _onRedeem(v),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.vouchers.isNotEmpty) ...[
                    if (state.redeemable.isNotEmpty) ...[
                      const _SectionHeader(title: 'Mã có thể lưu'),
                      const SizedBox(height: 8),
                    ],
                    ...state.vouchers.map((v) {
                      final tierLocked =
                          !TierInfoEntity.meetsTier(userTier, v.minTier);
                      return _ClaimableCard(
                        voucher: v,
                        saving: state.savingCode == v.code,
                        disabled: state.savingCode != null &&
                            state.savingCode != v.code,
                        tierLocked: tierLocked,
                        onSave: () => _onSave(v.code),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ClaimableCard extends StatelessWidget {
  final AdminDiscountEntity voucher;
  final bool saving;
  final bool disabled;
  final bool tierLocked; // user chưa đủ hạng để lưu mã này
  final VoidCallback onSave;

  const _ClaimableCard({
    required this.voucher,
    required this.saving,
    required this.disabled,
    this.tierLocked = false,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currFmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

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
                color: AppColors.primaryRed,
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
                      voucher.isPercentage ? 'GIẢM' : 'OFF',
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (voucher.minTier != null)
                          _TierChip(minTier: voucher.minTier!),
                        if (voucher.minOrderValue != null &&
                            voucher.minOrderValue! > 0)
                          _InfoChip(
                              label:
                                  'Tối thiểu ${currFmt.format(voucher.minOrderValue)}'),
                        if (voucher.maxDiscountAmount != null &&
                            voucher.maxDiscountAmount! > 0)
                          _InfoChip(
                              label:
                                  'Giảm tối đa ${currFmt.format(voucher.maxDiscountAmount)}'),
                        _InfoChip(label: 'Còn ${voucher.quantity}'),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                  onPressed: (saving || disabled || tierLocked) ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    disabledBackgroundColor: tierLocked
                        ? const Color(0xFFBDBDBD)
                        : AppColors.primaryRed.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : tierLocked
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_rounded, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'Cần ${TierInfoEntity.labelOf(voucher.minTier ?? '')}',
                                  style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            )
                          : Text('Lưu',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip hạng yêu cầu trên voucher tier-exclusive: "Bạc trở lên", màu theo hạng.
class _TierChip extends StatelessWidget {
  final String minTier;

  const _TierChip({required this.minTier});

  @override
  Widget build(BuildContext context) {
    final color = TierInfoEntity.colorOf(minTier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TierInfoEntity.iconOf(minTier), size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '${TierInfoEntity.labelOf(minTier)} trở lên',
            style: GoogleFonts.inter(
                fontSize: 10, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500)),
    );
  }
}

/// Tiêu đề nhóm trong màn "Mã có thể nhận".
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87),
        ),
        if (subtitle != null) ...[
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded,
                  size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 4),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Card mã đổi-bằng-điểm mà user đã ĐỦ điểm → bấm đổi ngay tại màn này.
class _RedeemableCard extends StatelessWidget {
  final AdminDiscountEntity voucher;
  final bool redeeming;
  final bool disabled;
  final VoidCallback onRedeem;

  const _RedeemableCard({
    required this.voucher,
    required this.redeeming,
    required this.disabled,
    required this.onRedeem,
  });

  static final _pointFmt = NumberFormat.decimalPattern('vi_VN');

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final cost = voucher.pointCost ?? 0;

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
                  onPressed: (redeeming || disabled) ? null : onRedeem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    disabledBackgroundColor:
                        const Color(0xFFD97706).withValues(alpha: 0.35),
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
                      : Text('Đổi ${_pointFmt.format(cost)} điểm',
                          style: GoogleFonts.inter(
                              fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
