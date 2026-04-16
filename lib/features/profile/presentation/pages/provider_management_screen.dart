import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../widgets/provider_info_tab.dart';
import '../widgets/provider_address_tab.dart';
import '../widgets/provider_pitch_tab.dart';
import '../cubit/provider_cubit.dart';
import '../../domain/repositories/provider_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProviderManagementScreen extends StatefulWidget {
  final UserEntity user;

  const ProviderManagementScreen({super.key, required this.user});

  @override
  State<ProviderManagementScreen> createState() => _ProviderManagementScreenState();
}

class _ProviderManagementScreenState extends State<ProviderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProviderCubit(
        repository: context.read<ProviderRepository>(),
      )..loadProviderData(widget.user.userId),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
        title: Text(
          'Quản lý Đối tác',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primaryRed,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Khu vực'),
            Tab(text: 'Sân bãi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProviderInfoTab(user: widget.user),
          ProviderAddressTab(user: widget.user),
          ProviderPitchTab(user: widget.user),
        ],
      ),
      ),
    );
  }
}
