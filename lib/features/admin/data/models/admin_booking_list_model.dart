class AdminBookingListModel {
  final List<AdminBookingItem> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  const AdminBookingListModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });

  factory AdminBookingListModel.fromJson(Map<String, dynamic> json) {
    return AdminBookingListModel(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => AdminBookingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num? ?? 0).toInt(),
      totalPages: (json['totalPages'] as num? ?? 0).toInt(),
      currentPage: (json['currentPage'] as num? ?? 0).toInt(),
    );
  }
}

class AdminBookingItem {
  final String bookingId;
  final String userName;
  final String pitchName;
  final String bookingDate;
  final double totalPrice;
  final String paymentStatus;
  final String status;
  final String createdAt;

  const AdminBookingItem({
    required this.bookingId,
    required this.userName,
    required this.pitchName,
    required this.bookingDate,
    required this.totalPrice,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  factory AdminBookingItem.fromJson(Map<String, dynamic> json) {
    return AdminBookingItem(
      bookingId: json['bookingId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '—',
      pitchName: json['pitchName']?.toString() ?? '—',
      bookingDate: json['bookingDate']?.toString() ?? '',
      totalPrice: (json['totalPrice'] as num? ?? 0).toDouble(),
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
