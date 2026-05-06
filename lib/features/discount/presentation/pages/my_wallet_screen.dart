import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/my_wallet_cubit.dart';
import '../../domain/entities/user_discount_entity.dart';

class MyWalletScreen extends StatefulWidget {
  final String userId;

  const MyWalletScreen({super.key, required this.userId});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<MyWalletCubit>().loadWallet(widget.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Voucher của tôi',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: 17, color: Colors.black87),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryRed,
          tabs: const [
            Tab(text: 'Có thể dùng'),
            Tab(text: 'Đã dùng / Hết hạn'),
          ],
        ),
      ),
      body: BlocBuilder<MyWalletCubit, MyWalletState>(
        builder: (context, state) {
          if (state.status == WalletStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == WalletStatus.failure) {
            return Center(
              child: Text(state.errorMessage,
                  style: GoogleFonts.inter(color: Colors.grey)),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _VoucherList(vouchers: state.available),
              _VoucherList(vouchers: state.usedOrExpired, dimmed: true),
            ],
          );
        },
      ),
    );
  }
}

class _VoucherList extends StatelessWidget {
  final List<UserDiscountEntity> vouchers;
  final bool dimmed;

  const _VoucherList({required this.vouchers, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Chưa có voucher nào',
                style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vouchers.length,
      itemBuilder: (_, i) =>
          _VoucherCard(voucher: vouchers[i], dimmed: dimmed),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final UserDiscountEntity voucher;
  final bool dimmed;

  const _VoucherCard({required this.voucher, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currFmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final isRefund = voucher.isRefundCredit;
    final accent = dimmed
        ? Colors.grey[200]!
        : (isRefund ? const Color(0xFF15803D) : AppColors.primaryRed);

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Container(
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
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isRefund
                            ? currFmt
                                .format(voucher.effectiveValue)
                                .replaceAll(' ', '')
                            : voucher.displayValue,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: isRefund ? 13 : 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRefund
                            ? 'HOÀN'
                            : (voucher.isPercentage ? 'GIẢM' : 'OFF'),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              voucher.discountCode,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          _StatusBadge(status: voucher.walletStatus),
                          const SizedBox(width: 12),
                        ],
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
                          _InfoChip(
                            label: voucher.scopeLabel,
                            color: voucher.isRefundCredit
                                ? const Color(0xFF15803D)
                                : null,
                          ),
                          if (voucher.isRefundCredit &&
                              voucher.remainingValue != null &&
                              voucher.remainingValue! < voucher.value)
                            _InfoChip(
                              label:
                                  'Số dư ${currFmt.format(voucher.remainingValue)}',
                              color: const Color(0xFF15803D),
                            ),
                          if (!voucher.isRefundCredit &&
                              voucher.minOrderValue != null &&
                              voucher.minOrderValue! > 0)
                            _InfoChip(
                                label:
                                    'Tối thiểu ${currFmt.format(voucher.minOrderValue)}'),
                          if (!voucher.isRefundCredit &&
                              voucher.maxDiscountAmount != null &&
                              voucher.maxDiscountAmount! > 0)
                            _InfoChip(
                                label:
                                    'Giảm tối đa ${currFmt.format(voucher.maxDiscountAmount)}'),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'AVAILABLE':
        color = Colors.green;
        label = 'Khả dụng';
        break;
      case 'USED':
        color = Colors.grey;
        label = 'Đã dùng';
        break;
      default:
        color = Colors.orange;
        label = 'Hết hạn';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _InfoChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final base = color ?? const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: 0.12)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10,
              color: base,
              fontWeight: color != null ? FontWeight.w700 : FontWeight.w500)),
    );
  }
}
