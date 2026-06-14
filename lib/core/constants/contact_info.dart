/// Thông tin liên hệ thật của SportsHub — đặt 1 chỗ, Support + Contact cùng đọc.
/// Sửa giá trị ở đây là cập nhật toàn app.
class ContactInfo {
  static const String name = 'SportsHub Group';

  /// Hotline (hiển thị). Tap chính → mở Zalo (zaloUrl); nút phụ "Gọi" → tel.
  static const String hotline = '0888696869';
  static const String zaloUrl = 'https://zalo.me/0888696869';

  static const String email = 'triet172004@gmail.com';

  static const String address = '45 Tân Lập, Đông Hòa, Hồ Chí Minh';

  static const String facebookUrl = 'https://www.facebook.com/mtriet.004/';

  /// Số đẹp hiển thị: "0888 696 869".
  static String get hotlinePretty {
    final d = hotline;
    if (d.length == 10) {
      return '${d.substring(0, 4)} ${d.substring(4, 7)} ${d.substring(7)}';
    }
    return d;
  }
}
