import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../../home/presentation/widgets/shimmer_card.dart';
import '../../data/models/product_model.dart';
import '../pages/product_detail_screen.dart';

/// "Gợi ý cho bạn" — feed cá nhân hóa (SASRec; cold-start ⇒ bán chạy). Tự fetch /products/for-you.
class ForYouSection extends StatefulWidget {
  const ForYouSection({super.key});

  @override
  State<ForYouSection> createState() => _ForYouSectionState();
}

class _ForYouSectionState extends State<ForYouSection> {
  bool _loading = true;
  List<ProductModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context
          .read<DioClient>()
          .dio
          .get('/products/for-you', queryParameters: {'limit': 10});
      final data = res.data as List<dynamic>;
      final items =
          data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _items = const []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _items.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Gợi ý cho bạn', onSeeAll: null, darkMode: false),
          SizedBox(
            height: 196,
            child: _loading
                ? _shimmer()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _card(_items[i]),
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _shimmer() => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) => ShimmerCard(
          width: 128,
          height: 196,
          borderRadius: BorderRadius.circular(12),
        ),
      );

  Widget _card(ProductModel p) {
    final price = (p.salePrice != null && p.salePrice! > 0) ? p.salePrice! : p.price;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
      ),
      child: Container(
        width: 128,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: p.imageUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Icon(Icons.image, color: Colors.grey))
                    : CachedNetworkImage(
                        imageUrl: ImageUrl.thumbnail(p.imageUrl, width: 300),
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        errorWidget: (_, _, _) => Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatVnd(price),
                    style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryRed),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
