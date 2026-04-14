import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../checkout/domain/entities/checkout_item_entity.dart';
import '../../../checkout/presentation/pages/checkout_screen.dart';

class AddToCartModal extends StatefulWidget {
  final ProductEntity product;
  final String selectedSize;
  final int stockAvailable;
  final int currentInCart;
  final CartCubit cartCubit;

  const AddToCartModal({
    super.key,
    required this.product,
    required this.selectedSize,
    required this.stockAvailable,
    required this.currentInCart,
    required this.cartCubit,
  });

  @override
  State<AddToCartModal> createState() => _AddToCartModalState();
}

class _AddToCartModalState extends State<AddToCartModal> {
  int _quantity = 1;

  int get _maxQty => widget.stockAvailable - widget.currentInCart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        // Drag handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên sản phẩm + size
              Text(
                '${widget.product.name} · Size ${widget.selectedSize}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Còn $_maxQty sản phẩm có thể thêm',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 20),

              // Stepper số lượng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Số lượng',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove,
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      SizedBox(
                        width: 44,
                        child: Center(
                          child: Text(
                            '$_quantity',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add,
                        onTap: _quantity < _maxQty
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hai nút hành động
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _addToCart,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primaryRed),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Thêm vào giỏ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _buyNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Mua ngay',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(top: false, child: const SizedBox(height: 8)),
      ],
    );
  }

  void _addToCart() {
    widget.cartCubit.addItem(
      int.parse(widget.product.id),
      widget.selectedSize,
      _quantity,
      stockAvailable: widget.stockAvailable,
    );
    Navigator.pop(context);
  }

  void _buyNow() {
    final item = CheckoutItemEntity(
      productId: int.parse(widget.product.id),
      productName: widget.product.name,
      brand: widget.product.brand,
      imageUrl: widget.product.imageUrl,
      size: widget.selectedSize,
      unitPrice: widget.product.salePrice ?? widget.product.price,
      originalPrice: widget.product.price,
      salePercent: widget.product.salePercent,
      quantity: _quantity,
    );
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(items: [item])),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryRed.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primaryRed : Colors.grey.shade400,
        ),
      ),
    );
  }
}
