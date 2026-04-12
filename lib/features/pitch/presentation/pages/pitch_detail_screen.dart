import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
// import '../../../../core/storage/token_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/pitch_detail_cubit.dart';
import '../cubit/pitch_detail_state.dart';
import '../../data/datasources/pitch_remote_datasource.dart';
import '../../data/datasources/review_remote_datasource.dart';
import '../../data/repositories/pitch_repository_impl.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/review_entity.dart';
import './booking_screen.dart';

class PitchDetailScreen extends StatefulWidget {
  final PitchEntity pitch;

  const PitchDetailScreen({super.key, required this.pitch});

  @override
  State<PitchDetailScreen> createState() => _PitchDetailScreenState();
}

class _PitchDetailScreenState extends State<PitchDetailScreen>
    with SingleTickerProviderStateMixin {
  late PageController _imagePageController;
  int _currentImagePage = 0;
  DateTime _selectedDate = DateTime.now();

  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // final tokenStorage = context.read<TokenStorage>();
        final dioClient = context.read<DioClient>();
        final pitchDatasource = PitchRemoteDatasource(dioClient.dio);
        final reviewDatasource = ReviewRemoteDatasource(dioClient.dio);
        final repository = PitchRepositoryImpl(
          pitchRemoteDatasource: pitchDatasource,
          reviewRemoteDatasource: reviewDatasource,
        );
        return PitchDetailCubit(repository)
          ..loadPitchDetails(widget.pitch.pitchId);
      },
      child: BlocBuilder<PitchDetailCubit, PitchDetailState>(
        builder: (context, state) {
          if (state is PitchDetailLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            );
          }

          if (state is PitchDetailFailure) {
            return Scaffold(body: Center(child: Text('Lỗi: ${state.message}')));
          }

          final pitch = (state is PitchDetailSuccess)
              ? state.pitch
              : widget.pitch;
          final reviews = (state is PitchDetailSuccess)
              ? state.reviews
              : <ReviewEntity>[];
          final images = pitch.imageUrls.isNotEmpty ? pitch.imageUrls : [''];

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // ── Main scrollable content ──────────────────────────────────────
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Image Gallery SliverAppBar ───────────────────────────────
                    _buildImageAppBar(images),

                    // ── Body ────────────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Pitch Info ─────────────────────────────────────────
                          _buildPitchInfo(pitch, reviews),

                          const _SectionDivider(),

                          // ── Day Picker ─────────────────────────────────────────
                          _buildDayPicker(),

                          const _SectionDivider(),

                          // ── Pitch Price Info ───────────────────────────────────
                          _buildPitchPriceInfo(pitch),

                          const _SectionDivider(),

                          // ── More Images ────────────────────────────────────────
                          if (images.length > 1) _buildImageGrid(images),

                          if (images.length > 1) const _SectionDivider(),

                          // ── Reviews ───────────────────────────────────────────
                          _buildReviews(reviews),

                          // Bottom padding for FAB
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Back button ──────────────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: _CircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),

                // ── Share button ─────────────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: _CircleButton(
                    icon: Icons.share_outlined,
                    onTap: () {},
                  ),
                ),

                // ── Booking FAB ──────────────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBookingBar(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Image App Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildImageAppBar(List<String> images) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 300,
      pinned: false,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // PageView of images
            PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentImagePage = i),
              itemBuilder: (_, i) {
                final url = images[i];
                return url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder();
              },
            ),
            // Bottom gradient
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Image indicator dots
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImagePage == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentImagePage == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2c2c2c), Color(0xFF1a1a1a)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_soccer, size: 64, color: Colors.white24),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pitch Info
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPitchInfo(PitchEntity pitch, List<ReviewEntity> reviews) {
    double avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + rating row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  pitch.name,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Star rating badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      avg.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      ' (${reviews.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Type + environment chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.sports_soccer_rounded,
                label: pitch.displayType,
                color: AppColors.primaryRed,
              ),
              _InfoChip(
                icon: Icons.nature_outlined,
                label: pitch.environment,
                color: const Color(0xFF2E7D32),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Address
          if (pitch.address.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pitch.address,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 14),

          // Description
          if (pitch.description.isNotEmpty) ...[
            Text(
              'Mô tả',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            _ExpandableText(text: pitch.description),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Day Picker
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDayPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                'Chọn ngày',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (_, i) {
                final date = DateTime.now().add(Duration(days: i));
                final isSelected = _isSameDay(date, _selectedDate);
                final isToday = _isSameDay(date, DateTime.now());
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    margin: EdgeInsets.only(right: 10, left: i == 0 ? 0 : 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryRed
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryRed
                            : isToday
                            ? AppColors.primaryRed.withValues(alpha: 0.3)
                            : const Color(0xFFEEEEEE),
                        width: isToday && !isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _dayOfWeekShort(date.weekday),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Th${date.month}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: isSelected
                                ? Colors.white60
                                : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ngày đã chọn: ${_formatDate(_selectedDate)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayOfWeekShort(int weekday) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[weekday - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pitch Types & Pricing
  // ─────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────
  // Pitch Price Info
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPitchPriceInfo(PitchEntity pitch) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 18,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                'Thông tin giá',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_soccer_rounded,
                    color: AppColors.primaryRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pitch.displayType,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Giá thuê cố định',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${pitch.price.toStringAsFixed(0)}k/h',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Image Grid
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildImageGrid(List<String> images) {
    final displayImages = images.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                'Hình ảnh sân',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${images.length} ảnh',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: displayImages.length,
            itemBuilder: (_, i) {
              final url = displayImages[i];
              final isLast = i == 5 && images.length > 6;
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    url.isNotEmpty
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: const Color(0xFFEEEEEE)),
                          )
                        : Container(color: const Color(0xFFEEEEEE)),
                    if (isLast)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            '+${images.length - 5}',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reviews
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildReviews(List<ReviewEntity> reviews) {
    double avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 18,
                color: AppColors.primaryRed,
              ),
              const SizedBox(width: 8),
              Text(
                'Đánh giá',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              // Average
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFFFB300),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    avg.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    ' / 5.0',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Rating summary bar
          _buildRatingSummary(reviews),

          const SizedBox(height: 16),

          // Individual reviews
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có đánh giá nào',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            )
          else
            ...reviews.map((r) => _buildReviewCard(r)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(List<ReviewEntity> reviews) {
    final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      if (counts.containsKey(r.rating)) {
        counts[r.rating] = (counts[r.rating] ?? 0) + 1;
      }
    }
    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = counts[star] ?? 0;
        final fraction = reviews.isEmpty ? 0.0 : count / reviews.length;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$star',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.star_rounded,
                size: 10,
                color: Color(0xFFFFB300),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFB300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewCard(ReviewEntity review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              review.userImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.network(
                        review.userImageUrl!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildLetterAvatar(review.userName),
                      ),
                    )
                  : _buildLetterAvatar(review.userName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < review.rating
                        ? const Color(0xFFFFB300)
                        : const Color(0xFFEEEEEE),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF444444),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterAvatar(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed,
            AppColors.primaryRed.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────────
  // Booking Bottom Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBookingBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Price display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tổng thanh toán',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.pitch.price.toStringAsFixed(0)}k',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        TextSpan(
                          text: '/giờ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Book button
              Expanded(
                child: ScaleTransition(
                  scale: _fabScaleAnimation,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            pitch: widget.pitch,
                            selectedDate: _selectedDate,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B0A2E), Color(0xFF7B0323)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đặt lịch ngay',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 8, color: const Color(0xFFF5F5F5));
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;

  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Text(
            widget.text,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF555555),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Thu gọn' : 'Xem thêm',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryRed,
            ),
          ),
        ),
      ],
    );
  }
}

// Data Models
// ─────────────────────────────────────────────────────────────────────────────

// class _PitchTypeVariant {
//   final String label;
//   final String type;
//   final double price;
//   final bool available;

//   const _PitchTypeVariant({
//     required this.label,
//     required this.type,
//     required this.price,
//     required this.available,
//   });
// }
