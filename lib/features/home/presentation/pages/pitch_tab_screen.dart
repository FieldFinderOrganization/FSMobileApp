import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../cubit/home_cubit.dart';

/// Tab "Sân" độc lập — tự fetch data qua HomeCubit riêng,
/// không cần data truyền từ ngoài vào. Dùng trong [MainShell] IndexedStack.
class PitchTabScreen extends StatelessWidget {
  const PitchTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dioClient = DioClient(tokenStorage);
    final datasource = HomeRemoteDatasource(dioClient.dio);
    final repository = HomeRepositoryImpl(datasource);

    return BlocProvider(
      create: (_) => HomeCubit(repository: repository)..loadAll(),
      child: const _PitchTabBody(),
    );
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

  String _query = '';
  String _selectedDistrict = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value.trim();
      if (value.isEmpty) _selectedDistrict = '';
    });
    if (value.isNotEmpty) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  List<PitchEntity> _filteredPitches(List<PitchEntity> pitches) {
    if (_query.isEmpty) return pitches; // show all khi chưa search
    final q = _query.toLowerCase();
    var result = pitches.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.displayType.toLowerCase().contains(q) ||
        p.environment.toLowerCase().contains(q) ||
        p.address.toLowerCase().contains(q)).toList();
    if (_selectedDistrict.isNotEmpty) {
      result = result.where((p) => p.district == _selectedDistrict).toList();
    }
    return result;
  }

  List<ProductEntity> _filteredProducts(List<ProductEntity> products) {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return products.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.brand.toLowerCase().contains(q) ||
        p.categoryName.toLowerCase().contains(q)).toList();
  }

  List<String> _availableDistricts(List<PitchEntity> pitches) {
    final base = _query.isEmpty
        ? pitches
        : pitches.where((p) {
            final q = _query.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.displayType.toLowerCase().contains(q) ||
                p.environment.toLowerCase().contains(q) ||
                p.address.toLowerCase().contains(q);
          });
    final districts = base
        .map((p) => p.district)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return districts;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final pitches = _filteredPitches(state.pitches);
        final products = _filteredProducts(state.products);
        final districts = _availableDistricts(state.pitches);

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                _buildHeader(context, state),

                // ── Search bar ─────────────────────────────────────────────
                _buildSearchBar(),

                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // ── District chips ─────────────────────────────────────────
                if (districts.isNotEmpty) _buildDistrictBar(districts),

                // ── Content ────────────────────────────────────────────────
                Expanded(
                  child: _buildContent(
                    context,
                    state,
                    pitches,
                    products,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tìm sân',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '${state.pitches.length} sân có sẵn',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          if (state.pitchesStatus == LoadStatus.loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryRed,
              ),
            )
          else
            IconButton(
              onPressed: () => context.read<HomeCubit>().refresh(),
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.textGrey, size: 22),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _controller,
          onChanged: _onQueryChanged,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Tìm tên sân, khu vực, loại sân...',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFBBBBBB),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFBBBBBB),
              size: 20,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        size: 18, color: Color(0xFFAAAAAA)),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictBar(List<String> districts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: districts.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _DistrictChip(
                  label: 'Tất cả',
                  isActive: _selectedDistrict.isEmpty,
                  onTap: () => setState(() => _selectedDistrict = ''),
                );
              }
              final d = districts[i - 1];
              return _DistrictChip(
                label: d,
                isActive: _selectedDistrict == d,
                onTap: () => setState(() {
                  _selectedDistrict = _selectedDistrict == d ? '' : d;
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    HomeState state,
    List<PitchEntity> pitches,
    List<ProductEntity> products,
  ) {
    if (state.pitchesStatus == LoadStatus.loading && state.pitches.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryRed,
          strokeWidth: 2.5,
        ),
      );
    }

    if (state.pitchesStatus == LoadStatus.failure && state.pitches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Không thể tải dữ liệu',
              style: GoogleFonts.inter(
                  fontSize: 15, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<HomeCubit>().refresh(),
              child: const Text('Thử lại',
                  style: TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        ),
      );
    }

    if (pitches.isEmpty && _query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 72, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy sân',
              style: GoogleFonts.inter(
                  fontSize: 15, color: Colors.grey[400]),
            ),
            const SizedBox(height: 6),
            Text(
              'Thử tìm với từ khoá khác',
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.grey[350]),
            ),
          ],
        ),
      );
    }

    // Hiện tất cả sân (có filter district/query)
    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: pitches.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 80, color: Color(0xFFF0F0F0)),
        itemBuilder: (_, i) => _PitchListItem(pitch: pitches[i]),
      ),
    );
  }
}

// ── District Chip ────────────────────────────────────────────────────────────

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
        duration: const Duration(milliseconds: 180),
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

// ── Pitch List Item ──────────────────────────────────────────────────────────

class _PitchListItem extends StatelessWidget {
  final PitchEntity pitch;

  const _PitchListItem({required this.pitch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: pitch.primaryImage.isNotEmpty
                ? Image.network(
                    pitch.primaryImage,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pitch.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${pitch.displayType} · ${pitch.environment}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
                if (pitch.district.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textGrey),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          pitch.district,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${pitch.price.toStringAsFixed(0)}k/h',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 64,
        height: 64,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.sports_soccer, color: Colors.grey, size: 24),
      );
}
