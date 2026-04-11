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
          // Category filter chips
          _CategoryFilter(state: state),
          const SizedBox(height: 8),
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
                    side:
                        const BorderSide(color: AppColors.primaryRed),
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

class _CategoryFilter extends StatelessWidget {
  final HomeState state;

  const _CategoryFilter({required this.state});

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
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: ShimmerCard(
              width: 70,
              height: 36,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // Lọc bỏ các danh mục bị ẩn
    final categories = state.categories
        .where((c) => !kHiddenCategories.contains(c.name))
        .toList();
    final selected = state.selectedCategoryName;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'Tất cả' : categories[index - 1].name;
          final categoryName = isAll ? '' : categories[index - 1].name;
          final isActive = selected == categoryName;

          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            child: GestureDetector(
              onTap: () =>
                  context.read<HomeCubit>().selectCategory(categoryName),
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
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textGrey,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
