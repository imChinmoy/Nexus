import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'SETTINGS',
          accentColor: AppColors.primary,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // Profile Card
            BrlGlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(user.avatar!)
                        : null,
                    child: (user?.avatar == null || user!.avatar!.isEmpty)
                        ? Text(
                            user?.name.isNotEmpty == true ? user!.name.substring(0, 2).toUpperCase() : 'U',
                            style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Unknown User', style: AppTextStyles.headlineMd),
                        const SizedBox(height: 4),
                        Text(user?.email ?? 'No email provided', style: AppTextStyles.bodySm.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => context.push(RouteConstants.profile),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Account & Security'),
            _buildSettingsTile(
              context,
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => context.push(RouteConstants.changePassword),
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('Preferences'),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_none,
              title: 'Notifications',
              trailing: Switch(
                value: true,
                onChanged: (val) {},
                activeThumbColor: AppColors.primary,
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              trailing: Switch(
                value: true,
                onChanged: (val) {},
                activeThumbColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Support'),
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () async {
                final url = Uri.parse('https://brl.akgec.ac.in/');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Could not launch \$url');
                }
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () async {
                final url = Uri.parse('https://brl.akgec.ac.in/portfolio');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Could not launch \$url');
                }
              },
            ),

            const SizedBox(height: 32),
            BrlGlassCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                onTap: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go(RouteConstants.login);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelLg.copyWith(color: AppColors.primary, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BrlGlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: Colors.white70),
          title: Text(title, style: AppTextStyles.bodyMd),
          trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: onTap,
        ),
      ),
    );
  }
}
