import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/contact_info.dart';
import '../../../../core/utils/launch_helper.dart';

/// Màn "Trợ giúp & Hỗ trợ": FAQ + kênh liên hệ nhanh. Tĩnh, không backend.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const List<_Faq> _faqs = [
    _Faq(
      'Làm sao để đặt sân?',
      'Vào tab Sân, chọn sân và khung giờ trống, xác nhận và thanh toán. '
          'Đơn đặt sẽ xuất hiện trong "Lịch sử đặt sân" ở trang cá nhân.',
    ),
    _Faq(
      'Tôi có thể huỷ và được hoàn tiền không?',
      'Có. Mở "Lịch sử đặt sân", chọn đơn và bấm Huỷ. Nếu đơn đã thanh toán và '
          'còn trong thời gian cho phép, hệ thống phát hành mã hoàn tiền cho bạn.',
    ),
    _Faq(
      'Có những cách thanh toán nào?',
      'Hỗ trợ chuyển khoản QR ngân hàng và thanh toán khi nhận (với đơn hàng). '
          'Số tiền luôn được tính theo máy chủ để đảm bảo chính xác.',
    ),
    _Faq(
      'Điểm thưởng và voucher hoạt động ra sao?',
      'Mỗi 10.000đ chi tiêu hợp lệ được 1 điểm khi đơn hoàn tất. Vào "Điểm thưởng" '
          'để đổi điểm lấy voucher, và "Voucher của tôi" để xem mã đã có.',
    ),
    _Faq(
      'Quên mật khẩu / bảo mật tài khoản?',
      'Dùng "Quên mật khẩu" ở màn đăng nhập để nhận OTP. Bạn cũng có thể bật '
          'Passkey trong trang cá nhân để đăng nhập an toàn không cần mật khẩu.',
    ),
  ];

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
          'Trợ giúp & Hỗ trợ',
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
          // ── Liên hệ nhanh ──────────────────────────────────────────────
          _card(
            child: Column(
              children: [
                _quickRow(
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF0068FF),
                  title: 'Nhắn Zalo hỗ trợ',
                  subtitle: ContactInfo.hotlinePretty,
                  onTap: () =>
                      _open(context, () => LaunchHelper.openUrl(ContactInfo.zaloUrl)),
                ),
                const Divider(height: 1),
                _quickRow(
                  icon: Icons.phone_rounded,
                  color: AppColors.primaryRed,
                  title: 'Gọi hotline',
                  subtitle: ContactInfo.hotlinePretty,
                  onTap: () =>
                      _open(context, () => LaunchHelper.dialPhone(ContactInfo.hotline)),
                ),
                const Divider(height: 1),
                _quickRow(
                  icon: Icons.email_rounded,
                  color: const Color(0xFFE4572E),
                  title: 'Gửi email',
                  subtitle: ContactInfo.email,
                  onTap: () => _open(
                      context,
                      () => LaunchHelper.sendEmail(ContactInfo.email,
                          subject: 'Hỗ trợ SportsHub')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Câu hỏi thường gặp',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          _card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < _faqs.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      iconColor: AppColors.primaryRed,
                      title: Text(
                        _faqs[i].q,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      children: [
                        Text(
                          _faqs[i].a,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            height: 1.5,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(4),
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

  Widget _quickRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
            fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}
