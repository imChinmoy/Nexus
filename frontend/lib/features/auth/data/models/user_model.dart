import '../../domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
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

  const UserModel({
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
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'viewer',
        avatar: json['avatar'] as String?,
        year: json['year'] as String?,
        domain: json['domain'] as String?,
        phone: json['phone'] as String?,
        bio: json['bio'] as String?,
        github: json['github'] as String?,
        linkedin: json['linkedin'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar': avatar,
        'year': year,
        'domain': domain,
        'phone': phone,
        'bio': bio,
        'github': github,
        'linkedin': linkedin,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserEntity toEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
        role: UserRole.fromString(role),
        avatar: avatar,
        year: year,
        domain: domain,
        phone: phone,
        bio: bio,
        github: github,
        linkedin: linkedin,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
