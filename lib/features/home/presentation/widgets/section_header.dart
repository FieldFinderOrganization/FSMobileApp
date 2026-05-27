import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String? index;      // e.g. '01', '02'
  final bool darkMode;      // for dark-background sections

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.index,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = darkMode ? Colors.white : AppColors.textDark;
    final seeAllColor = darkMode ? Colors.white54 : AppColors.primaryRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: index number (if any) + "Xem tất cả"
          if (index != null || onSeeAll != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (index != null)
                  Text(
                    index!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                      letterSpacing: 1.5,
                    ),
                  ),
                const Spacer(),
                if (onSeeAll != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    child: Row(
                      children: [
                        Text(
                          'XEM TẤT CẢ',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: seeAllColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: seeAllColor,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (index != null) const SizedBox(height: 10),
          // Title
          Text(
            title.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: 0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentGold,
                  AppColors.accentGold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
