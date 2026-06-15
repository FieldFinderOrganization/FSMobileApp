import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../call/presentation/cubit/call_cubit.dart';
import 'shipper_earnings_screen.dart';
import 'shipper_orders_tab.dart';
import 'shipper_profile_screen.dart';

/// Khung chính của shipper: bottom nav 3 tab — Đơn / Thu nhập / Hồ sơ.
class ShipperShell extends StatefulWidget {
  final UserEntity user;
  const ShipperShell({super.key, required this.user});

  @override
  State<ShipperShell> createState() => _ShipperShellState();
}

class _ShipperShellState extends State<ShipperShell> {
  int _index = 0;
  late bool _online;

  @override
  void initState() {
    super.initState();
    _online = widget.user.available ?? true;
    // Shipper KHÔNG qua MainShell (nơi start signaling) → tự mở socket cuộc gọi
    // để gọi/nhận được. CallCubit là provider global; logout đã stop() ở main.dart.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CallCubit>().start(widget.user.userId, widget.user.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(
        index: _index,
        children: [
          ShipperOrdersTab(user: widget.user, online: _online),
          ShipperEarningsScreen(user: widget.user),
          ShipperProfileScreen(
            user: widget.user,
            online: _online,
            onOnlineChanged: (v) => setState(() => _online = v),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: AppColors.primaryRed.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.primaryRed),
            label: 'Đơn',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon:
                Icon(Icons.account_balance_wallet, color: AppColors.primaryRed),
            label: 'Thu nhập',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person, color: AppColors.primaryRed),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
