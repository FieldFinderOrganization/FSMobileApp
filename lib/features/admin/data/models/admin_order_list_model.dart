class AdminOrderListModel {
  final List<AdminOrderItem> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  const AdminOrderListModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });

  factory AdminOrderListModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderListModel(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => AdminOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num? ?? 0).toInt(),
      totalPages: (json['totalPages'] as num? ?? 0).toInt(),
      currentPage: (json['currentPage'] as num? ?? 0).toInt(),
    );
  }
}

class AdminOrderItem {
  final int orderId;
  final String userName;
  final double totalAmount;
  final String status;
  final int itemCount;
  final String createdAt;

  const AdminOrderItem({
    required this.orderId,
    required this.userName,
    required this.totalAmount,
    required this.status,
    required this.itemCount,
    required this.createdAt,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      orderId: (json['orderId'] as num? ?? 0).toInt(),
      userName: json['userName']?.toString() ?? '—',
      totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
      status: json['status']?.toString() ?? '',
      itemCount: (json['itemCount'] as num? ?? 0).toInt(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
