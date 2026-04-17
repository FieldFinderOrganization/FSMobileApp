class BookingByDayModel {
  final String dayLabel;
  final int count;

  const BookingByDayModel({required this.dayLabel, required this.count});

  factory BookingByDayModel.fromJson(Map<String, dynamic> json) {
    return BookingByDayModel(
      dayLabel: json['dayLabel'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}
