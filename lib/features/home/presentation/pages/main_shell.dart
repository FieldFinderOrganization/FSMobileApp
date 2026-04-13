import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../home/presentation/pages/home_screen.dart';
import '../../../pitch/presentation/pages/pitch_tab_screen.dart';
import '../../../product/presentation/pages/product_list_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../../core/constants/app_colors.dart';

/// Shell cố định bao toàn bộ màn hình chính (sau khi đăng nhập).
/// Dùng [IndexedStack] để giữ state của từng tab khi chuyển qua lại.
class MainShell extends StatefulWidget {
  final UserEntity user;

  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _indicatorController;

  // Định nghĩa các tab
  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, label: 'Trang chủ'),
    _TabItem(icon: Icons.sports_soccer_rounded, label: 'Sân'),
    _TabItem(icon: Icons.shopping_bag_outlined, label: 'Shop'),
    _TabItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    _TabItem(icon: Icons.person_outline_rounded, label: 'Tôi'),
  ];

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      // IndexedStack giữ state từng tab — không rebuild khi chuyển tab
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0 — Trang chủ
          HomeScreen(),
          // 1 — Sân (danh sách và tìm kiếm sân)
          const PitchTabScreen(),
          // 2 — Shop
          const ProductListScreen(),
          // 3 — Chat
          const ChatScreen(),
          // 4 — Tôi
          ProfileScreen(user: widget.user),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: _AppBottomBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        bottomPadding: bottomPadding,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── Tab Item Data ─────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_TabItem> tabs;
  final double bottomPadding;
  final ValueChanged<int> onTap;

  const _AppBottomBar({
    required this.currentIndex,
    required this.tabs,
    required this.bottomPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: _TabBarItem(
                    icon: tab.icon,
                    label: tab.label,
                    isActive: isActive,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Tab Bar Item ──────────────────────────────────────────────────────────────

class _TabBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _TabBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryRed.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? AppColors.primaryRed : const Color(0xFFB0B0B0),
          ),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primaryRed : const Color(0xFFB0B0B0),
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

// ── Placeholder Tab ───────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _PlaceholderTab({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppColors.primaryRed),
              ),
              const SizedBox(height: 20),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
