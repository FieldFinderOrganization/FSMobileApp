import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? imageUrl;
  final bool hasPassword;

  // Personal info
  final String? gender;             // MALE / FEMALE / OTHER / UNKNOWN
  final DateTime? dateOfBirth;
  final String? address;
  final String? province;
  final String? district;
  final String? occupation;

  // Preferences
  final String? preferredPitchType; // FIVE_A_SIDE / SEVEN_A_SIDE / ELEVEN_A_SIDE
  final String? preferredPlayTime;  // MORNING / AFTERNOON / EVENING / NIGHT

  // Toạ độ (dùng cho "sân gần bạn" khi GPS không có)
  final double? latitude;
  final double? longitude;

  const UserEntity({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.imageUrl,
    this.hasPassword = true,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.province,
    this.district,
    this.occupation,
    this.preferredPitchType,
    this.preferredPlayTime,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        userId, name, email, phone, role, status, imageUrl, hasPassword,
        gender, dateOfBirth, address, province, district, occupation,
        preferredPitchType, preferredPlayTime, latitude, longitude,
      ];

  UserEntity copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? imageUrl,
    bool? hasPassword,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? province,
    String? district,
    String? occupation,
    String? preferredPitchType,
    String? preferredPlayTime,
    double? latitude,
    double? longitude,
  }) {
    return UserEntity(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      hasPassword: hasPassword ?? this.hasPassword,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      province: province ?? this.province,
      district: district ?? this.district,
      occupation: occupation ?? this.occupation,
      preferredPitchType: preferredPitchType ?? this.preferredPitchType,
      preferredPlayTime: preferredPlayTime ?? this.preferredPlayTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
