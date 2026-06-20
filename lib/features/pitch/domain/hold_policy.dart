/// Chính sách giữ slot động (Dynamic Hold) — bản FE, khớp với
/// `BookingHoldPolicy` ở backend. Dùng để hiển thị countdown thanh toán.
///
/// Hold timeout theo khoảng cách từ lúc đặt (createdAt) đến giờ bắt đầu slot:
///   gap ≥ 12h → 30 phút; gap ≥ 3h → 15 phút; còn lại → 5 phút.
/// Hạn thanh toán = min(createdAt + holdTimeout, slotStart − 90 phút).
library;

const int kAbsoluteDeadlineMinutesBeforeStart = 90;

int holdTimeoutMinutes(DateTime createdAt, DateTime slotStart) {
  final gapHours = slotStart.difference(createdAt).inHours;
  if (gapHours >= 12) return 30;
  if (gapHours >= 3) return 15;
  return 5;
}

DateTime holdPaymentDeadline(DateTime createdAt, DateTime slotStart) {
  final holdDeadline =
      createdAt.add(Duration(minutes: holdTimeoutMinutes(createdAt, slotStart)));
  final absoluteDeadline = slotStart
      .subtract(const Duration(minutes: kAbsoluteDeadlineMinutesBeforeStart));
  return holdDeadline.isBefore(absoluteDeadline) ? holdDeadline : absoluteDeadline;
}
