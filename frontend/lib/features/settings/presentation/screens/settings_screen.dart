import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/appearance_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(appearanceProvider);

    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'Settings',
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Profile Card (iOS Apple ID style)
            _buildProfileCard(context, user),
            const SizedBox(height: 24),

            // Appearance Section (Section 7.4 requirement)
            _buildSectionHeader(context, 'APPEARANCE'),
            const SizedBox(height: 8),
            _buildAppearanceSelector(context, ref, themeMode),
            const SizedBox(height: 24),

            // Account & Security Group
            _buildSectionHeader(context, 'ACCOUNT & SECURITY'),
            const SizedBox(height: 8),
            BrlGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsRow(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Name, avatar and contact info',
                    onTap: () => context.push(RouteConstants.profile),
                  ),
                  Divider(color: AppColors.borderOf(context), height: 1),
                  _buildSettingsRow(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your login credentials',
                    onTap: () => context.push(RouteConstants.changePassword),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Society Administration Group
            if (user?.role == UserRole.superAdmin) ...[
              _buildSectionHeader(context, 'ADMINISTRATION'),
              const SizedBox(height: 8),
              BrlGlassCard(
                padding: EdgeInsets.zero,
                child: _buildSettingsRow(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Role Permissions',
                  subtitle: 'Configure volunteer and coordinator access',
                  onTap: () => context.push(RouteConstants.rolePermissions),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Support & About Group
            _buildSectionHeader(context, 'ABOUT & SUPPORT'),
            const SizedBox(height: 8),
            BrlGlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingsRow(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Documentation',
                    subtitle: 'BRL society knowledge base',
                    onTap: () => _openUrl('https://brl.akgec.ac.in/'),
                  ),
                  Divider(color: AppColors.borderOf(context), height: 1),
                  _buildSettingsRow(
                    context,
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy & Terms',
                    subtitle: 'Data protection policies',
                    onTap: () => _openUrl('https://brl.akgec.ac.in/portfolio'),
                  ),
                  Divider(color: AppColors.borderOf(context), height: 1),
                  _buildSettingsRow(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    trailing: Text(
                      '2.0.0 (Kaiser)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondaryOf(context),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            BrlGlassCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(Icons.logout_rounded,
                      color: AppColors.errorOf(context), size: 20),
                  title: Text(
                    'Log Out',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.errorOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiaryOf(context), size: 18),
                  onTap: () => _confirmLogout(context, ref),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiaryOf(context),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserEntity? user) {
    final accent = AppColors.accentOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = user?.name.isNotEmpty == true
        ? user!.name
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () => context.push(RouteConstants.profile),
      child: BrlGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                border:
                    Border.all(color: accent.withValues(alpha: 0.3), width: 1),
              ),
              child: ClipOval(
                child: (user?.avatar != null && user!.avatar!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: user.avatar!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            initials,
                            style: AppTextStyles.headlineSm.copyWith(
                                color: accent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.headlineSm.copyWith(
                              color: accent, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Nexus User',
                    style: AppTextStyles.headlineSm
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'member@society.org',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user?.role.displayName.toUpperCase() ?? 'MEMBER',
                      style: AppTextStyles.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textTertiaryOf(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSelector(
      BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BrlGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined,
                  size: 16, color: AppColors.accentOf(context)),
              const SizedBox(width: 8),
              Text(
                'Interface Theme',
                style:
                    AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161619) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildThemeSegment(
                    context,
                    ref: ref,
                    title: 'System',
                    icon: Icons.brightness_auto_outlined,
                    mode: ThemeMode.system,
                    isSelected: currentMode == ThemeMode.system,
                  ),
                ),
                Expanded(
                  child: _buildThemeSegment(
                    context,
                    ref: ref,
                    title: 'Light',
                    icon: Icons.light_mode_outlined,
                    mode: ThemeMode.light,
                    isSelected: currentMode == ThemeMode.light,
                    badge: 'BETA',
                  ),
                ),
                Expanded(
                  child: _buildThemeSegment(
                    context,
                    ref: ref,
                    title: 'Dark',
                    icon: Icons.dark_mode_outlined,
                    mode: ThemeMode.dark,
                    isSelected: currentMode == ThemeMode.dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSegment(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
    String? badge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppColors.accentOf(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(appearanceProvider.notifier).setThemeMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color:
                      isSelected ? accent : AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.textPrimaryOf(context)
                        : AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color:
                      (isDark ? Colors.amber.shade400 : Colors.amber.shade700)
                          .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        (isDark ? Colors.amber.shade400 : Colors.amber.shade700)
                            .withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color:
                        isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final accent = AppColors.accentOf(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textTertiaryOf(context)),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Log Out of Nexus?',
            style:
                AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'You will need to sign in again with your email and password to access society operations.',
            style: AppTextStyles.bodySm
                .copyWith(color: AppColors.textSecondaryOf(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondaryOf(context)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authNotifierProvider.notifier).logout();
              },
              child: Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.errorOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
