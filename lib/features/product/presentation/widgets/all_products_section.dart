import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../home/presentation/widgets/fade_in_section.dart';
import 'product_card.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../../home/presentation/widgets/shimmer_card.dart';

class AllProductsSection extends StatelessWidget {
  final HomeState state;

  const AllProductsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.productsStatus == LoadStatus.loading ||
        state.productsStatus == LoadStatus.initial;

    return FadeInSection(
      delay: const Duration(milliseconds: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Tất cả sản phẩm', onSeeAll: null, index: '03'),

          // ── Danh mục cha ────────────────────────────────────────────────
          _ParentCategoryChips(state: state),

          // ── Danh mục con ────────────────────────────────────────────────
          if (state.subCategories.isNotEmpty) ...[
            const SizedBox(height: 4),
            _SubCategoryChips(state: state),
          ],

          const SizedBox(height: 8),

          // ── Bộ lọc giá & giới tính ──────────────────────────────────────
          _FilterBar(state: state),

          const SizedBox(height: 12),

          // ── Bento Grid ──────────────────────────────────────────────────
          if (isLoading)
            _buildShimmerBento()
          else if (state.visibleProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: const Center(
                child: Text(
                  'Không có sản phẩm nào.',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StaggeredGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: List.generate(state.visibleProducts.length, (i) {
                  final product = state.visibleProducts[i];
                  // Pattern: Index 0 is Large, then 1-2 small, 3 Large, 4-5 small...
                  final isLarge = i % 3 == 0;
                  
                  return StaggeredGridTile.fit(
                    crossAxisCellCount: isLarge ? 2 : 1,
                    child: ProductCard(
                      product: product,
                      mode: isLarge ? ProductCardMode.featured : ProductCardMode.grid,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
            _PaginationButtons(state: state),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShimmerBento() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: List.generate(5, (i) {
          final isLarge = i % 3 == 0;
          return StaggeredGridTile.fit(
            crossAxisCellCount: isLarge ? 2 : 1,
            child: ShimmerCard(
              width: double.infinity,
              height: isLarge ? 180 : 240,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }
}

// ── Bộ lọc giá & giới tính ──────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final HomeState state;

  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng 1: Sắp xếp theo giá
          Row(
            children: [
              Text(
                'Giá:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: '↑ Tăng dần',
                isActive: state.sortOption == SortOption.priceAsc,
                onTap: () => context.read<HomeCubit>().setSortOption(
                  SortOption.priceAsc,
                ),
              ),
              const SizedBox(width: 6),
              _SortChip(
                label: '↓ Giảm dần',
                isActive: state.sortOption == SortOption.priceDesc,
                onTap: () => context.read<HomeCubit>().setSortOption(
                  SortOption.priceDesc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hàng 2: Lọc theo giới tính
          Row(
            children: [
              Text(
                'Giới tính:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(width: 8),
              _GenderChip(
                label: 'Nam',
                value: 'Men',
                selectedGenders: state.selectedGenders,
              ),
              const SizedBox(width: 6),
              _GenderChip(
                label: 'Nữ',
                value: 'Women',
                selectedGenders: state.selectedGenders,
              ),
              const SizedBox(width: 6),
              _GenderChip(
                label: 'Unisex',
                value: 'Unisex',
                selectedGenders: state.selectedGenders,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryRed : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppColors.primaryRed : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final String value;
  final Set<String> selectedGenders;

  const _GenderChip({
    required this.label,
    required this.value,
    required this.selectedGenders,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selectedGenders.contains(value);
    return GestureDetector(
      onTap: () => context.read<HomeCubit>().toggleGender(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryRed : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppColors.primaryRed : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

// ── Nút Ẩn bớt / Xem thêm ───────────────────────────────────────────────────

class _PaginationButtons extends StatelessWidget {
  final HomeState state;

  const _PaginationButtons({required this.state});

  @override
  Widget build(BuildContext context) {
    final canCollapse = state.visibleProductCount > kProductPageSize;
    final canLoadMore = state.hasMoreProducts;

    if (!canCollapse && !canLoadMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ── Nút Ẩn bớt ────────────────────────────────────────────────
          if (canCollapse)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.read<HomeCubit>().collapseProducts(),
                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 16),
                label: Text(
                  'Ẩn bớt',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          if (canCollapse && canLoadMore) const SizedBox(width: 10),

          // ── Nút Xem thêm ──────────────────────────────────────────────
          if (canLoadMore)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.read<HomeCubit>().loadMoreProducts(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                label: Text(
                   'Xem thêm',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                  side: const BorderSide(color: AppColors.primaryRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Danh mục cha ────────────────────────────────────────────────────────────

class _ParentCategoryChips extends StatelessWidget {
  final HomeState state;

  const _ParentCategoryChips({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.categoriesStatus == LoadStatus.loading ||
        state.categoriesStatus == LoadStatus.initial;

    if (isLoading) {
      return SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: ShimmerCard(
              width: 80,
              height: 36,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    final roots = state.rootCategories;
    final selected = state.selectedCategoryName;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: roots.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'Tất cả' : roots[index - 1].name;
          final value = isAll ? '' : roots[index - 1].name;
          final isActive = selected == value;
          final hasChildren =
              !isAll &&
              state.categories.any(
                (c) => c.parentName == roots[index - 1].name,
              );

          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: GestureDetector(
              onTap: () => context.read<HomeCubit>().selectCategory(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryRed
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.textGrey,
                      ),
                    ),
                    if (hasChildren) ...[
                      const SizedBox(width: 3),
                      Icon(
                        isActive
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: isActive ? Colors.white : AppColors.textGrey,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Danh mục con (multi-select) ──────────────────────────────────────────────

class _SubCategoryChips extends StatelessWidget {
  final HomeState state;

  const _SubCategoryChips({required this.state});

  @override
  Widget build(BuildContext context) {
    final subs = state.subCategories;
    final selectedSubs = state.selectedSubCategoryNames;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: subs.map((cat) {
          final isSelected = selectedSubs.contains(cat.name);
          return GestureDetector(
            onTap: () => context.read<HomeCubit>().toggleSubCategory(cat.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryRed
                      : const Color(0xFFDDDDDD),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: isSelected
                        ? const Icon(
                            Icons.check_box_rounded,
                            size: 14,
                            color: AppColors.primaryRed,
                            key: ValueKey('checked'),
                          )
                        : const Icon(
                            Icons.check_box_outline_blank_rounded,
                            size: 14,
                            color: Color(0xFFBBBBBB),
                            key: ValueKey('unchecked'),
                          ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cat.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primaryRed
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
