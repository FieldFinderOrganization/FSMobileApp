import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/home/presentation/pages/main_shell.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';
import 'admin_bookings_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_pitches_screen.dart';
import 'admin_users_screen.dart';
import '../../../discount/presentation/cubit/admin_discount_cubit.dart';
import '../../../discount/presentation/pages/admin_discount_list_screen.dart';

class AdminShell extends StatefulWidget {
  final UserEntity user;

  const AdminShell({super.key, required this.user});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().loadDashboard();
    context.read<AdminDiscountCubit>().loadDiscounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(
                _getAppbarTitle(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              backgroundColor: const Color(0xFFF8F9FC),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              centerTitle: false,
            ),
      drawer: _buildCleanDrawer(),
      body: _buildBody(),
    );
  }

  String _getAppbarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tổng quan';
      case 1:
        return 'Người dùng';
      case 2:
        return 'Sân bóng';
      case 3:
        return 'Khu vực';
      case 4:
        return 'Đặt sân';
      case 5:
        return 'Đơn hàng';
      default:
        return 'Bảng điều khiển';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboardScreen(user: widget.user);
      case 1:
        return Center(
          child: Text(
            'Tính năng Người dùng đang phát triển',
            style: GoogleFonts.inter(),
          ),
        );
      case 2:
        return Center(
          child: Text(
            'Tính năng Sân bóng đang phát triển',
            style: GoogleFonts.inter(),
          ),
        );
      case 3:
        return Center(
          child: Text(
            'Tính năng Khu vực đang phát triển',
            style: GoogleFonts.inter(),
          ),
        );
      case 4:
        return Center(
          child: Text(
            'Tính năng Đặt sân đang phát triển',
            style: GoogleFonts.inter(),
          ),
        );
      case 5:
        return Center(
          child: Text(
            'Tính năng Đơn hàng đang phát triển',
            style: GoogleFonts.inter(),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  void _pushScreen(Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildCleanDrawer() {
    return Drawer(
      width: 280,
      backgroundColor: const Color(0xFF1A1A2E),
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
          builder: (context, state) {
            final cubit = context.read<AdminDashboardCubit>();
            final loaded = state is AdminDashboardLoaded ? state : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDrawerHeader(),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFF2A2A4A),
                ),
                const SizedBox(height: 12),
                _buildDrawerItem(
                  0,
                  'Tổng quan',
                  Icons.space_dashboard_outlined,
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  1,
                  'Người dùng',
                  Icons.people_outline,
                  onTap: () => _pushScreen(
                    AdminUsersScreen(datasource: cubit.datasource),
                  ),
                ),
                _buildDrawerItem(
                  2,
                  'Sân bóng',
                  Icons.sports_soccer_outlined,
                  onTap: () => _pushScreen(
                    AdminPitchesScreen(
                      datasource: cubit.datasource,
                      pitchTypeData: loaded?.pitchesByType ?? [],
                    ),
                  ),
                ),
                _buildDrawerItem(
                  4,
                  'Đặt sân',
                  Icons.calendar_today_outlined,
                  onTap: () => _pushScreen(
                    AdminBookingsScreen(datasource: cubit.datasource),
                  ),
                ),
                _buildDrawerItem(
                  5,
                  'Đơn hàng',
                  Icons.receipt_long_outlined,
                  onTap: () => _pushScreen(
                    AdminOrdersScreen(datasource: cubit.datasource),
                  ),
                ),
                _buildDrawerItem(
                  6,
                  'Mã khuyến mãi',
                  Icons.local_offer_outlined,
                  onTap: () => _pushScreen(
                    BlocProvider.value(
                      value: context.read<AdminDiscountCubit>(),
                      child: const AdminDiscountListScreen(),
                    ),
                  ),
                ),
                const Spacer(),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFF2A2A4A),
                ),
                _buildBackToAppItem(),
                _buildLogoutItem(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final initials = _buildInitials(widget.user.name);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryRed,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Trung tâm Quản trị',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.name,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    int index,
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primaryRed.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryRed.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.primaryRed, width: 3),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryRed : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackToAppItem() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainShell(user: widget.user)),
            (route) => false,
          );
        },
        child: Row(
          children: [
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              'Quay lại app chính',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GestureDetector(
        onTap: () {
          // TODO: implement logout
        },
        child: Row(
          children: [
            const Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 14),
            Text(
              'Đăng xuất',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    final sb = StringBuffer();
    for (final part in parts) {
      if (part.isNotEmpty) sb.write(part[0].toUpperCase());
    }
    final s = sb.toString();
    return s.length > 2 ? s.substring(s.length - 2) : s;
  }
}
