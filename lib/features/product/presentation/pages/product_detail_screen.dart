import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../cart/presentation/pages/cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProductDetailCubit(repository: context.read<ProductRepository>())
            ..loadProduct(productId),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage ||
          prev.successMessage != curr.successMessage,
      listener: (context, cartState) {
        if (cartState.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cartState.errorMessage!,
                      style: GoogleFonts.inter(color: Colors.white)),
                ),
              ]),
              backgroundColor: const Color(0xFFB71C1C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
        } else if (cartState.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(cartState.successMessage!,
                    style: GoogleFonts.inter(color: Colors.white)),
              ]),
              backgroundColor: AppColors.primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Xem giỏ',
                textColor: Colors.white70,
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
            ));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          if (state.status == ProductDetailStatus.loading ||
              state.status == ProductDetailStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }
          if (state.status == ProductDetailStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage,
                    style: GoogleFonts.inter(color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context
                        .read<ProductDetailCubit>()
                        .loadProduct(state.product?.id ?? ''),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final product = state.product!;
          return _ProductContent(product: product, state: state);
        },
      ),
    ),  // end Scaffold
    );  // end BlocListener
  }
}

class _ProductContent extends StatelessWidget {
  final ProductEntity product;
  final ProductDetailState state;

  const _ProductContent({required this.product, required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Fake3DImageSection(imageUrl: product.imageUrl),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BrandCategoryRow(
                      brand: product.brand,
                      category: product.categoryName,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(product: product),
                    const SizedBox(height: 20),
                    _SizeSelector(
                      variants: product.variants,
                      selectedSize: state.selectedSize,
                      productId: product.id,
                    ),
                    const SizedBox(height: 20),
                    _DescriptionSection(description: product.description),
                    const SizedBox(height: 16),
                    if (product.tags.isNotEmpty) _TagsRow(tags: product.tags),
                    const SizedBox(height: 12),
                    _SoldCount(totalSold: product.totalSold),
                    const SizedBox(height: 100), // bottom bar clearance
                  ],
                ),
              ),
            ),
          ],
        ),
        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _BackButton(),
        ),
        // Bottom bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomBar(state: state),
        ),
      ],
    );
  }
}

// ─── Fake 3D Image Section ────────────────────────────────────────────────────

class _Fake3DImageSection extends StatefulWidget {
  final String imageUrl;

  const _Fake3DImageSection({required this.imageUrl});

  @override
  State<_Fake3DImageSection> createState() => _Fake3DImageSectionState();
}

class _Fake3DImageSectionState extends State<_Fake3DImageSection>
    with SingleTickerProviderStateMixin {
  double _rotationY = 0.0;
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _snapBackController.stop();
    setState(() {
      _rotationY += details.delta.dx * 0.008;
      _rotationY = _rotationY.clamp(-0.4, 0.4);
    });
  }

  void _onDragEnd(DragEndDetails _) {
    _snapBackAnimation = Tween<double>(begin: _rotationY, end: 0.0).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.elasticOut),
    );
    _snapBackAnimation.addListener(() {
      setState(() => _rotationY = _snapBackAnimation.value);
    });
    _snapBackController.forward(from: 0);
  }

  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenImageViewer(imageUrl: widget.imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onLongPress: () => _openFullscreen(context),
      child: Container(
        height: 320,
        color: const Color(0xFFF5F5F5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_rotationY),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                height: 280,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 80,
                  color: AppColors.textGrey,
                ),
              ),
            ),
            // Hint icon bottom-right
            Positioned(
              bottom: 12,
              right: 16,
              child: Row(
                children: [
                  Icon(Icons.open_in_full, size: 14, color: Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    'Giữ để phóng to',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: Row(
                children: [
                  Icon(Icons.swipe, size: 14, color: Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    'Kéo để xoay',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fullscreen viewer ────────────────────────────────────────────────────────

class _FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullscreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 80,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _BrandCategoryRow extends StatelessWidget {
  final String brand;
  final String category;

  const _BrandCategoryRow({required this.brand, required this.category});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if (brand.isNotEmpty)
          _Chip(
            label: brand,
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            textColor: AppColors.primaryRed,
          ),
        if (category.isNotEmpty)
          _Chip(
            label: category,
            color: Colors.grey.shade100,
            textColor: AppColors.textGrey,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final ProductEntity product;

  const _PriceRow({required this.product});

  String _formatPrice(double price) {
    final p = price.toInt();
    final s = p.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _formatPrice(product.isOnSale ? product.salePrice! : product.price),
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: product.isOnSale ? AppColors.primaryRed : AppColors.textDark,
          ),
        ),
        if (product.isOnSale) ...[
          const SizedBox(width: 10),
          Text(
            _formatPrice(product.price),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textGrey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${product.salePercent}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SizeSelector extends StatelessWidget {
  final List<ProductVariantEntity> variants;
  final String? selectedSize;
  final String productId;

  const _SizeSelector({
    required this.variants,
    required this.productId,
    this.selectedSize,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        // Build map: size → qty already in cart for this product
        final cartQty = <String, int>{};
        for (final item in cartState.cart?.items ?? []) {
          if (item.productId == int.tryParse(productId)) {
            cartQty[item.size] = item.quantity;
          }
        }

        // Auto-deselect if the currently selected size just became cart-full
        if (selectedSize != null) {
          final selectedVariant =
              variants.where((v) => v.size == selectedSize).firstOrNull;
          if (selectedVariant != null) {
            final inCart = cartQty[selectedSize] ?? 0;
            if (inCart >= selectedVariant.quantity) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.read<ProductDetailCubit>().deselectSize();
                }
              });
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn size',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: variants.map((v) {
                final isSelected = v.size == selectedSize;
                final isOut = !v.isAvailable;
                // Full in cart = stock exhausted by current cart quantity
                final inCart = cartQty[v.size] ?? 0;
                final isCartFull = inCart >= v.quantity;
                final isDisabled = isOut || isCartFull;

                String subLabel;
                if (isOut) {
                  subLabel = 'Hết hàng';
                } else if (isCartFull) {
                  subLabel = 'Đã đủ trong giỏ';
                } else {
                  final remaining = v.quantity - inCart;
                  subLabel = 'Còn $remaining';
                }

                return GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => context
                          .read<ProductDetailCubit>()
                          .selectSize(v.size),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryRed
                          : isDisabled
                              ? Colors.grey.shade100
                              : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryRed
                            : isDisabled
                                ? Colors.grey.shade300
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          v.size,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : isDisabled
                                    ? AppColors.textGrey
                                    : AppColors.textDark,
                            decoration: isDisabled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          subLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : isCartFull
                                    ? Colors.orange.shade700
                                    : isOut
                                        ? AppColors.textGrey
                                        : Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _DescriptionSection extends StatefulWidget {
  final String description;

  const _DescriptionSection({required this.description});

  @override
  State<_DescriptionSection> createState() => _DescriptionSectionState();
}

class _DescriptionSectionState extends State<_DescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả sản phẩm',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textGrey,
            height: 1.6,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _expanded ? 'Thu gọn' : 'Xem thêm',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;

  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => _Chip(
              label: '#$tag',
              color: Colors.grey.shade100,
              textColor: AppColors.textGrey,
            ),
          )
          .toList(),
    );
  }
}

class _SoldCount extends StatelessWidget {
  final int totalSold;

  const _SoldCount({required this.totalSold});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
        const SizedBox(width: 4),
        Text(
          'Đã bán: $totalSold',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final ProductDetailState state;

  const _BottomBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasVariants = state.product?.variants.isNotEmpty ?? false;
    final hasSelection = state.selectedSize != null;
    final canAdd = !hasVariants || hasSelection;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: canAdd
              ? () {
                  final product = state.product!;
                  final selectedSize = state.selectedSize ?? '';
                  // Get stock for selected size to pass to client-side guard
                  final stock = product.variants
                      .where((v) => v.size == selectedSize)
                      .firstOrNull
                      ?.quantity;
                  context.read<CartCubit>().addItem(
                        int.parse(product.id),
                        selectedSize,
                        1,
                        stockAvailable: stock,
                      );
                  // SnackBar handled by BlocListener<CartCubit> above
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasVariants && !hasSelection
                    ? 'Chọn size trước'
                    : 'Thêm vào giỏ hàng',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: canAdd ? Colors.white : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
