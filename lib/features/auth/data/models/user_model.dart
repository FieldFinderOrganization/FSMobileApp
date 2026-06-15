import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    required super.role,
    required super.status,
    super.imageUrl,
    required super.hasPassword,
    super.gender,
    super.dateOfBirth,
    super.address,
    super.province,
    super.district,
    super.occupation,
    super.preferredPitchType,
    super.preferredPlayTime,
    super.latitude,
    super.longitude,
    super.available,
    super.vehicleType,
    super.vehiclePlate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return UserModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      imageUrl: json['imageUrl'] as String?,
      hasPassword: json['hasPassword'] as bool? ?? true,
      gender: json['gender'] as String?,
      dateOfBirth: parseDate(json['dateOfBirth']),
      address: json['address'] as String?,
      province: json['province'] as String?,
      district: json['district'] as String?,
      occupation: json['occupation'] as String?,
      preferredPitchType: json['preferredPitchType'] as String?,
      preferredPlayTime: json['preferredPlayTime'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      available: json['available'] as bool?,
      vehicleType: json['vehicleType'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
    );
  }
}
