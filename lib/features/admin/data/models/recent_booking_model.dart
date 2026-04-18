class RecentBookingModel {
  final String bookingId;
  final String userName;
  final String userInitials;
  final String description;
  final String timeAgo;
  final String status;

  const RecentBookingModel({
    required this.bookingId,
    required this.userName,
    required this.userInitials,
    required this.description,
    required this.timeAgo,
    required this.status,
  });

  factory RecentBookingModel.fromJson(Map<String, dynamic> json) {
    return RecentBookingModel(
      bookingId: json['bookingId'] as String,
      userName: json['userName'] as String,
      userInitials: json['userInitials'] as String,
      description: json['description'] as String,
      timeAgo: json['timeAgo'] as String,
      status: json['status'] as String,
    );
  }
}
