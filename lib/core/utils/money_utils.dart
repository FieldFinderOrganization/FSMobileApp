/// Định dạng tiền VND thống nhất toàn app (giống màn chi tiết sản phẩm):
/// dấu chấm mỗi 3 số + hậu tố "đ". Không phụ thuộc intl/locale.
///
/// Mọi giá trong app (sản phẩm, sân, booking, payment) đều lưu theo ĐỒNG đầy đủ
/// (vd 120000 = 120.000đ), nên chỉ cần [formatVnd].
library;

/// Giá theo ĐỒNG đầy đủ -> "120.000đ".
String formatVnd(num? dong) {
  final value = (dong ?? 0).round();
  final negative = value < 0;
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${negative ? '-' : ''}${buf}đ';
}
