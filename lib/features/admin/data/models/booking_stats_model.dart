class BookingStatsModel {
  final int confirmed;
  final int canceled;
  final int pending;
  final int total;

  const BookingStatsModel({
    required this.confirmed,
    required this.canceled,
    required this.pending,
    required this.total,
  });

  factory BookingStatsModel.fromJson(Map<String, dynamic> json) =>
      BookingStatsModel(
        confirmed: (json['confirmed'] as num).toInt(),
        canceled:  (json['canceled']  as num).toInt(),
        pending:   (json['pending']   as num).toInt(),
        total:     (json['total']     as num).toInt(),
      );
}
