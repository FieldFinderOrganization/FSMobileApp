class AdminOverviewModel {
  final double totalRevenue;
  final double bookingRevenue;
  final double productRevenue;
  final double revenueChangePercent;
  final int totalUsers;
  final double usersChangePercent;
  final int totalPitches;
  final double pitchesChangePercent;
  final int bookingsTodayCount;
  final double bookingsTodayChangePercent;
  final int totalBookings;
  final int pendingOrdersCount;
  final double averageRating;

  const AdminOverviewModel({
    required this.totalRevenue,
    required this.bookingRevenue,
    required this.productRevenue,
    required this.revenueChangePercent,
    required this.totalUsers,
    required this.usersChangePercent,
    required this.totalPitches,
    required this.pitchesChangePercent,
    required this.bookingsTodayCount,
    required this.bookingsTodayChangePercent,
    required this.totalBookings,
    required this.pendingOrdersCount,
    required this.averageRating,
  });

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    double d(String key) => (json[key] as num? ?? 0).toDouble();
    int i(String key) => (json[key] as num? ?? 0).toInt();
    return AdminOverviewModel(
      totalRevenue: d('totalRevenue'),
      bookingRevenue: d('bookingRevenue'),
      productRevenue: d('productRevenue'),
      revenueChangePercent: d('revenueChangePercent'),
      totalUsers: i('totalUsers'),
      usersChangePercent: d('usersChangePercent'),
      totalPitches: i('totalPitches'),
      pitchesChangePercent: d('pitchesChangePercent'),
      bookingsTodayCount: i('bookingsTodayCount'),
      bookingsTodayChangePercent: d('bookingsTodayChangePercent'),
      totalBookings: i('totalBookings'),
      pendingOrdersCount: i('pendingOrdersCount'),
      averageRating: d('averageRating'),
    );
  }
}
