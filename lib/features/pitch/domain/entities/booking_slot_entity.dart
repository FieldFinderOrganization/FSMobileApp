import 'package:equatable/equatable.dart';

enum SlotStatus { available, booked, selected, past, tooLate }

class BookingSlotEntity extends Equatable {
  final int slotId;
  final String startTime;
  final String endTime;
  final SlotStatus status;

  const BookingSlotEntity({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    this.status = SlotStatus.available,
  });

  String get timeRange => '$startTime - $endTime';

  BookingSlotEntity copyWith({SlotStatus? status}) {
    return BookingSlotEntity(
      slotId: slotId,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [slotId, startTime, endTime, status];
}
