import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? profilePhotoPath;
  final String? createdAt;
  final String? updatedAt;
  final String? phoneNumber;
  final String? role;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.profilePhotoPath,
    this.createdAt,
    this.updatedAt,
    this.phoneNumber,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      profilePhotoPath: json['profile_photo_path'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: json['role']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, email, emailVerifiedAt, profilePhotoPath, createdAt, updatedAt, phoneNumber, role];
} 