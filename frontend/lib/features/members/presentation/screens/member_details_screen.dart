import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/neon_badge.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/members_provider.dart';
import '../../../../core/network/dio_client.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final UserEntity member;

  const MemberDetailsScreen({super.key, required this.member});

  @override
  ConsumerState<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  late UserEntity _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canEdit = currentUser?.isAdmin == true;

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'MEMBER DETAILS',
          accentColor: AppColors.moduleMembers,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(height: 24),
              Text(
                _member.name,
                style: AppTextStyles.headlineMd.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              NeonBadge(label: _member.role.displayName.toUpperCase(), type: NeonBadgeType.info),
              const SizedBox(height: 32),
              _buildDetailsCard(),
            ],
          ),
        ),
        floatingActionButton: canEdit
            ? Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.accentPink.withOpacity(0.4), blurRadius: 16),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () => _showEditMemberDialog(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.moduleMembers.withOpacity(0.8),
            AppColors.moduleMembers.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.moduleMembers, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.moduleMembers.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: _member.avatar != null && _member.avatar!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.network(_member.avatar!, width: 120, height: 120, fit: BoxFit.cover),
              )
            : Text(
                _member.name.isNotEmpty ? _member.name[0].toUpperCase() : 'M',
                style: AppTextStyles.headlineLg.copyWith(color: Colors.white, fontSize: 48),
              ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return BrlGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email', _member.email),
          if (_member.phone?.isNotEmpty == true) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildInfoRow(Icons.phone_outlined, 'Phone', _member.phone!),
          ],
          if (_member.domain?.isNotEmpty == true) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildInfoRow(Icons.work_outline, 'Domain', _member.domain!),
          ],
          if (_member.year?.isNotEmpty == true) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildInfoRow(Icons.school_outlined, 'Year', _member.year!),
          ],
          if (_member.github?.isNotEmpty == true) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildInfoRow(Icons.code, 'GitHub', _member.github!),
          ],
          if (_member.linkedin?.isNotEmpty == true) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildInfoRow(Icons.link, 'LinkedIn', _member.linkedin!),
          ],
          if (_member.bio?.isNotEmpty == true) ...[
            const Divider(color: Colors.white12, height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline, color: AppColors.moduleMembers, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bio', style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_member.bio!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.moduleMembers, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditMemberDialog(BuildContext context) {
    final nameController = TextEditingController(text: _member.name);
    final emailController = TextEditingController(text: _member.email);
    final phoneController = TextEditingController(text: _member.phone ?? '');
    final domainController = TextEditingController(text: _member.domain ?? '');
    final yearController = TextEditingController(text: _member.year ?? '');
    final bioController = TextEditingController(text: _member.bio ?? '');
    final githubController = TextEditingController(text: _member.github ?? '');
    final linkedinController = TextEditingController(text: _member.linkedin ?? '');
    UserRole selectedRole = _member.role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Member Details', style: AppTextStyles.headlineSm.copyWith(color: AppColors.moduleMembers)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildTextField('Name', nameController),
                    const SizedBox(height: 16),
                    _buildTextField('Email', emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField('Phone', phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField('Domain', domainController),
                    const SizedBox(height: 16),
                    _buildTextField('Year', yearController),
                    const SizedBox(height: 16),
                    _buildTextField('GitHub URL', githubController),
                    const SizedBox(height: 16),
                    _buildTextField('LinkedIn URL', linkedinController),
                    const SizedBox(height: 16),
                    _buildTextField('Bio', bioController, maxLines: 3),
                    const SizedBox(height: 16),
                    if (ref.read(currentUserProvider)?.isSuperAdmin == true)
                      DropdownButtonFormField<UserRole>(
                        value: selectedRole,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Role',
                          labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.moduleMembers), borderRadius: BorderRadius.circular(12)),
                        ),
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.displayName.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedRole = val);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.moduleMembers,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isEmpty || emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and email are required')));
                      return;
                    }
                    try {
                      final dio = ref.read(dioClientProvider);
                      final response = await dio.put('/members/${_member.id}', data: {
                        'name': nameController.text,
                        'email': emailController.text,
                        'phone': phoneController.text,
                        'domain': domainController.text,
                        'year': yearController.text,
                        'github': githubController.text,
                        'linkedin': linkedinController.text,
                        'bio': bioController.text,
                        'role': selectedRole.name,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ref.invalidate(membersProvider);
                        
                        if (response.data != null && response.data['data'] != null) {
                           final updatedModel = UserModel.fromJson(response.data['data']);
                           this.setState(() {
                             _member = updatedModel.toEntity();
                           });
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member updated successfully')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        String errMsg = 'Failed to update member';
                        if (e.toString().contains('403')) {
                          errMsg = 'Access Denied: You do not have permission to edit members';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errMsg)));
                      }
                    }
                  },
                  child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.moduleMembers), borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
