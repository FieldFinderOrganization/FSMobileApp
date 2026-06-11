import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final bool darkMode; // for dark-background sections

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = darkMode ? Colors.white : AppColors.textDark;
    final seeAllColor = darkMode ? Colors.white54 : AppColors.primaryRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: seeAllColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 13,
                    color: seeAllColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
