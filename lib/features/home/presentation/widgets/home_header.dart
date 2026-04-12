import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final double opacity;
  final VoidCallback? onSearchTap;

  const HomeHeader({super.key, required this.opacity, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final showShadow = opacity > 0.5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Logo
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Field',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Finder',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryRed,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Action icons
                _HeaderIcon(
                  icon: Icons.search_rounded,
                  isDark: true,
                  onTap: onSearchTap ?? () {},
                ),
                const SizedBox(width: 4),
                _HeaderIcon(
                  icon: Icons.shopping_cart_outlined,
                  isDark: true,
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                _HeaderIcon(
                  icon: Icons.notifications_outlined,
                  isDark: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: isDark ? AppColors.textDark : Colors.white,
        size: 24,
      ),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}
