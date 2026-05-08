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
  final double totalAmount;       // sau giảm giá
  final double subtotal;          // trước giảm giá
  final double discountAmount;    // tổng giảm
  final List<String> discountCodes;
  final String paymentMethod; // 'CASH' or 'BANK_TRANSFER'

  const BookingSuccess({
    required this.slots,
    this.selectedSlotIds = const [],
    this.totalAmount = 0.0,
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.discountCodes = const [],
    this.paymentMethod = 'CASH',
  });

  @override
  List<Object?> get props => [
        slots,
        selectedSlotIds,
        totalAmount,
        subtotal,
        discountAmount,
        discountCodes,
        paymentMethod,
      ];

  BookingSuccess copyWith({
    List<BookingSlotEntity>? slots,
    List<int>? selectedSlotIds,
    double? totalAmount,
    double? subtotal,
    double? discountAmount,
    List<String>? discountCodes,
    String? paymentMethod,
  }) {
    return BookingSuccess(
      slots: slots ?? this.slots,
      selectedSlotIds: selectedSlotIds ?? this.selectedSlotIds,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      discountCodes: discountCodes ?? this.discountCodes,
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

class BookingConfirmed extends BookingState {
  final String? bookingId;
  const BookingConfirmed({this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

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
