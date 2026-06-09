import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Field',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Finder',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đặt sân · Mua đồ thể thao · Thi đấu',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),
          Row(
            children: [
              _FooterLink(label: 'Đặt sân', onTap: () {}),
              const SizedBox(width: 24),
              _FooterLink(label: 'Mua đồ', onTap: () {}),
              const SizedBox(width: 24),
              _FooterLink(label: 'Đơn hàng', onTap: () {}),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '© 2026 FieldFinder. All rights reserved.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white30,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }
}
