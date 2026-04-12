class BookingRequestModel {
  final String pitchId;
  final String userId;
  final String bookingDate; // yyyy-MM-dd
  final double totalPrice;
  final List<BookingDetailModel> bookingDetails;

  BookingRequestModel({
    required this.pitchId,
    required this.userId,
    required this.bookingDate,
    required this.totalPrice,
    required this.bookingDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'pitchId': pitchId,
      'userId': userId,
      'bookingDate': bookingDate,
      'totalPrice': totalPrice,
      'bookingDetails': bookingDetails.map((x) => x.toJson()).toList(),
    };
  }
}

class BookingDetailModel {
  final int slot;
  final String name;
  final double priceDetail;

  BookingDetailModel({
    required this.slot,
    required this.name,
    required this.priceDetail,
  });

  Map<String, dynamic> toJson() {
    return {
      'slot': slot,
      'name': name,
      'priceDetail': priceDetail,
    };
  }
}
