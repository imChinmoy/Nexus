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

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatar,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      year: year ?? this.year,
      domain: domain ?? this.domain,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      github: github ?? this.github,
      linkedin: linkedin ?? this.linkedin,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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

  int get hierarchyLevel {
    switch (this) {
      case UserRole.superAdmin:
        return 5;
      case UserRole.admin:
        return 4;
      case UserRole.coordinator:
        return 3;
      case UserRole.volunteer:
        return 2;
      case UserRole.viewer:
        return 1;
    }
  }

  String get tierTitle {
    switch (this) {
      case UserRole.superAdmin:
        return 'Executive Council';
      case UserRole.admin:
        return 'Team Leads';
      case UserRole.coordinator:
        return 'Domain Coordinators';
      case UserRole.volunteer:
        return 'Operations & Crew';
      case UserRole.viewer:
        return 'Society Members';
    }
  }

  String get shortCode {
    switch (this) {
      case UserRole.superAdmin:
        return 'LEAD';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.coordinator:
        return 'COORD';
      case UserRole.volunteer:
        return 'CREW';
      case UserRole.viewer:
        return 'MBR';
    }
  }
}
