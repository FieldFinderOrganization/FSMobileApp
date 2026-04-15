import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';

class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Sắp xếp theo giá'),
              const SizedBox(height: 12),
              _buildSortFilter(context, state),
              const SizedBox(height: 24),
              _buildSectionTitle('Thương hiệu'),
              const SizedBox(height: 12),
              _buildBrandFilter(context, state),
              const SizedBox(height: 24),
              _buildSectionTitle('Khoảng giá'),
              const SizedBox(height: 12),
              _buildPriceFilter(context, state),
              const SizedBox(height: 32),
              _buildApplyButton(context),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bộ lọc',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        TextButton(
          onPressed: () => context.read<ProductCubit>().clearFilters(),
          child: Text(
            'Thiết lập lại',
            style: GoogleFonts.inter(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildSortFilter(BuildContext context, ProductState state) {
    const options = [
      (label: 'Mặc định', icon: Icons.sort_rounded, value: SortOption.none),
      (label: 'Giá thấp → cao', icon: Icons.arrow_upward_rounded, value: SortOption.priceAsc),
      (label: 'Giá cao → thấp', icon: Icons.arrow_downward_rounded, value: SortOption.priceDesc),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = state.sortOption == opt.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => context.read<ProductCubit>().setSortOption(opt.value),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryRed : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primaryRed : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    opt.icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.textGrey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBrandFilter(BuildContext context, ProductState state) {
    final brands = state.allBrands;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: brands.map((brand) {
        final isSelected = state.selectedBrands.contains(brand);
        return GestureDetector(
          onTap: () => context.read<ProductCubit>().toggleBrand(brand),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textDark : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.textDark : Colors.transparent,
              ),
            ),
            child: Text(
              brand,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceFilter(BuildContext context, ProductState state) {
    final maxPrice = state.maxPriceInList;
    return Column(
      children: [
        RangeSlider(
          values: state.priceRange,
          min: 0,
          max: maxPrice,
          divisions: 20,
          activeColor: AppColors.primaryRed,
          inactiveColor: const Color(0xFFF0F0F0),
          labels: RangeLabels(
            '${state.priceRange.start.toStringAsFixed(0)}k',
            '${state.priceRange.end.toStringAsFixed(0)}k',
          ),
          onChanged: (values) =>
              context.read<ProductCubit>().updatePriceRange(values),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0k',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
              Text(
                '${maxPrice.toStringAsFixed(0)}k',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Áp dụng',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
