import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/features/auth/domain/entities/user_entity.dart';
import 'package:brl_nexus/features/auth/domain/repositories/auth_repository.dart';
import 'package:brl_nexus/features/auth/providers/auth_provider.dart';
import 'package:brl_nexus/features/settings/presentation/screens/profile_screen.dart';

class FakeProfileAuthRepository implements AuthRepository {
  String? updatedName;
  String? updatedYear;
  String? updatedDomain;
  String? updatedPhone;
  String? updatedBio;
  String? updatedGithub;
  String? updatedLinkedin;

  UserEntity currentUser = UserEntity(
    id: 'user_999',
    name: 'Jane Member',
    email: 'jane@akgec.ac.in',
    role: UserRole.coordinator,
    year: '3rd Year',
    domain: 'App Development',
    phone: '9876543210',
    bio: 'Flutter enthusiast',
    github: 'https://github.com/janedoe',
    linkedin: 'https://linkedin.com/in/janedoe',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? avatar,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  }) async {
    updatedName = name;
    updatedYear = year;
    updatedDomain = domain;
    updatedPhone = phone;
    updatedBio = bio;
    updatedGithub = github;
    updatedLinkedin = linkedin;

    currentUser = currentUser.copyWith(
      name: name ?? currentUser.name,
      year: year ?? currentUser.year,
      domain: domain ?? currentUser.domain,
      phone: phone ?? currentUser.phone,
      bio: bio ?? currentUser.bio,
      github: github ?? currentUser.github,
      linkedin: linkedin ?? currentUser.linkedin,
    );

    return Right(currentUser);
  }

  @override
  Future<Either<Failure, UserEntity>> updateAvatar(File imageFile) async =>
      Right(currentUser);

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserEntity?> getCachedUser() async => currentUser;

  @override
  Future<Either<Failure, ({UserEntity user, String accessToken, String refreshToken})>> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, ({UserEntity user, String accessToken, String refreshToken})>> register({
    required String name,
    required String email,
    required String password,
    required String secretKey,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async => Right(currentUser);

  @override
  Future<Either<Failure, String>> refreshToken(String token) async => const Right('dummy');

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async => const Right(null);

  @override
  Future<Either<Failure, void>> resetPassword({required String token, required String newPassword}) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => const Right(null);
}

void main() {
  late FakeProfileAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeProfileAuthRepository();
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
        currentUserProvider.overrideWith((ref) => fakeRepo.currentUser),
      ],
      child: const MaterialApp(
        home: ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Edit Details Tests', () {
    testWidgets('Renders Edit Profile app bar and populated user details', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Jane Member'), findsOneWidget);
      expect(find.text('jane@akgec.ac.in'), findsOneWidget);
      expect(find.text('ACADEMIC & SOCIETY ROLE'), findsOneWidget);
      expect(find.text('CONTACT & SOCIAL PROFILES'), findsOneWidget);
      expect(find.text('ABOUT & BIO'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Updates profile with new year, domain, phone, links and bio', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Edit name
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      await tester.enterText(nameField, 'Jane Updated');

      // Edit phone
      final phoneField = find.widgetWithText(TextFormField, 'Phone Number');
      await tester.enterText(phoneField, '9998887776');

      // Edit bio
      final bioField = find.widgetWithText(TextFormField, 'Short Bio');
      await tester.enterText(bioField, 'Senior Coordinator & Flutter enthusiast');

      // Save changes
      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.updatedName, 'Jane Updated');
      expect(fakeRepo.updatedPhone, '9998887776');
      expect(fakeRepo.updatedBio, 'Senior Coordinator & Flutter enthusiast');
      expect(find.text('Profile updated successfully'), findsOneWidget);
    });
  });
}
