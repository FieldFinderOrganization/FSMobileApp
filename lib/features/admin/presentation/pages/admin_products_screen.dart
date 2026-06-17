import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../../product/data/models/product_model.dart';

/// Danh sách sản phẩm cho admin — tự chứa, phân trang cục bộ qua
/// [AdminStatisticsDatasource.getProducts] (GET /products). Theo pattern các
/// màn admin khác: StatefulWidget nhận datasource, không cubit mới.
class AdminProductsScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminProductsScreen({super.key, required this.datasource});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  static const _kBackground = Color(0xFFF8F9FC);
  static const _pageSize = 20;

  final _scrollController = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  final List<ProductModel> _items = [];
  int _page = 0;
  bool _last = false;
  int _total = 0;
  String _search = '';

  bool _loading = true; // tải trang đầu / reload
  bool _loadingMore = false;
  String? _error;

  final _currency = NumberFormat.decimalPattern('vi_VN');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 0;
        _last = false;
        _items.clear();
      }
    });
    try {
      final data = await widget.datasource.getProducts(
        page: 0,
        size: _pageSize,
        search: _search,
      );
      final parsed = _parse(data);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(parsed);
        _page = 0;
        _last = (data['last'] as bool?) ?? (parsed.length < _pageSize);
        _total = (data['totalElements'] as num?)?.toInt() ?? parsed.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tải được danh sách sản phẩm';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _last) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final data = await widget.datasource.getProducts(
        page: next,
        size: _pageSize,
        search: _search,
      );
      final parsed = _parse(data);
      if (!mounted) return;
      setState(() {
        _items.addAll(parsed);
        _page = next;
        _last = (data['last'] as bool?) ?? (parsed.length < _pageSize);
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  List<ProductModel> _parse(Map<String, dynamic> data) {
    final content = (data['content'] as List<dynamic>?) ?? const [];
    return content
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value.trim();
      _load(reset: true);
    });
  }

  String _formatPrice(double v) => '${_currency.format(v)}đ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          'Sản phẩm',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (!_loading && _error == null) _buildTotalLine(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tìm sản phẩm theo tên...',
            hintStyle: GoogleFonts.inter(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      _onSearchChanged('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalLine() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Tổng $_total sản phẩm',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.inter(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              onPressed: () => _load(reset: true),
              child: Text(
                'Thử lại',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sản phẩm nào',
              style: GoogleFonts.inter(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryRed,
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryRed,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          return _buildProductRow(_items[i]);
        },
      ),
    );
  }

  Widget _buildProductRow(ProductModel p) {
    final onSale = p.salePrice != null && p.salePrice! < p.price;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: p.imageUrl.isNotEmpty
                ? Image.network(
                    p.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (p.brand.isNotEmpty) p.brand,
                    if (p.categoryName.isNotEmpty) p.categoryName,
                  ].join(' · '),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã bán: ${p.totalSold}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(onSale ? p.salePrice! : p.price),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                ),
              ),
              if (onSale) ...[
                const SizedBox(height: 2),
                Text(
                  _formatPrice(p.price),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }
}
