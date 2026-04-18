class BookingResponseModel {
  final String userId;
  final String userName;
  final String providerUserId;
  final String bookingId;
  final String bookingDate;
  final String status;
  final String paymentStatus;
  final double totalPrice;
  final String providerId;
  final String paymentMethod;
  final String providerName;
  final String pitchName;
  final String? pitchImageUrl;
  final String? pitchId;
  final List<int> slots;
  final String? createdAt;
  final String? paidAt;

  BookingResponseModel({
    required this.userId,
    required this.userName,
    required this.providerUserId,
    required this.bookingId,
    required this.bookingDate,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    required this.providerId,
    required this.paymentMethod,
    required this.providerName,
    required this.pitchName,
    this.pitchImageUrl,
    this.pitchId,
    required this.slots,
    this.createdAt,
    this.paidAt,
  });

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    return BookingResponseModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      providerUserId: json['providerUserId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      bookingDate: json['bookingDate'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      providerId: json['providerId'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      providerName: json['providerName'] ?? '',
      pitchName: json['pitchName'] ?? '',
      pitchImageUrl: json['pitchImageUrl'],
      pitchId: json['pitchId']?.toString(),
      slots: (json['slots'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      createdAt: json['createdAt'],
      paidAt: json['paidAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'providerUserId': providerUserId,
      'bookingId': bookingId,
      'bookingDate': bookingDate,
      'status': status,
      'paymentStatus': paymentStatus,
      'totalPrice': totalPrice,
      'providerId': providerId,
      'paymentMethod': paymentMethod,
      'providerName': providerName,
      'pitchName': pitchName,
      'pitchImageUrl': pitchImageUrl,
      'pitchId': pitchId,
      'slots': slots,
      'createdAt': createdAt,
      'paidAt': paidAt,
    };
  }
}
