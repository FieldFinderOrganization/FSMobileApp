class AdminUserListModel {
  final List<AdminUserItem> content;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  const AdminUserListModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });

  factory AdminUserListModel.fromJson(Map<String, dynamic> json) {
    return AdminUserListModel(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => AdminUserItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num? ?? 0).toInt(),
      totalPages: (json['totalPages'] as num? ?? 0).toInt(),
      currentPage: (json['currentPage'] as num? ?? 0).toInt(),
    );
  }
}

class AdminUserItem {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? lastLoginAt;
  final String? createdAt;

  const AdminUserItem({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.lastLoginAt,
    this.createdAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    return AdminUserItem(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastLoginAt: json['lastLoginAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
