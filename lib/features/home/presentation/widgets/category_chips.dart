import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/home_cubit.dart';
import 'shimmer_card.dart';

class CategoryChips extends StatelessWidget {
  final HomeState state;

  const CategoryChips({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.categoriesStatus == LoadStatus.loading ||
        state.categoriesStatus == LoadStatus.initial;

    if (isLoading) {
      return SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: ShimmerCard(
              width: 80,
              height: 36,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }

    final categories = state.categories;
    final selected = state.selectedCategoryName;

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'Tất cả' : categories[index - 1].name;
          final categoryName = isAll ? '' : categories[index - 1].name;
          final isActive = selected == categoryName;

          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () =>
                  context.read<HomeCubit>().selectCategory(categoryName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryRed : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primaryRed
                        : const Color(0xFFE0E0E0),
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textGrey,
                    ),
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
