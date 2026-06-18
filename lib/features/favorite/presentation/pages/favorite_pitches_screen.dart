import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../../pitch/presentation/pages/pitch_detail_screen.dart';
import '../cubit/favorite_cubit.dart';
import '../cubit/favorite_state.dart';
import '../widgets/favorite_heart_button.dart';

/// Màn "Sân yêu thích". Dùng FavoriteCubit global (đã provide ở main.dart),
/// chỉ nạp danh sách khi mở.
class FavoritePitchesScreen extends StatefulWidget {
  const FavoritePitchesScreen({super.key});

  @override
  State<FavoritePitchesScreen> createState() => _FavoritePitchesScreenState();
}

class _FavoritePitchesScreenState extends State<FavoritePitchesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FavoriteCubit>().loadPitches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Sân yêu thích',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FavoriteErrorListener(
        child: BlocBuilder<FavoriteCubit, FavoriteState>(
          builder: (context, state) {
            switch (state.status) {
              case FavoriteListStatus.loading:
              case FavoriteListStatus.initial:
                return _buildSkeleton();
              case FavoriteListStatus.failure:
                return _buildError(context);
              case FavoriteListStatus.success:
                if (state.pitches.isEmpty) return _buildEmpty();
                return RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: () =>
                      context.read<FavoriteCubit>().loadPitches(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.pitches.length,
                    itemBuilder: (_, i) =>
                        _FavoritePitchCard(pitch: state.pitches[i]),
                  ),
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có sân yêu thích nào',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bấm ❤ trên sân để lưu vào đây',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 14),
          Text(
            'Không tải được danh sách',
            style: GoogleFonts.inter(color: AppColors.textGrey),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<FavoriteCubit>().loadPitches(),
            child: Text(
              'Thử lại',
              style: GoogleFonts.inter(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritePitchCard extends StatelessWidget {
  final PitchEntity pitch;
  const _FavoritePitchCard({required this.pitch});

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
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    pitch.primaryImage,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: const Color(0xFFEFEFEF),
                      child: Icon(Icons.sports_soccer_rounded,
                          size: 48, color: Colors.grey[400]),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FavoriteHeartButton(pitchId: pitch.pitchId),
                ),
              ],
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
                            horizontal: 8, vertical: 4),
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
                        '${formatVnd(pitch.price)}/giờ',
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
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  if (pitch.address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pitch.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 12.5, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
