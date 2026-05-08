import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../discount/data/datasources/discount_remote_data_source.dart';
import '../../../discount/data/models/user_discount_model.dart';
import '../../../discount/domain/entities/user_discount_entity.dart';

class BookingDiscountPicker extends StatefulWidget {
  final String userId;
  final DiscountRemoteDataSource dataSource;
  final List<String> initiallySelected;

  const BookingDiscountPicker({
    super.key,
    required this.userId,
    required this.dataSource,
    this.initiallySelected = const [],
  });

  static Future<List<UserDiscountEntity>?> show(
    BuildContext context, {
    required String userId,
    required DiscountRemoteDataSource dataSource,
    List<String> initiallySelected = const [],
  }) {
    return showModalBottomSheet<List<UserDiscountEntity>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookingDiscountPicker(
        userId: userId,
        dataSource: dataSource,
        initiallySelected: initiallySelected,
      ),
    );
  }

  @override
  State<BookingDiscountPicker> createState() => _State();
}

class _State extends State<BookingDiscountPicker> {
  late Future<List<UserDiscountModel>> _future;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _future = widget.dataSource.getWallet(widget.userId);
    _selected = widget.initiallySelected.toSet();
  }

  bool _isApplicable(UserDiscountEntity v) {
    if (!v.isAvailable) return false;
    if (v.isRefundCredit) return true;
    return v.scope == 'GLOBAL';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Chọn mã ưu đãi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Refund + Toàn cục',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<UserDiscountModel>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text('Lỗi: ${snap.error}',
                            style: GoogleFonts.inter(color: Colors.red)),
                      );
                    }
                    final all = snap.data ?? [];
                    final usable =
                        all.where(_isApplicable).toList();
                    if (usable.isEmpty) {
                      return Center(
                        child: Text(
                          'Chưa có mã phù hợp',
                          style: GoogleFonts.inter(color: AppColors.textGrey),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      itemCount: usable.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final v = usable[i];
                        final picked = _selected.contains(v.discountCode);
                        return _Tile(
                          voucher: v,
                          picked: picked,
                          onTap: () => setState(() {
                            if (picked) {
                              _selected.remove(v.discountCode);
                            } else {
                              _selected.add(v.discountCode);
                            }
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final all = await _future;
                      final picked = all
                          .where((v) => _selected.contains(v.discountCode))
                          .toList();
                      if (!context.mounted) return;
                      Navigator.pop<List<UserDiscountEntity>>(context, picked);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _selected.isEmpty
                          ? 'Bỏ qua'
                          : 'Áp dụng ${_selected.length} mã',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                    ),
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

class _Tile extends StatelessWidget {
  final UserDiscountEntity voucher;
  final bool picked;
  final VoidCallback onTap;

  const _Tile({
    required this.voucher,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRefund = voucher.isRefundCredit;
    final accent = isRefund ? const Color(0xFF15803D) : AppColors.primaryRed;
    final fmt = NumberFormat.currency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final valueText = voucher.isPercentage
        ? '-${voucher.value.toInt()}%'
        : '-${fmt.format(voucher.effectiveValue)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: picked ? accent : const Color(0xFFE0E0E0),
            width: picked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isRefund ? 'HOÀN' : 'GIẢM',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.discountCode,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valueText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: picked,
              onChanged: (_) => onTap(),
              activeColor: accent,
              shape: const CircleBorder(),
            ),
          ],
        ),
      ),
    );
  }
}
