import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../widgets/product_card.dart';
import '../widgets/filter_sheet.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          const _ProductContent(),
          
          // Glassmorphism Header
          _buildHeader(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final hasSubCats = state.subCategories.isNotEmpty;
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  bottom: 15,
                  left: 0,
                  right: 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: _buildSearchBar(context)),
                          const SizedBox(width: 12),
                          _buildFilterButton(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    const _RootCategoryRow(),
                    if (hasSubCats) ...[
                      const SizedBox(height: 12),
                      const _SubCategoryRow(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        onChanged: (val) => context.read<ProductCubit>().updateSearchQuery(val),
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm...',
          hintStyle: GoogleFonts.inter(color: AppColors.textGrey, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const FilterSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _RootCategoryRow extends StatelessWidget {
  const _RootCategoryRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final roots = state.rootCategories;
        return SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: roots.length + 1,
            itemBuilder: (context, i) {
              final isAll = i == 0;
              final cat = isAll ? null : roots[i - 1];
              final label = isAll ? 'Tất cả' : cat!.name;
              final isSelected = isAll 
                ? state.selectedCategory.isEmpty 
                : state.selectedCategory == label;
              
              return GestureDetector(
                onTap: () => context.read<ProductCubit>().selectCategory(isAll ? '' : label),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryRed : const Color(0xFFEEEEEE),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SubCategoryRow extends StatelessWidget {
  const _SubCategoryRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        final subs = state.subCategories;
        if (subs.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 32,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: subs.length,
            itemBuilder: (context, i) {
              final sub = subs[i];
              final isSelected = state.selectedSubCategoryNames.contains(sub.name);
              
              return GestureDetector(
                onTap: () => context.read<ProductCubit>().toggleSubCategory(sub.name),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.textDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.textDark : const Color(0xFFF0F0F0),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    sub.name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductContent extends StatelessWidget {
  const _ProductContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state.status == LoadStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        
        if (state.status == LoadStatus.failure) {
          return Center(child: Text(state.errorMessage ?? 'Đã có lỗi xảy ra'));
        }

        final filtered = state.filteredProducts;
        if (filtered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Color(0xFFEEEEEE)),
                SizedBox(height: 16),
                Text('Không tìm thấy sản phẩm nào'),
              ],
            ),
          );
        }

        final hasSubCats = state.subCategories.isNotEmpty;
        final paddingTop = MediaQuery.of(context).padding.top + (hasSubCats ? 190 : 145);

        return GridView.builder(
          padding: EdgeInsets.only(
            top: paddingTop,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) => ProductCard(product: filtered[i]),
        );
      },
    );
  }
}
