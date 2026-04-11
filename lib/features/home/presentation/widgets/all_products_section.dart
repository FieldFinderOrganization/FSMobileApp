import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'fade_in_section.dart';
import 'product_card.dart';
import 'section_header.dart';
import 'shimmer_card.dart';

class AllProductsSection extends StatelessWidget {
  final HomeState state;

  const AllProductsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.productsStatus == LoadStatus.loading ||
        state.productsStatus == LoadStatus.initial;

    return FadeInSection(
      delay: const Duration(milliseconds: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Tất cả sản phẩm', onSeeAll: null),

          // ── Danh mục cha ─────────────────────────────────────────────────
          _ParentCategoryChips(state: state),

          // ── Danh mục con (hiện khi cha được chọn và có con) ──────────────
          if (state.subCategories.isNotEmpty) ...[
            const SizedBox(height: 4),
            _SubCategoryChips(state: state),
          ],

          const SizedBox(height: 8),

          // ── Lưới sản phẩm ─────────────────────────────────────────────
          if (isLoading)
            _buildShimmerGrid()
          else if (state.visibleProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Không có sản phẩm nào.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 250,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: state.visibleProducts.length,
              itemBuilder: (_, i) =>
                  ProductCard(product: state.visibleProducts[i]),
            ),
            if (state.hasMoreProducts)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: OutlinedButton(
                  onPressed: () =>
                      context.read<HomeCubit>().loadMoreProducts(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: AppColors.primaryRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Xem thêm',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 250,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => ShimmerCard(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(12),
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
    final isLoading = state.categoriesStatus == LoadStatus.loading ||
        state.categoriesStatus == LoadStatus.initial;

    if (isLoading) {
      return SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: ShimmerCard(
                width: 80,
                height: 36,
                borderRadius: BorderRadius.circular(8)),
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
        itemCount: roots.length + 1, // +1 cho "Tất cả"
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'Tất cả' : roots[index - 1].name;
          final value = isAll ? '' : roots[index - 1].name;
          final isActive = selected == value;
          final hasChildren = isAll
              ? false
              : state.categories
                  .any((c) => c.parentName == roots[index - 1].name);

          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: GestureDetector(
              onTap: () => context.read<HomeCubit>().selectCategory(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                    // Mũi tên nhỏ nếu có danh mục con
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

// ── Danh mục con (multi-select checkboxes) ───────────────────────────────────

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
            onTap: () =>
                context.read<HomeCubit>().toggleSubCategory(cat.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed.withOpacity(0.08)
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
                  // Checkbox icon
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
