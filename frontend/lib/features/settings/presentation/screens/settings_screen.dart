import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          padding: const EdgeInsets.all(16),
          children: [
            BrlGlassCard(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(user?.name.isNotEmpty == true ? user!.name.substring(0, 2).toUpperCase() : 'U'),
                ),
                title: Text(user?.name ?? 'Unknown User', style: AppTextStyles.bodyLg),
                subtitle: Text(user?.email ?? 'No email provided', style: AppTextStyles.bodySm),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () => context.push(RouteConstants.profile),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Change Password', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () => context.push(RouteConstants.changePassword),
            ),
            ListTile(
              title: const Text('Logout', style: TextStyle(color: AppColors.error)),
              trailing: const Icon(Icons.logout, color: AppColors.error),
              onTap: () {
                ref.read(authNotifierProvider.notifier).logout();
                context.go(RouteConstants.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
