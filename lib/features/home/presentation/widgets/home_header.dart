import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../cart/presentation/pages/cart_screen.dart';

class HomeHeader extends StatelessWidget {
  final double opacity;
  final VoidCallback? onSearchTap;

  const HomeHeader({super.key, required this.opacity, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final showShadow = opacity > 0.5;
    const logoFirstColor = Colors.white;
    const logoSecondColor = AppColors.accentGold;
    const iconColor = Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.midnightDeep.withValues(alpha: opacity * 0.92),
        border: showShadow
            ? const Border(
                bottom: BorderSide(
                  color: Color(0x26C9A86A), // AppColors.accentGold with 15% opacity
                  width: 0.5,
                ),
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
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
                          color: logoFirstColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Finder',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: logoSecondColor,
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
                  color: iconColor,
                  onTap: onSearchTap ?? () {},
                ),
                const SizedBox(width: 4),
                _CartIconWithBadge(
                  color: iconColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),
                const SizedBox(width: 4),
                _HeaderIcon(
                  icon: Icons.notifications_outlined,
                  color: iconColor,
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

class _CartIconWithBadge extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _CartIconWithBadge({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final count = state.cart?.items.fold(0, (sum, i) => sum + i.quantity) ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: color,
                size: 24,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            if (count > 0)
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: color,
        size: 24,
      ),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}
