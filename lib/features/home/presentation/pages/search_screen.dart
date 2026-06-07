import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../../pitch/presentation/pages/pitch_detail_screen.dart';
import '../../../pitch/presentation/widgets/filter_sheet.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/presentation/pages/product_detail_screen.dart';
import '../../data/datasources/search_history_remote_datasource.dart';
import '../../domain/entities/search_history_entity.dart';
import '../cubit/home_cubit.dart';
import '../cubit/search_history_cubit.dart';
import 'search_history_screen.dart';
import '../../../../shared/widgets/voice_input_button.dart';

enum SearchMode { product, pitch }

class SearchScreen extends StatelessWidget {
  final SearchMode initialMode;

  const SearchScreen({super.key, this.initialMode = SearchMode.pitch});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final dioClient = ctx.read<DioClient>();
        return SearchHistoryCubit(SearchHistoryRemoteDatasource(dioClient.dio))
          ..load();
      },
      child: _SearchScreenBody(initialMode: initialMode),
    );
  }
}

class _SearchScreenBody extends StatefulWidget {
  final SearchMode initialMode;
  const _SearchScreenBody({required this.initialMode});

  @override
  State<_SearchScreenBody> createState() => _SearchScreenBodyState();
}

class _SearchScreenBodyState extends State<_SearchScreenBody> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  late SearchMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value.trim();
    });
    // Sản phẩm: tìm trên toàn DB qua server (debounce trong cubit).
    // Sân: vẫn lọc client-side trên danh sách đã tải (giữ nguyên hành vi cũ).
    if (_mode == SearchMode.product) {
      context.read<HomeCubit>().searchProducts(_query);
    }
  }

  void _commitSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    context.read<SearchHistoryCubit>().add(trimmed);
  }

  void _useKeyword(String keyword) {
    _controller.text = keyword;
    _controller.selection =
        TextSelection.fromPosition(TextPosition(offset: keyword.length));
    _onQueryChanged(keyword);
    _commitSearch(keyword);
    _focusNode.unfocus();
  }

  Future<void> _openHistoryPage() async {
    final cubit = context.read<SearchHistoryCubit>();
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const SearchHistoryScreen(),
        ),
      ),
    );
    if (picked != null && picked.isNotEmpty) {
      _useKeyword(picked);
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
    final content = BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final resultsPitches = _getFilteredPitches(state);
        final productsResults = _getProductResults(state);

        return Column(
          children: [
            _buildSearchBar(state),
            const SizedBox(height: 12),
            if (_query.isEmpty) ...[
              _buildRecentKeywords(),
            ] else
              _buildAutocomplete(state, resultsPitches, productsResults),
            const SizedBox(height: 12),
            Expanded(
              child: _mode == SearchMode.pitch
                  ? _buildPitchList(resultsPitches)
                  : _buildProductSection(state, productsResults),
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

  /// Query rỗng: hiển thị danh sách đã tải (browse). Có query: dùng kết quả
  /// search server-side trên toàn DB (`state.searchProducts`).
  List<ProductEntity> _getProductResults(HomeState state) {
    if (_query.isEmpty) return state.products;
    return state.searchProducts;
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
                      focusNode: _focusNode,
                      autofocus: true,
                      onChanged: _onQueryChanged,
                      onSubmitted: (value) {
                        _commitSearch(value);
                      },
                      textInputAction: TextInputAction.search,
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
                  VoiceInputButton(
                    size: 20,
                    onResult: _useKeyword,
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

  Widget _buildRecentKeywords() {
    return BlocBuilder<SearchHistoryCubit, SearchHistoryState>(
      builder: (context, hState) {
        if (hState.items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm gần đây',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openHistoryPage,
                    child: Text(
                      'Xem tất cả',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hState.items
                    .map((item) => _recentChip(context, item))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _recentChip(BuildContext context, SearchHistoryEntity item) {
    return GestureDetector(
      onTap: () => _useKeyword(item.keyword),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 14, color: AppColors.textGrey),
            const SizedBox(width: 6),
            Text(
              item.keyword,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () =>
                  context.read<SearchHistoryCubit>().remove(item.id),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocomplete(
    HomeState state,
    List<PitchEntity> pitches,
    List<ProductEntity> products,
  ) {
    final normalizedQuery = StringUtils.removeDiacritics(_query.toLowerCase());
    final hCubit = context.read<SearchHistoryCubit>();
    final recentMatches = hCubit.state.items
        .where((e) => StringUtils.removeDiacritics(e.keyword.toLowerCase())
            .startsWith(normalizedQuery))
        .take(5)
        .map((e) => e.keyword)
        .toList();
    // Gợi ý theo đúng mode của tab: Sân → tên sân, Sản phẩm → tên sản phẩm.
    final Iterable<String> names = _mode == SearchMode.pitch
        ? pitches.map((p) => p.name)
        : products.map((p) => p.name);
    final nameMatches = names
        .where((n) =>
            StringUtils.removeDiacritics(n.toLowerCase())
                .contains(normalizedQuery))
        .toSet()
        .take(5)
        .toList();

    final suggestions = <String>{
      ...recentMatches,
      ...nameMatches,
    }.toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            for (final s in suggestions)
              InkWell(
                onTap: () => _useKeyword(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          size: 16, color: AppColors.textGrey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: GoogleFonts.inter(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.north_west_rounded,
                          size: 14, color: AppColors.textGrey),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchList(List<PitchEntity> pitches) {
    if (pitches.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pitches.length,
      itemBuilder: (context, index) => _PitchCard(
        pitch: pitches[index],
        onTap: () => _commitSearch(_query),
      ),
    );
  }

  Widget _buildProductSection(HomeState state, List<ProductEntity> products) {
    // Đang tìm trên server cho từ khóa hiện tại → hiện loading.
    if (_query.isNotEmpty &&
        state.searchProductsStatus == LoadStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }
    return _buildProductList(products);
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
      itemBuilder: (context, index) => _ProductCard(
        product: products[index],
        onTap: () => _commitSearch(_query),
      ),
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
  final VoidCallback? onTap;
  const _PitchCard({required this.pitch, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PitchDetailScreen(pitch: pitch)),
        );
      },
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
  final VoidCallback? onTap;
  const _ProductCard({required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
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
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF5F5F5),
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
}
