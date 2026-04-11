import 'package:flutter/material.dart';
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
    final isLoading =
        state.productsStatus == LoadStatus.loading ||
        state.productsStatus == LoadStatus.initial;
    final products = state.filteredProducts;

    return FadeInSection(
      delay: const Duration(milliseconds: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Tất cả sản phẩm', onSeeAll: () {}),
          if (isLoading)
            _buildShimmerGrid()
          else if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Không có sản phẩm nào.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => ProductCard(product: products[i]),
            ),
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
        childAspectRatio: 0.70,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => ShimmerCard(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
