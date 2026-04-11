import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/pitch_entity.dart';

enum SearchMode { product, pitch }

class SearchScreen extends StatefulWidget {
  final List<ProductEntity> products;
  final List<PitchEntity> pitches;

  const SearchScreen({
    super.key,
    required this.products,
    required this.pitches,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  SearchMode _mode = SearchMode.product;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
    if (value.isNotEmpty) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  List<ProductEntity> get _filteredProducts {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return widget.products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q))
        .toList();
  }

  List<PitchEntity> get _filteredPitches {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return widget.pitches
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.type.toLowerCase().contains(q) ||
            p.environment.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: _onQueryChanged,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: _mode == SearchMode.product
                              ? 'Tìm sản phẩm, thương hiệu...'
                              : 'Tìm tên sân, loại sân...',
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
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    _onQueryChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Mode toggle ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ModeChip(
                    label: 'Sản phẩm',
                    icon: Icons.shopping_bag_outlined,
                    isActive: _mode == SearchMode.product,
                    onTap: () => setState(() => _mode = SearchMode.product),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: 'Sân',
                    icon: Icons.sports_soccer_rounded,
                    isActive: _mode == SearchMode.pitch,
                    onTap: () => setState(() => _mode = SearchMode.pitch),
                  ),
                  const Spacer(),
                  // Số kết quả
                  if (_query.isNotEmpty)
                    Text(
                      '${_mode == SearchMode.product ? _filteredProducts.length : _filteredPitches.length} kết quả',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Results ───────────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _query.isEmpty
                    ? _buildEmptyHint(key: const ValueKey('hint'))
                    : _mode == SearchMode.product
                        ? _buildProductResults(key: const ValueKey('products'))
                        : _buildPitchResults(key: const ValueKey('pitches')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 72, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Nhập tên để tìm kiếm',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _mode == SearchMode.product
                ? 'Tìm theo tên sản phẩm hoặc thương hiệu'
                : 'Tìm theo tên sân hoặc loại sân',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[350]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductResults({Key? key}) {
    final results = _filteredProducts;
    if (results.isEmpty) {
      return _buildNoResult(key: key);
    }
    return FadeTransition(
      key: key,
      opacity: _fadeAnim,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: results.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 80, color: Color(0xFFF0F0F0)),
        itemBuilder: (_, i) => _ProductResultItem(product: results[i]),
      ),
    );
  }

  Widget _buildPitchResults({Key? key}) {
    final results = _filteredPitches;
    if (results.isEmpty) {
      return _buildNoResult(key: key);
    }
    return FadeTransition(
      key: key,
      opacity: _fadeAnim,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: results.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 80, color: Color(0xFFF0F0F0)),
        itemBuilder: (_, i) => _PitchResultItem(pitch: results[i]),
      ),
    );
  }

  Widget _buildNoResult({Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy kết quả',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[400]),
          ),
          const SizedBox(height: 6),
          Text(
            'Thử với từ khoá khác',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[350]),
          ),
        ],
      ),
    );
  }
}

// ── Mode chip ────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryRed : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product result item ──────────────────────────────────────────────────────

class _ProductResultItem extends StatelessWidget {
  final ProductEntity product;

  const _ProductResultItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    width: 60,
                    height: 60,
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
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (product.brand.isNotEmpty) product.brand,
                    if (product.sex.isNotEmpty) product.sex,
                  ].join(' · '),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (product.isOnSale && product.salePrice != null) ...[
                Text(
                  '${_fmt(product.price)}đ',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  '${_fmt(product.salePrice!)}đ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
              ] else
                Text(
                  '${_fmt(product.price)}đ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 60,
        height: 60,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.image_not_supported,
            color: Colors.grey, size: 24),
      );

  String _fmt(double price) {
    // Format số: 1000000 → 1.000.000
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }
}

// ── Pitch result item ────────────────────────────────────────────────────────

class _PitchResultItem extends StatelessWidget {
  final PitchEntity pitch;

  const _PitchResultItem({required this.pitch});

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
                    width: 60,
                    height: 60,
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
                const SizedBox(height: 2),
                Text(
                  '${pitch.type} · ${pitch.environment}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Price
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        width: 60,
        height: 60,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.sports_soccer,
            color: Colors.grey, size: 24),
      );
}
