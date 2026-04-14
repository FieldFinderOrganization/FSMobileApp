import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../../../core/constants/app_colors.dart';

class CartItemCard extends StatelessWidget {
  final CartItemEntity item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final hasSale = item.salePercent != null && item.salePercent! > 0;
    final isOut = item.isOutOfStock;

    return Opacity(
      opacity: isOut ? 0.55 : 1.0,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + delete button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onRemove,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Brand · Size · Sex
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.brand.isNotEmpty)
                        _Tag(item.brand, AppColors.primaryRed.withValues(alpha: 0.08),
                            AppColors.primaryRed),
                      _Tag('Size ${item.size}', const Color(0xFFF0F0F0),
                          AppColors.textGrey),
                      if (item.sex.isNotEmpty)
                        _Tag(item.sex, const Color(0xFFF0F0F0),
                            AppColors.textGrey),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Stock warning note
                  if (isOut)
                    _StockNote(
                      icon: Icons.inventory_2_outlined,
                      text: 'Sản phẩm đã hết hàng',
                      color: AppColors.textGrey,
                    )
                  else if (item.exceedsStock)
                    _StockNote(
                      icon: Icons.warning_amber_rounded,
                      text: 'Chỉ còn ${item.stockAvailable}, đã điều chỉnh',
                      color: Colors.orange.shade700,
                    ),

                  if (!isOut) ...[
                    const SizedBox(height: 10),
                    // Price + quantity controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasSale)
                              Text(
                                formatter.format(item.originalPrice),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.textGrey,
                                ),
                              ),
                            Text(
                              formatter.format(item.unitPrice),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ],
                        ),

                        // Quantity stepper
                        Row(
                          children: [
                            _StepBtn(
                              icon: Icons.remove_rounded,
                              filled: false,
                              onTap: onDecrease,
                            ),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            _StepBtn(
                              icon: Icons.add_rounded,
                              filled: true,
                              disabled: item.quantity >= item.stockAvailable,
                              onTap: item.quantity >= item.stockAvailable
                                  ? null
                                  : onIncrease,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _placeholder() {
    return Container(
      width: 82,
      height: 82,
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.image_outlined, color: Color(0xFFCCCCCC), size: 28),
    );
  }
}

class _StockNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StockNote({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Tag(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final bool disabled;
  final VoidCallback? onTap;

  const _StepBtn({
    required this.icon,
    required this.filled,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = disabled
        ? const Color(0xFFEEEEEE)
        : filled
            ? AppColors.primaryRed
            : Colors.white;
    final Color borderColor = disabled
        ? const Color(0xFFDDDDDD)
        : filled
            ? AppColors.primaryRed
            : const Color(0xFFDDDDDD);
    final Color iconColor = disabled
        ? const Color(0xFFBBBBBB)
        : filled
            ? Colors.white
            : AppColors.textDark;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Icon(icon, size: 14, color: iconColor),
      ),
    );
  }
}
