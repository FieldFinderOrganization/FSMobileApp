import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/contact_info.dart';
import '../../../../core/utils/launch_helper.dart';

/// Màn "Liên hệ": thông tin SportsHub + các kênh (Zalo, gọi, email, địa chỉ, FB).
/// Tĩnh, không backend.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  /// Chạy action mở app ngoài; bắt messenger trước await để tránh dùng context
  /// qua async gap. Hiện snackbar nếu thất bại.
  Future<void> _open(BuildContext context, Future<bool> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng tương ứng.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Liên hệ',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryRed,
                  AppColors.primaryRed.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_soccer_rounded,
                      color: Colors.white, size: 34),
                ),
                const SizedBox(height: 12),
                Text(
                  ContactInfo.name,
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Luôn sẵn sàng hỗ trợ bạn',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Các kênh liên hệ ────────────────────────────────────────────
          _card(
            child: Column(
              children: [
                _row(
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF0068FF),
                  title: 'Zalo',
                  value: ContactInfo.hotlinePretty,
                  onTap: () =>
                      _open(context, () => LaunchHelper.openUrl(ContactInfo.zaloUrl)),
                ),
                const Divider(height: 1),
                _row(
                  icon: Icons.phone_rounded,
                  color: AppColors.primaryRed,
                  title: 'Gọi điện',
                  value: ContactInfo.hotlinePretty,
                  onTap: () =>
                      _open(context, () => LaunchHelper.dialPhone(ContactInfo.hotline)),
                ),
                const Divider(height: 1),
                _row(
                  icon: Icons.email_rounded,
                  color: const Color(0xFFE4572E),
                  title: 'Email',
                  value: ContactInfo.email,
                  onTap: () =>
                      _open(context, () => LaunchHelper.sendEmail(ContactInfo.email)),
                ),
                const Divider(height: 1),
                _row(
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF2E7D32),
                  title: 'Địa chỉ',
                  value: ContactInfo.address,
                  onTap: () =>
                      _open(context, () => LaunchHelper.openMaps(ContactInfo.address)),
                ),
                const Divider(height: 1),
                _row(
                  icon: Icons.facebook_rounded,
                  color: const Color(0xFF1877F2),
                  title: 'Facebook',
                  value: 'fb.com/mtriet.004',
                  onTap: () =>
                      _open(context, () => LaunchHelper.openUrl(ContactInfo.facebookUrl)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _row({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.inter(
            fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
    );
  }
}
