import 'package:flutter_test/flutter_test.dart';
import 'package:fsmobileapp/features/pitch/domain/entities/booking_slot_entity.dart';

// Khung giờ đặt sân — đơn vị hiển thị + đổi trạng thái (available→selected→booked).
// Bằng nhau theo giá trị (Equatable) để lưới slot rebuild đúng khi chọn/bỏ chọn.
void main() {
  const slot = BookingSlotEntity(slotId: 3, startTime: '08:00', endTime: '09:00');

  test('timeRange ghép start - end', () {
    expect(slot.timeRange, '08:00 - 09:00');
  });

  test('status mặc định là available', () {
    expect(slot.status, SlotStatus.available);
  });

  test('copyWith đổi status giữ nguyên thông tin giờ', () {
    final selected = slot.copyWith(status: SlotStatus.selected);

    expect(selected.status, SlotStatus.selected);
    expect(selected.slotId, 3);
    expect(selected.startTime, '08:00');
    expect(selected.endTime, '09:00');
    // bản gốc bất biến
    expect(slot.status, SlotStatus.available);
  });

  test('copyWith không truyền status → giữ status cũ', () {
    final booked = slot.copyWith(status: SlotStatus.booked);
    expect(booked.copyWith().status, SlotStatus.booked);
  });

  test('bằng nhau theo giá trị; khác status → khác nhau', () {
    const same = BookingSlotEntity(slotId: 3, startTime: '08:00', endTime: '09:00');
    expect(slot, same);
    expect(slot == slot.copyWith(status: SlotStatus.booked), false);
  });
}
