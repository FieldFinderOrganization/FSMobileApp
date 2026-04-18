class AdminUserStatsModel {
  final List<RoleCount> byRole;
  final List<StatusCount> byStatus;
  final int total;

  const AdminUserStatsModel({
    required this.byRole,
    required this.byStatus,
    required this.total,
  });

  factory AdminUserStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminUserStatsModel(
      byRole: (json['byRole'] as List<dynamic>? ?? [])
          .map((e) => RoleCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      byStatus: (json['byStatus'] as List<dynamic>? ?? [])
          .map((e) => StatusCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

class RoleCount {
  final String role;
  final int count;

  const RoleCount({required this.role, required this.count});

  factory RoleCount.fromJson(Map<String, dynamic> json) {
    return RoleCount(
      role: json['role']?.toString() ?? '',
      count: (json['count'] as num? ?? 0).toInt(),
    );
  }
}

class StatusCount {
  final String status;
  final int count;

  const StatusCount({required this.status, required this.count});

  factory StatusCount.fromJson(Map<String, dynamic> json) {
    return StatusCount(
      status: json['status']?.toString() ?? '',
      count: (json['count'] as num? ?? 0).toInt(),
    );
  }
}
