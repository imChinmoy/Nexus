import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/data/models/user_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

final membersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final dio = ref.watch(dioClientProvider);

  try {
    final response = await dio.get(ApiConstants.users, queryParameters: {'limit': 100});
    if (response.statusCode == 200 && response.data != null) {
      final dynamic rawData = response.data['data'];
      if (rawData is List && rawData.isNotEmpty) {
        return rawData.map((json) => UserModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
      }
    }
  } catch (_) {
    // Attempt fallback to /members route
  }

  try {
    final response = await dio.get(ApiConstants.members, queryParameters: {'limit': 100});
    if (response.statusCode == 200 && response.data != null) {
      final dynamic rawData = response.data['data'];
      if (rawData is List && rawData.isNotEmpty) {
        return rawData.map((json) => UserModel.fromJson(json as Map<String, dynamic>).toEntity()).toList();
      }
    }
  } catch (_) {
    // Fall through to seed members
  }

  return defaultSeedMembers;
});

final defaultSeedMembers = [
  UserEntity(
    id: 'mem-super-admin',
    name: 'Chinmoy Senapati',
    email: 'chinmoy@brlnexus.com',
    role: UserRole.superAdmin,
    year: '4th Year',
    domain: 'Technical & Architecture',
    phone: '+91 98765 43210',
    bio: 'President & Chief Architect at BRL Nexus. Leading mobile systems, AI integration, and core devops.',
    github: 'https://github.com/imChinmoy',
    linkedin: 'https://linkedin.com/in/chinmoy-senapati',
    isActive: true,
    createdAt: DateTime(2025, 8, 1),
    updatedAt: DateTime(2026, 1, 15),
  ),
  UserEntity(
    id: 'mem-admin-1',
    name: 'Aarav Sharma',
    email: 'aarav.tech@brlnexus.com',
    role: UserRole.admin,
    year: '3rd Year',
    domain: 'Software Engineering',
    phone: '+91 98765 11223',
    bio: 'Vice Lead & Systems Engineer. Managing backend reliability, database cluster, and cloud operations.',
    github: 'https://github.com/aarav-sharma',
    linkedin: 'https://linkedin.com/in/aarav-sharma',
    isActive: true,
    createdAt: DateTime(2025, 9, 1),
    updatedAt: DateTime(2026, 2, 10),
  ),
  UserEntity(
    id: 'mem-admin-2',
    name: 'Priya Singh',
    email: 'priya.ops@brlnexus.com',
    role: UserRole.admin,
    year: '3rd Year',
    domain: 'Operations & Strategy',
    phone: '+91 98765 44332',
    bio: 'Operations Lead & Event Strategist. Orchestrating annual summits, hackathons, and corporate alliances.',
    linkedin: 'https://linkedin.com/in/priya-singh',
    isActive: true,
    createdAt: DateTime(2025, 9, 10),
    updatedAt: DateTime(2026, 2, 12),
  ),
  UserEntity(
    id: 'mem-coord-1',
    name: 'Rohan Verma',
    email: 'rohan.dev@brlnexus.com',
    role: UserRole.coordinator,
    year: '3rd Year',
    domain: 'Web & Mobile Dev',
    phone: '+91 98111 22334',
    bio: 'Lead Coordinator for Flutter & Fullstack tracks. Mentoring junior developers across society sprints.',
    github: 'https://github.com/rohan-verma',
    isActive: true,
    createdAt: DateTime(2025, 10, 1),
    updatedAt: DateTime(2026, 3, 1),
  ),
  UserEntity(
    id: 'mem-coord-2',
    name: 'Sneha Patel',
    email: 'sneha.design@brlnexus.com',
    role: UserRole.coordinator,
    year: '3rd Year',
    domain: 'UI/UX & Brand Design',
    phone: '+91 98222 33445',
    bio: 'Design Systems Lead. Crafting micro-interactions, motion graphics, and Apple-grade interfaces.',
    linkedin: 'https://linkedin.com/in/sneha-patel-design',
    isActive: true,
    createdAt: DateTime(2025, 10, 5),
    updatedAt: DateTime(2026, 3, 5),
  ),
  UserEntity(
    id: 'mem-coord-3',
    name: 'Aditya Kumar',
    email: 'aditya.events@brlnexus.com',
    role: UserRole.coordinator,
    year: '2nd Year',
    domain: 'Events & Logistics',
    phone: '+91 98333 44556',
    bio: 'Campus Logistics Coordinator. Handling venue operations, gate check-in systems, and schedule flow.',
    isActive: true,
    createdAt: DateTime(2025, 11, 1),
    updatedAt: DateTime(2026, 3, 10),
  ),
  UserEntity(
    id: 'mem-coord-4',
    name: 'Kavya Nair',
    email: 'kavya.pr@brlnexus.com',
    role: UserRole.coordinator,
    year: '2nd Year',
    domain: 'PR & Outreach',
    phone: '+91 98444 55667',
    bio: 'Public Relations & Social Media Coordinator. Driving society awareness, press kits, and sponsor liaison.',
    linkedin: 'https://linkedin.com/in/kavya-nair-pr',
    isActive: true,
    createdAt: DateTime(2025, 11, 15),
    updatedAt: DateTime(2026, 3, 15),
  ),
  UserEntity(
    id: 'mem-vol-1',
    name: 'Vikram Malhotra',
    email: 'vikram.m@brlnexus.com',
    role: UserRole.volunteer,
    year: '2nd Year',
    domain: 'Web & Mobile Dev',
    bio: 'Frontend enthusiast working on Flutter widgets and responsive mobile layouts.',
    github: 'https://github.com/vikram-m',
    isActive: true,
    createdAt: DateTime(2025, 12, 1),
    updatedAt: DateTime(2026, 3, 20),
  ),
  UserEntity(
    id: 'mem-vol-2',
    name: 'Ananya Roy',
    email: 'ananya.r@brlnexus.com',
    role: UserRole.volunteer,
    year: '2nd Year',
    domain: 'Web & Mobile Dev',
    bio: 'Cloud and DevOps associate. Building CI/CD GitHub action pipelines and Docker containers.',
    github: 'https://github.com/ananya-roy',
    isActive: true,
    createdAt: DateTime(2025, 12, 5),
    updatedAt: DateTime(2026, 3, 22),
  ),
  UserEntity(
    id: 'mem-vol-3',
    name: 'Rahul Joshi',
    email: 'rahul.j@brlnexus.com',
    role: UserRole.volunteer,
    year: '2nd Year',
    domain: 'UI/UX & Brand Design',
    bio: 'Illustrator and motion designer preparing banner artwork and stage graphics for events.',
    isActive: true,
    createdAt: DateTime(2025, 12, 10),
    updatedAt: DateTime(2026, 3, 25),
  ),
  UserEntity(
    id: 'mem-vol-4',
    name: 'Ishita Gupta',
    email: 'ishita.g@brlnexus.com',
    role: UserRole.volunteer,
    year: '1st Year',
    domain: 'Events & Logistics',
    bio: 'Event check-in volunteer managing attendee badge printing and entry validation.',
    isActive: true,
    createdAt: DateTime(2026, 1, 10),
    updatedAt: DateTime(2026, 3, 28),
  ),
  UserEntity(
    id: 'mem-vol-5',
    name: 'Tanmay Saxena',
    email: 'tanmay.s@brlnexus.com',
    role: UserRole.volunteer,
    year: '1st Year',
    domain: 'PR & Outreach',
    bio: 'Media and photography crew. Capturing keynotes, workshops, and attendee reels.',
    isActive: true,
    createdAt: DateTime(2026, 1, 15),
    updatedAt: DateTime(2026, 4, 1),
  ),
  UserEntity(
    id: 'mem-view-1',
    name: 'Meera Iyer',
    email: 'meera.i@brlnexus.com',
    role: UserRole.viewer,
    year: '1st Year',
    domain: 'General Member',
    bio: 'Registered society member actively participating in coding sessions and technical seminars.',
    isActive: true,
    createdAt: DateTime(2026, 2, 1),
    updatedAt: DateTime(2026, 4, 5),
  ),
  UserEntity(
    id: 'mem-view-2',
    name: 'Harsh Vardhan',
    email: 'harsh.v@brlnexus.com',
    role: UserRole.viewer,
    year: '1st Year',
    domain: 'General Member',
    bio: 'Fresher and technology explorer interested in robotics and embedded systems.',
    isActive: true,
    createdAt: DateTime(2026, 2, 5),
    updatedAt: DateTime(2026, 4, 10),
  ),
];
