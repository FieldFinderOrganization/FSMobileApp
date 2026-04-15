import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/booking_request_model.dart';
import '../../data/models/payment_request_model.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/booking_slot_entity.dart';
import '../../domain/entities/pitch_entity.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository repository;
  final PaymentRepository paymentRepository;
  final PitchEntity pitch;
  final DateTime date;
  DateTime? paymentDeadline;

  BookingCubit({
    required this.repository,
    required this.paymentRepository,
    required this.pitch,
    required this.date,
  }) : super(BookingInitial()) {
    loadSlots();
  }

  static const List<Map<String, String>> _defaultSlots = [
    {'id': '1', 'start': '06:00', 'end': '07:00'},
    {'id': '2', 'start': '07:00', 'end': '08:00'},
    {'id': '3', 'start': '08:00', 'end': '09:00'},
    {'id': '4', 'start': '09:00', 'end': '10:00'},
    {'id': '5', 'start': '10:00', 'end': '11:00'},
    {'id': '6', 'start': '11:00', 'end': '12:00'},
    {'id': '7', 'start': '12:00', 'end': '13:00'},
    {'id': '8', 'start': '13:00', 'end': '14:00'},
    {'id': '9', 'start': '14:00', 'end': '15:00'},
    {'id': '10', 'start': '15:00', 'end': '16:00'},
    {'id': '11', 'start': '16:00', 'end': '17:00'},
    {'id': '12', 'start': '17:00', 'end': '18:00'},
    {'id': '13', 'start': '18:00', 'end': '19:00'},
    {'id': '14', 'start': '19:00', 'end': '20:00'},
    {'id': '15', 'start': '20:00', 'end': '21:00'},
    {'id': '16', 'start': '21:00', 'end': '22:00'},
    {'id': '17', 'start': '22:00', 'end': '23:00'},
    {'id': '18', 'start': '23:00', 'end': '00:00'},
  ];

  Future<void> loadSlots() async {
    emit(BookingLoading());
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final bookedIds = await repository.getBookedSlots(pitch.pitchId, dateStr);

      final now = DateTime.now();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

      final allSlots = _defaultSlots.map((s) {
        final id = int.parse(s['id']!);
        final startParts = s['start']!.split(':');
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        
        // Construct full DateTime for the slot
        final slotStartTime = DateTime(
          date.year,
          date.month,
          date.day,
          startHour,
          startMinute,
        );

        SlotStatus status = SlotStatus.available;
        if (bookedIds.contains(id)) {
          status = SlotStatus.booked;
        } else if (slotStartTime.isBefore(now)) {
          status = SlotStatus.past;
        } else if (isToday && slotStartTime.isBefore(now.add(const Duration(minutes: 30)))) {
          status = SlotStatus.tooLate;
        }

        return BookingSlotEntity(
          slotId: id,
          startTime: s['start']!,
          endTime: s['end']!,
          status: status,
        );
      }).toList();

      emit(BookingSuccess(slots: allSlots));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  void toggleSlotSelection(int slotId) {
    if (state is! BookingSuccess) return;
    final currentState = state as BookingSuccess;

    final updatedSlots = currentState.slots.map((slot) {
      if (slot.slotId == slotId) {
        if (slot.status == SlotStatus.available) {
          return slot.copyWith(status: SlotStatus.selected);
        } else if (slot.status == SlotStatus.selected) {
          return slot.copyWith(status: SlotStatus.available);
        }
      }
      return slot;
    }).toList();

    final selectedIds = updatedSlots
        .where((s) => s.status == SlotStatus.selected)
        .map((s) => s.slotId)
        .toList();

    final totalAmount = selectedIds.length * pitch.price;

    emit(currentState.copyWith(
      slots: updatedSlots,
      selectedSlotIds: selectedIds,
      totalAmount: totalAmount,
    ));
  }

  void setPaymentMethod(String method) {
    if (state is! BookingSuccess) return;
    emit((state as BookingSuccess).copyWith(paymentMethod: method));
  }

  Future<void> confirmBooking(String userId) async {
    if (state is! BookingSuccess) return;
    final currentState = state as BookingSuccess;
    
    if (currentState.selectedSlotIds.isEmpty) {
      emit(const BookingError('Vui lòng chọn ít nhất một khung giờ'));
      return;
    }

    emit(BookingLoading());
    try {
      final minSlot = currentState.selectedSlotIds.reduce((a, b) => a < b ? a : b);
      paymentDeadline = DateTime(date.year, date.month, date.day, 5 + minSlot, 0).subtract(const Duration(minutes: 5));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final bookingRequest = BookingRequestModel(
        pitchId: pitch.pitchId,
        userId: userId,
        bookingDate: dateStr,
        totalPrice: currentState.totalAmount,
        bookingDetails: currentState.selectedSlotIds.map((id) {
          final slot = currentState.slots.firstWhere((s) => s.slotId == id);
          return BookingDetailModel(
            slot: id,
            name: slot.timeRange,
            priceDetail: pitch.price,
          );
        }).toList(),
        paymentMethod: currentState.paymentMethod,
      );

      final bookingId = await repository.createBooking(bookingRequest);
      
      if (currentState.paymentMethod == 'BANK_TRANSFER') {
        final paymentRequest = PaymentRequestModel(
          bookingId: bookingId,
          userId: userId,
          amount: currentState.totalAmount,
          paymentMethod: 'BANK', // Matches Backend PaymentMethod enum
        );
        final paymentRes = await paymentRepository.createPayment(paymentRequest);
        emit(BookingPaymentRequired(
          paymentResponse: paymentRes,
          bookingId: bookingId,
        ));
      } else {
        emit(BookingConfirmed());
      }
    } catch (e) {
      emit(BookingError(e.toString()));
      loadSlots(); 
    }
  }

  Future<void> checkPaymentStatus(String bookingId) async {
    try {
      final status = await paymentRepository.getPaymentStatusByBookingId(bookingId);
      if (status.isPaid) {
        emit(BookingConfirmed());
      }
    } catch (e) {
      // Ignore polling errors to not disrupt UI
    }
  }
}
