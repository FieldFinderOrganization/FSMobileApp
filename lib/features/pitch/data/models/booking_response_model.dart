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
  final List<String> slotsName;
  final String? createdAt;
  final String? paidAt;

  /// Hạn thanh toán đơn PENDING (Dynamic Hold) — nguồn chuẩn từ BE. Null nếu hết chờ.
  final String? paymentDeadline;

  /// USER / PROVIDER / SYSTEM — null nếu đơn chưa hủy.
  final String? cancelledBy;
  final String? cancelReason;

  /// Khóa lịch thủ công: 'MAINTENANCE' | 'OFFLINE_BOOKING'. Null = đơn đặt thường.
  final String? blockType;

  /// Ghi chú chủ sân khi khóa (tên/SĐT/cọc khách đặt ngoài app).
  final String? providerNotes;

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
    this.slotsName = const [],
    this.createdAt,
    this.paidAt,
    this.paymentDeadline,
    this.cancelledBy,
    this.cancelReason,
    this.blockType,
    this.providerNotes,
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
      slotsName: (json['slotsName'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['createdAt'],
      paidAt: json['paidAt'],
      paymentDeadline: json['paymentDeadline'],
      cancelledBy: json['cancelledBy'],
      cancelReason: json['cancelReason'],
      blockType: json['blockType'],
      providerNotes: json['providerNotes'],
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
      'slotsName': slotsName,
      'createdAt': createdAt,
      'paidAt': paidAt,
      'paymentDeadline': paymentDeadline,
      'cancelledBy': cancelledBy,
      'cancelReason': cancelReason,
      'blockType': blockType,
      'providerNotes': providerNotes,
    };
  }
}
