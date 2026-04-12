import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../../../features/auth/login/presentation/bloc/auth_cubit.dart';
import '../../../../features/auth/login/presentation/bloc/auth_state.dart';
import '../../../../features/auth/login/presentation/pages/login_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pitch/presentation/pages/booking_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserEntity user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return _ProfileBody(user: user);
  }
}

class _ProfileBody extends StatelessWidget {
  final UserEntity user;

  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── App Bar ───────────────────────────────────────────────
                _buildAppBar(),
                // ── Scrollable body ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        // ── Avatar ───────────────────────────────────────
                        _buildAvatar(),
                        const SizedBox(height: 16),
                        // ── Name ─────────────────────────────────────────
                        Text(
                          user.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // ── Role badge ───────────────────────────────────
                        _buildRoleBadge(),
                        const SizedBox(height: 28),
                        // ── Info Card ─────────────────────────────────────
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        // ── Quick actions ─────────────────────────────────
                        _buildQuickActions(context),
                        const SizedBox(height: 20),
                        // ── Logout button ─────────────────────────────────
                        _buildLogoutButton(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // App Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Trang cá nhân',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Avatar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final hasImage = user.imageUrl != null && user.imageUrl!.isNotEmpty;
    final initials = user.name.isNotEmpty
        ? user.name
              .trim()
              .split(' ')
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryRed, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withValues(alpha: 0.18),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: hasImage
                ? Image.network(
                    user.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildInitialsAvatar(initials),
                  )
                : _buildInitialsAvatar(initials),
          ),
        ),
        // Online indicator
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: user.status == 'ACTIVE'
                  ? const Color(0xFF4CAF50)
                  : Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      color: AppColors.primaryRed,
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.playfairDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Role Badge
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRoleBadge() {
    final roleLabel = _localizeRole(user.role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 13,
            color: AppColors.primaryRed,
          ),
          const SizedBox(width: 5),
          Text(
            roleLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _localizeRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'OWNER':
        return 'Chủ sân';
      case 'CUSTOMER':
        return 'Người dùng';
      default:
        return role;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Info Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    // Phone: luôn hiển thị, dùng "N/A" nếu null hoặc rỗng
    final phone =
        (user.phone == null || user.phone!.isEmpty || user.phone == 'N/A')
        ? 'N/A'
        : user.phone!;

    final statusLabel = user.status == 'ACTIVE'
        ? 'Đang hoạt động'
        : user.status;
    final statusColor = user.status == 'ACTIVE'
        ? const Color(0xFF2E7D32)
        : Colors.orange[700]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Họ và tên',
            value: user.name,
            isFirst: true,
          ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Số điện thoại',
            value: phone,
            valueColor: phone == 'N/A'
                ? AppColors.textGrey
                : AppColors.textDark,
          ),
          _InfoRow(
            icon: Icons.circle_rounded,
            label: 'Trạng thái',
            value: statusLabel,
            valueColor: statusColor,
            isLast: true,
            iconColor: statusColor,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Quick Actions
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.history_rounded,
            label: 'Lịch sử đặt sân',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingHistoryScreen(userId: user.userId),
                ),
              );
            },
            isFirst: true,
          ),
          _ActionRow(
            icon: Icons.favorite_border_rounded,
            label: 'Sân yêu thích',
            onTap: () {},
          ),
          _ActionRow(
            icon: Icons.lock_outline_rounded,
            label: 'Đổi mật khẩu',
            onTap: () {},
          ),
          _ActionRow(
            icon: Icons.help_outline_rounded,
            label: 'Trợ giúp & Hỗ trợ',
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Logout Button
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.read<AuthCubit>().logout();
        },
        icon: const Icon(
          Icons.logout_rounded,
          color: AppColors.primaryRed,
          size: 19,
        ),
        label: Text(
          'Đăng xuất',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryRed,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: AppColors.primaryRed.withValues(alpha: 0.4),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: AppColors.primaryRed.withValues(alpha: 0.04),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row Widget
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryRed).withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: valueColor ?? AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Row Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, indent: 56, color: Color(0xFFF0F0F0)),
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.textGrey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textGrey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
