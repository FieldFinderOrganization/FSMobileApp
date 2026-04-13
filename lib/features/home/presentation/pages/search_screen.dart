import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../../pitch/presentation/pages/pitch_detail_screen.dart';
import '../../../pitch/presentation/widgets/filter_sheet.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../cubit/home_cubit.dart';

enum SearchMode { product, pitch }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  SearchMode _mode = SearchMode.pitch;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value.trim();
    });
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
    final content = BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final resultsPitches = _getFilteredPitches(state);
        final productsResults = _getFilteredProducts(state.products);

        return Column(
          children: [
            _buildSearchBar(state),
            const SizedBox(height: 12),
            _buildModeToggle(),
            Expanded(
              child: _mode == SearchMode.pitch
                  ? _buildPitchList(resultsPitches)
                  : _buildProductList(productsResults),
            ),
          ],
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: content),
    );
  }

  List<PitchEntity> _getFilteredPitches(HomeState state) {
    final normalizedQuery = StringUtils.removeDiacritics(_query.toLowerCase());
    return state.searchFilteredPitches.where((p) {
      if (_query.isEmpty) return true;
      final name = StringUtils.removeDiacritics(p.name.toLowerCase());
      final type = StringUtils.removeDiacritics(p.displayType.toLowerCase());
      return name.contains(normalizedQuery) || type.contains(normalizedQuery);
    }).toList();
  }

  List<ProductEntity> _getFilteredProducts(List<ProductEntity> products) {
    if (_query.isEmpty) return products;
    final normalizedQuery = StringUtils.removeDiacritics(_query.toLowerCase());
    return products.where((p) {
      final name = StringUtils.removeDiacritics(p.name.toLowerCase());
      return name.contains(normalizedQuery);
    }).toList();
  }

  Widget _buildSearchBar(HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),

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
                      autofocus: true,
                      onChanged: _onQueryChanged,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _mode == SearchMode.pitch
                            ? 'Tìm sân bóng, loại sân...'
                            : 'Tìm sản phẩm...',
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
          if (_mode == SearchMode.pitch) ...[
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
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _modeChip('Sân bóng', SearchMode.pitch),
          const SizedBox(width: 8),
          _modeChip('Sản phẩm', SearchMode.product),
        ],
      ),
    );
  }

  Widget _modeChip(String label, SearchMode mode) {
    final isSel = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AppColors.textDark : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? AppColors.textDark : const Color(0xFFEEEEEE),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
            color: isSel ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildPitchList(List<PitchEntity> pitches) {
    if (pitches.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pitches.length,
      itemBuilder: (context, index) => _PitchCard(pitch: pitches[index]),
    );
  }

  Widget _buildProductList(List<ProductEntity> products) {
    if (products.isEmpty) return _buildEmptyState();
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _ProductCard(product: products[index]),
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
            'Không tìm thấy kết quả nào',
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: pitch.primaryImage.isNotEmpty
                  ? Image.network(
                      pitch.primaryImage,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pitch.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
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

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(product.price),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
}
