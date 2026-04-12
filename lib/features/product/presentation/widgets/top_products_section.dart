import 'package:flutter/material.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../../../home/presentation/widgets/fade_in_section.dart';
import 'product_card.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../../home/presentation/widgets/shimmer_card.dart';

class TopProductsSection extends StatelessWidget {
  final HomeState state;

  const TopProductsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.topProductsStatus == LoadStatus.loading ||
        state.topProductsStatus == LoadStatus.initial;

    return FadeInSection(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Bán chạy nhất', onSeeAll: () {}),
          SizedBox(
            height: 260,
            child: isLoading
                ? _buildShimmer()
                : state.topProducts.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 16),
                    itemCount: state.topProducts.length,
                    itemBuilder: (_, i) => ProductCard(
                      product: state.topProducts[i],
                      mode: ProductCardMode.horizontal,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      itemCount: 4,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: ShimmerCard(
          width: 160,
          height: 260,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
