import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/admin_discount_entity.dart';
import '../cubit/available_vouchers_cubit.dart';

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

  @override
  void initState() {
    super.initState();
    context.read<AvailableVouchersCubit>().load(widget.userId);
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
            if (state.vouchers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Hiện không có mã nào để lưu',
                        style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              );
            }
            final bottomInset = MediaQuery.of(context).padding.bottom;
            return RefreshIndicator(
              color: AppColors.primaryRed,
              onRefresh: () =>
                  context.read<AvailableVouchersCubit>().load(widget.userId),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                itemCount: state.vouchers.length,
                itemBuilder: (_, i) {
                  final v = state.vouchers[i];
                  return _ClaimableCard(
                    voucher: v,
                    saving: state.savingCode == v.code,
                    disabled: state.savingCode != null &&
                        state.savingCode != v.code,
                    onSave: () => _onSave(v.code),
                  );
                },
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
  final VoidCallback onSave;

  const _ClaimableCard({
    required this.voucher,
    required this.saving,
    required this.disabled,
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
                  onPressed: (saving || disabled) ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    disabledBackgroundColor:
                        AppColors.primaryRed.withValues(alpha: 0.4),
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
