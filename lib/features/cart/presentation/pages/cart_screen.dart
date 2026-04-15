import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/cart_entity.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_item_card.dart';
import '../../../checkout/domain/entities/checkout_item_entity.dart';
import '../../../checkout/presentation/pages/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: _buildAppBar(context),
      body: BlocConsumer<CartCubit, CartState>(
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage ||
            prev.successMessage != curr.successMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(state.errorMessage!,
                        style: GoogleFonts.inter(color: Colors.white)),
                  ),
                ]),
                backgroundColor: const Color(0xFFB71C1C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
          }
        },
        builder: (context, state) {
          if (state.status == CartStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          final cart = state.cart;
          final isEmpty = cart == null || cart.isEmpty;

          if (isEmpty) {
            return _EmptyCart(onExplore: () => Navigator.pop(context));
          }

          return Column(
            children: [
              // Scrollable list
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: () => context.read<CartCubit>().loadCart(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return CartItemCard(
                        key: ValueKey('${item.productId}_${item.size}'),
                        item: item,
                        onIncrease: () => context
                            .read<CartCubit>()
                            .updateItem(item.productId, item.size, item.quantity + 1),
                        onDecrease: () => context
                            .read<CartCubit>()
                            .updateItem(item.productId, item.size, item.quantity - 1),
                        onRemove: () => context
                            .read<CartCubit>()
                            .removeItem(item.productId, item.size),
                      );
                    },
                  ),
                ),
              ),
              // Sticky bottom summary + checkout
              _BottomBar(cart: cart),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20, color: AppColors.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Giỏ hàng',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      centerTitle: false,
      actions: [
        BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            final isEmpty = state.cart == null || state.cart!.isEmpty;
            if (isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: () => _confirmClearCart(context),
              child: Text(
                'Xóa tất cả',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryRed,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xóa giỏ hàng?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc muốn xóa tất cả sản phẩm không?',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy',
                style: GoogleFonts.inter(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartCubit>().clearCart();
            },
            child: Text('Xóa',
                style: GoogleFonts.inter(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Sticky bottom bar ────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final CartEntity cart;

  const _BottomBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final itemCount = cart.items.length;
    final total = cart.totalCartPrice;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary rows
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tạm tính ($itemCount sản phẩm)',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey),
                  ),
                  Text(
                    formatter.format(total),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phí vận chuyển',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textGrey)),
                  Text(
                    'Miễn phí',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng cộng',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    formatter.format(total),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final cart = context.read<CartCubit>().state.cart;
                    if (cart == null || cart.isEmpty) return;
                    final items = cart.items
                        .map((i) => CheckoutItemEntity(
                              productId: i.productId,
                              productName: i.productName,
                              brand: i.brand,
                              imageUrl: i.imageUrl,
                              size: i.size,
                              unitPrice: i.unitPrice,
                              originalPrice: i.originalPrice,
                              salePercent: i.salePercent,
                              quantity: i.quantity,
                            ))
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(items: items),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tiến hành thanh toán',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  final VoidCallback onExplore;

  const _EmptyCart({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 48,
                color: Color(0xFFCCCCCC),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Giỏ hàng trống',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm sản phẩm để bắt đầu mua sắm',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: onExplore,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryRed,
                side: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
              ),
              child: Text(
                'Khám phá sản phẩm',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
