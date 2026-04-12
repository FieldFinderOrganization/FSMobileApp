import 'package:equatable/equatable.dart';
import '../../data/models/payment_response_model.dart';
import '../../domain/entities/booking_slot_entity.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {
  final List<BookingSlotEntity> slots;
  final List<int> selectedSlotIds;
  final double totalAmount;
  final String paymentMethod; // 'CASH' or 'BANK_TRANSFER'

  const BookingSuccess({
    required this.slots,
    this.selectedSlotIds = const [],
    this.totalAmount = 0.0,
    this.paymentMethod = 'CASH',
  });

  @override
  List<Object?> get props => [slots, selectedSlotIds, totalAmount, paymentMethod];

  BookingSuccess copyWith({
    List<BookingSlotEntity>? slots,
    List<int>? selectedSlotIds,
    double? totalAmount,
    String? paymentMethod,
  }) {
    return BookingSuccess(
      slots: slots ?? this.slots,
      selectedSlotIds: selectedSlotIds ?? this.selectedSlotIds,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingConfirmed extends BookingState {}

class BookingPaymentRequired extends BookingState {
  final PaymentResponseModel paymentResponse;
  final String bookingId;

  const BookingPaymentRequired({
    required this.paymentResponse,
    required this.bookingId,
  });

  @override
  List<Object?> get props => [paymentResponse, bookingId];
}
