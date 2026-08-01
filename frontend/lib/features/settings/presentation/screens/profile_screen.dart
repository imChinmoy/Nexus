import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_text_field.dart';
import '../../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider);
    final nameChanged = user?.name != _nameController.text.trim();
    
    String? error;

    if (nameChanged) {
      error = await ref.read(authNotifierProvider.notifier).updateProfile(name: _nameController.text.trim());
    }

    if (error == null && _imageFile != null) {
      error = await ref.read(authNotifierProvider.notifier).updateAvatar(_imageFile!);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'EDIT PROFILE',
          showBack: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) as ImageProvider
                          : (user?.avatar != null && user!.avatar!.isNotEmpty)
                              ? CachedNetworkImageProvider(user.avatar!)
                              : null,
                      child: (_imageFile == null && (user?.avatar == null || user!.avatar!.isEmpty))
                          ? Text(
                              user?.name.isNotEmpty == true ? user!.name.substring(0, 2).toUpperCase() : 'U',
                              style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              BrlTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Enter your name',
                prefix: const Icon(Icons.person_outline, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              BrlTextField(
                controller: _emailController,
                label: 'Email (Read Only)',
                hint: 'Your email',
                prefix: const Icon(Icons.email_outlined, color: Colors.white70),
                enabled: false,
              ),
              const SizedBox(height: 40),
              BrlButton(
                onPressed: _updateProfile,
                label: 'Save Changes',
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
