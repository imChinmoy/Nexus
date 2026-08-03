import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatar;
  final String? year;
  final String? domain;
  final String? phone;
  final String? bio;
  final String? github;
  final String? linkedin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.year,
    this.domain,
    this.phone,
    this.bio,
    this.github,
    this.linkedin,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin || isSuperAdmin;
  bool get isCoordinator =>
      role == UserRole.coordinator || isAdmin;
  bool get canWrite => role != UserRole.viewer;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        avatar,
        year,
        domain,
        phone,
        bio,
        github,
        linkedin,
        isActive,
        createdAt,
        updatedAt
      ];
}

enum UserRole {
  superAdmin,
  admin,
  coordinator,
  volunteer,
  viewer;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.coordinator:
        return 'Coordinator';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'coordinator':
        return UserRole.coordinator;
      case 'volunteer':
        return UserRole.volunteer;
      default:
        return UserRole.viewer;
    }
  }
  
  String get backendValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.admin:
        return 'admin';
      case UserRole.coordinator:
        return 'coordinator';
      case UserRole.volunteer:
        return 'volunteer';
      case UserRole.viewer:
        return 'viewer';
    }
  }
}
