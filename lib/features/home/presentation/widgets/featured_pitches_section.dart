import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'fade_in_section.dart';
import 'pitch_card.dart';
import 'section_header.dart';
import 'shimmer_card.dart';

class FeaturedPitchesSection extends StatelessWidget {
  final HomeState state;

  const FeaturedPitchesSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.pitchesStatus == LoadStatus.loading ||
        state.pitchesStatus == LoadStatus.initial;

    return FadeInSection(
      delay: const Duration(milliseconds: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Sân nổi bật', onSeeAll: () {}),
          // ── Pitch list ──────────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: isLoading
                ? _buildShimmer()
                : state.pitches.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 16),
                    itemCount: state.filteredPitches.length,
                    itemBuilder: (_, i) => SizedBox(
                          height: 200,
                          child: PitchCard(pitch: state.filteredPitches[i]),
                        ),
                  ),
          ),
          const SizedBox(height: 12),
          // ── District chip bar ───────────────────────────────────────────
          if (!isLoading && state.availableDistricts.isNotEmpty)
            _DistrictChipBar(
              districts: state.availableDistricts,
              selected: state.selectedDistrict,
              onTap: (d) => context.read<HomeCubit>().selectDistrict(d),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 16),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: ShimmerCard(
          width: 200,
          height: 200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Text('Chưa có sân nào.'));
  }
}

// ── District Chip Bar ─────────────────────────────────────────────────────────

class _DistrictChipBar extends StatelessWidget {
  final List<String> districts;
  final String selected;
  final ValueChanged<String> onTap;

  const _DistrictChipBar({
    required this.districts,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: districts.length + 1, // +1 cho chip "Tất cả"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            // Chip "Tất cả"
            final isActive = selected.isEmpty;
            return _DistrictChip(
              label: 'Tất cả',
              isActive: isActive,
              onTap: () => onTap(''),
            );
          }
          final district = districts[i - 1];
          final isActive = selected == district;
          return _DistrictChip(
            label: district,
            isActive: isActive,
            onTap: () => onTap(district),
          );
        },
      ),
    );
  }
}

class _DistrictChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DistrictChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryRed : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryRed : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
