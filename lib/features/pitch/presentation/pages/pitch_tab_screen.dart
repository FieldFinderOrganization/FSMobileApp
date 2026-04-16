import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../widgets/filter_sheet.dart';
import 'pitch_detail_screen.dart';

class PitchTabScreen extends StatelessWidget {
  const PitchTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PitchTabBody();
  }
}

class _PitchTabBody extends StatefulWidget {
  const _PitchTabBody();

  @override
  State<_PitchTabBody> createState() => _PitchTabBodyState();
}

class _PitchTabBodyState extends State<_PitchTabBody>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animController;
  late final ScrollController _scrollController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HomeCubit>().loadNextPagePitches();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value.trim();
    });
    if (value.isNotEmpty) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _showFilterSheet() {
    final cubit = context.read<HomeCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        selectedType: cubit.state.selectedPitchType,
        priceSortOrder: cubit.state.pitchSortOrder,
        onApply: (type, sort) {
          cubit.updatePitchFilters(type: type, sort: sort);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          final pitches = _getFilteredPitches(state);

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(state),
                Expanded(
                  child: pitches.isEmpty &&
                          state.pitchesStatus != LoadStatus.loading
                      ? _buildEmptyState()
                      : _buildPitchList(pitches, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PitchEntity> _getFilteredPitches(HomeState state) {
    final normalizedQuery = StringUtils.removeDiacritics(_query.toLowerCase());
    // Since we now have server-side filtering for district and type, 
    // we only do client-side filtering for the search query here.
    return state.pitches.where((p) {
      if (_query.isEmpty) return true;
      final name = StringUtils.removeDiacritics(p.name.toLowerCase());
      final type = StringUtils.removeDiacritics(p.displayType.toLowerCase());
      return name.contains(normalizedQuery) || type.contains(normalizedQuery);
    }).toList();
  }

  Widget _buildHeader(HomeState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: _onQueryChanged,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm sân bóng...',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _controller.clear();
                            _onQueryChanged('');
                          },
                          child: const Icon(
                            Icons.cancel_rounded,
                            color: AppColors.textGrey,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (state.selectedPitchType.isNotEmpty ||
                            state.pitchSortOrder != 'none')
                        ? AppColors.primaryRed.withValues(alpha: 0.1)
                        : const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (state.selectedPitchType.isNotEmpty ||
                              state.pitchSortOrder != 'none')
                          ? AppColors.primaryRed.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: (state.selectedPitchType.isNotEmpty ||
                            state.pitchSortOrder != 'none')
                        ? AppColors.primaryRed
                        : AppColors.textGrey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDistrictBar(state),
        ],
      ),
    );
  }

  Widget _buildDistrictBar(HomeState state) {
    // Note: getActiveDistricts should now probably pull from all loaded data or a separate list.
    // For now, keep it as is if it's still useful.
    final activeDistricts = state.getActiveDistricts(_query);
    final districts = ['Tất cả', ...activeDistricts];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: districts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = districts[i];
          final isSel = (d == 'Tất cả' && state.selectedDistrict.isEmpty) ||
              (d == state.selectedDistrict);

          return GestureDetector(
            onTap: () => context.read<HomeCubit>().selectDistrict(
                  d == 'Tất cả' ? '' : d,
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? AppColors.primaryRed : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? AppColors.primaryRed : const Color(0xFFEEEEEE),
                ),
              ),
              child: Text(
                d,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                  color: isSel ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPitchList(List<PitchEntity> pitches, HomeState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: pitches.length + (state.pitchesHasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < pitches.length) {
          return _PitchCard(pitch: pitches[index]);
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryRed,
                strokeWidth: 2,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy sân nào phù hợp',
            style: GoogleFonts.inter(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _PitchCard extends StatelessWidget {
  final PitchEntity pitch;
  const _PitchCard({required this.pitch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PitchDetailScreen(pitch: pitch)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                pitch.primaryImage,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pitch.displayType,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                      Text(
                        '${pitch.price.toStringAsFixed(0)}k/h',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pitch.name,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pitch.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 180,
    width: double.infinity,
    color: const Color(0xFFF5F5F5),
    child: const Icon(Icons.sports_soccer, color: Colors.grey, size: 48),
  );
}
