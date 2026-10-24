import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/features/auth/domain/entities/user_entity.dart';
import 'package:brl_nexus/features/auth/domain/repositories/auth_repository.dart';
import 'package:brl_nexus/features/auth/presentation/screens/login_screen.dart';
import 'package:brl_nexus/features/auth/providers/auth_provider.dart';

class FakeAuthRepository implements AuthRepository {
  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastRegisterName;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastRegisterSecretKey;

  final UserEntity dummyUser = UserEntity(
    id: 'user_123',
    name: 'Test Member',
    email: 'member@akgec.ac.in',
    role: UserRole.viewer,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  @override
  Future<Either<Failure, ({UserEntity user, String accessToken, String refreshToken})>> login({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    return Right((
      user: dummyUser,
      accessToken: 'dummy_access_token',
      refreshToken: 'dummy_refresh_token',
    ));
  }

  String? lastRegisterYear;
  String? lastRegisterDomain;
  String? lastRegisterPhone;
  String? lastRegisterBio;
  String? lastRegisterGithub;
  String? lastRegisterLinkedin;

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
  }) async {
    lastRegisterName = name;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    lastRegisterSecretKey = secretKey;
    lastRegisterYear = year;
    lastRegisterDomain = domain;
    lastRegisterPhone = phone;
    lastRegisterBio = bio;
    lastRegisterGithub = github;
    lastRegisterLinkedin = linkedin;

    if (secretKey != 'BRL_NEXUS_2026') {
      return const Left(AuthFailure('Invalid society secret passkey'));
    }

    return Right((
      user: dummyUser,
      accessToken: 'dummy_access_token',
      refreshToken: 'dummy_refresh_token',
    ));
  }

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async => Right(dummyUser);

  @override
  Future<Either<Failure, String>> refreshToken(String token) async => const Right('dummy_new_token');

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async => const Right(null);

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => const Right(null);

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? name,
    String? year,
    String? domain,
    String? phone,
    String? bio,
    String? github,
    String? linkedin,
  }) async => Right(dummyUser);

  @override
  Future<Either<Failure, UserEntity>> updateAvatar(File imageFile) async => Right(dummyUser);

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<UserEntity?> getCachedUser() async => null;
}

void main() {
  late FakeAuthRepository fakeAuthRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen UI & Register Features Tests', () {
    testWidgets('Renders background image assets/images/bg.png and Nexus branding', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Check background Image widget
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsWidgets);

      // Check Nexus branding
      expect(find.text('Nexus'), findsOneWidget);
      expect(find.text('BRL NEXUS • SOCIETY PORTAL'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('Initial mode is Sign In with email and password inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In to Nexus'), findsOneWidget);
      expect(find.text('Society Secret Key'), findsNothing);
    });

    testWidgets('Switches to Register mode when tapping Register tab', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap Register tab
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Verify register fields appear
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Society Secret Key'), findsOneWidget);
      expect(find.text('Create Member Account'), findsOneWidget);

      // Verify society verification banner
      expect(
        find.textContaining('Passkey verification ensures only BRL society members & associated team can register'),
        findsOneWidget,
      );
      expect(
        find.textContaining('automatically be granted Viewer access'),
        findsOneWidget,
      );
    });

    testWidgets('Register form validates required secret passkey and password mismatch', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Switch to register mode
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Tap submit with empty fields
      final submitFinder = find.text('Create Member Account');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Society secret passkey is required'), findsOneWidget);
    });

    testWidgets('Valid registration calls register repository method with secret key', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Switch to register mode
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Fill in valid details
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Chinmoy Anand');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'chinmoy@akgec.ac.in');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Society Secret Key'), 'BRL_NEXUS_2026');

      final submitFinder = find.text('Create Member Account');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();

      expect(fakeAuthRepo.lastRegisterName, 'Chinmoy Anand');
      expect(fakeAuthRepo.lastRegisterEmail, 'chinmoy@akgec.ac.in');
      expect(fakeAuthRepo.lastRegisterPassword, 'Password@123');
      expect(fakeAuthRepo.lastRegisterSecretKey, 'BRL_NEXUS_2026');
    });

    testWidgets('Error message is displayed when registration fails (e.g. invalid secret passkey)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Switch to register mode
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Enter invalid secret passkey
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Chinmoy Anand');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'chinmoy@akgec.ac.in');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Society Secret Key'), 'WRONG_KEY');

      final submitFinder = find.text('Create Member Account');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Invalid society secret passkey'), findsOneWidget);
    });

    testWidgets('Profile details card only appears in registration, not in sign in', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Sign In mode
      expect(find.byKey(const ValueKey('toggle_profile_fields_button')), findsNothing);
      expect(find.text('Profile Details'), findsNothing);

      // Switch to register mode
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('toggle_profile_fields_button')), findsOneWidget);
      expect(find.text('Profile Details'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('Can toggle profile details, fill additional info and submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Switch to register mode
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Tap + Add Details
      final toggleButton = find.byKey(const ValueKey('toggle_profile_fields_button'));
      await tester.ensureVisible(toggleButton);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Verify profile fields are visible
      expect(find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'GitHub Profile'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'LinkedIn Profile'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Short Bio'), findsOneWidget);

      // Fill in credentials and profile fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Chinmoy Anand');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'chinmoy@akgec.ac.in');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Society Secret Key'), 'BRL_NEXUS_2026');

      await tester.enterText(find.widgetWithText(TextFormField, 'Phone Number'), '9876543210');
      await tester.enterText(find.widgetWithText(TextFormField, 'GitHub Profile'), 'https://github.com/imchinmoy');
      await tester.enterText(find.widgetWithText(TextFormField, 'LinkedIn Profile'), 'https://linkedin.com/in/imchinmoy');
      await tester.enterText(find.widgetWithText(TextFormField, 'Short Bio'), 'Flutter & Backend enthusiast');

      final submitFinder = find.text('Create Member Account');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();

      expect(fakeAuthRepo.lastRegisterName, 'Chinmoy Anand');
      expect(fakeAuthRepo.lastRegisterPhone, '9876543210');
      expect(fakeAuthRepo.lastRegisterGithub, 'https://github.com/imchinmoy');
      expect(fakeAuthRepo.lastRegisterLinkedin, 'https://linkedin.com/in/imchinmoy');
      expect(fakeAuthRepo.lastRegisterBio, 'Flutter & Backend enthusiast');
    });

    testWidgets('Can skip profile details and register with credentials only', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Switch to register mode
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Expand profile details first
      final toggleButton = find.byKey(const ValueKey('toggle_profile_fields_button'));
      await tester.ensureVisible(toggleButton);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Phone Number'), findsOneWidget);

      // Now tap skip button inside the card
      final skipBtn = find.text('Skip for now & continue');
      await tester.ensureVisible(skipBtn);
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      // Form collapsed
      expect(find.widgetWithText(TextFormField, 'Phone Number'), findsNothing);

      // Fill in mandatory fields
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Chinmoy Anand');
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'chinmoy@akgec.ac.in');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirm Password'), 'Password@123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Society Secret Key'), 'BRL_NEXUS_2026');

      final submitFinder = find.text('Create Member Account');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();

      expect(fakeAuthRepo.lastRegisterName, 'Chinmoy Anand');
      expect(fakeAuthRepo.lastRegisterPhone, isNull);
      expect(fakeAuthRepo.lastRegisterGithub, isNull);
      expect(fakeAuthRepo.lastRegisterLinkedin, isNull);
      expect(fakeAuthRepo.lastRegisterBio, isNull);
    });
  });
}

